import logging

from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.http import StreamingHttpResponse
from google import genai
from google.auth import exceptions as google_auth_exceptions
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from .models import User, Post, Comment, Notification, Report, Exam
from .serializers import (
    UserSerializer, AdminUserSerializer, PostSerializer, 
    CommentSerializer, NotificationSerializer, ReportSerializer, ExamSerializer
)
from .permissions import IsOwnerOrAdminOrReadOnly, IsAdminRole
from .throttles import AuthRateThrottle, AssistantRateThrottle

logger = logging.getLogger(__name__)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        user = self.request.user
        if user.is_authenticated and (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return AdminUserSerializer
        return UserSerializer

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return User.objects.none()
            
        # On list routes, only admins see all users. Non-admins only receive themselves.
        if self.action == 'list':
            if getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin':
                return User.objects.all().order_by('id')
            return User.objects.filter(id=user.id)
            
        # On detail routes, allow fetching user profiles (for public profile display)
        return User.objects.all()

    def update(self, request, *args, **kwargs):
        # Only admins or staff can modify arbitrary user records via /api/users/<id>/
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to update user records."}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to update user records."}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        # Only admins or staff can delete users
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to delete users."}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny], throttle_classes=[AuthRateThrottle])
    def register(self, request):
        data = request.data
        username = data.get('username') or data.get('email')
        email = data.get('email')
        password = data.get('password')
        major = data.get('major', 'عام')
        
        # Security: Force role to 'user' for public registration to prevent privilege escalation
        role = 'user'
        
        if not email or not password:
            return Response({"error": "Email and password are required"}, status=status.HTTP_400_BAD_REQUEST)

        # Enforce password validation policy
        try:
            validate_password(password)
        except ValidationError as e:
            return Response({"error": e.messages}, status=status.HTTP_400_BAD_REQUEST)
            
        if User.objects.filter(email=email).exists():
            return Response({"error": "Email already registered"}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            return Response({"error": "Username already taken"}, status=status.HTTP_400_BAD_REQUEST)
            
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role=role,
            major=major
        )
        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        if request.method == 'GET':
            serializer = self.get_serializer(request.user)
            return Response(serializer.data)
        else:
            # Always use standard UserSerializer for /api/users/me/ so role cannot be changed via me
            serializer = UserSerializer(request.user, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], permission_classes=[IsAdminRole])
    def stats(self, request):
        return Response({
            'users': User.objects.count(),
            'posts': Post.objects.count(),
            'reports': Report.objects.count(),
        })

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all().order_by('-timestamp')
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrAdminOrReadOnly]
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
        
    @action(detail=True, methods=['post'])
    def upvote(self, request, pk=None):
        post = self.get_object()
        user = request.user
        if user in post.downvoted_by.all():
            post.downvoted_by.remove(user)
        if user in post.upvoted_by.all():
            post.upvoted_by.remove(user)
            return Response({'status': 'upvote removed'})
        else:
            post.upvoted_by.add(user)
            return Response({'status': 'upvoted'})
            
    @action(detail=True, methods=['post'])
    def downvote(self, request, pk=None):
        post = self.get_object()
        user = request.user
        if user in post.upvoted_by.all():
            post.upvoted_by.remove(user)
        if user in post.downvoted_by.all():
            post.downvoted_by.remove(user)
            return Response({'status': 'downvote removed'})
        else:
            post.downvoted_by.add(user)
            return Response({'status': 'downvoted'})

    @action(detail=False, methods=['get'])
    def me(self, request):
        posts = Post.objects.filter(author=request.user).order_by('-timestamp')
        serializer = self.get_serializer(posts, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get', 'post'])
    def comments(self, request, pk=None):
        post = self.get_object()
        if request.method == 'GET':
            comments = post.comments.all().order_by('timestamp')
            serializer = CommentSerializer(comments, many=True)
            return Response(serializer.data)
        elif request.method == 'POST':
            serializer = CommentSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save(author=request.user, post=post)
                if request.user != post.author:
                    Notification.objects.create(
                        recipient=post.author,
                        message=f"{request.user.name} قام بالتعليق على منشورك",
                        post_content=post.content[:50]
                    )
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrAdminOrReadOnly]

    @action(detail=True, methods=['post'])
    def upvote(self, request, pk=None):
        comment = self.get_object()
        user = request.user
        if user in comment.downvoted_by.all():
            comment.downvoted_by.remove(user)
        if user in comment.upvoted_by.all():
            comment.upvoted_by.remove(user)
            return Response({'status': 'upvote removed'})
        else:
            comment.upvoted_by.add(user)
            return Response({'status': 'upvoted'})
            
    @action(detail=True, methods=['post'])
    def downvote(self, request, pk=None):
        comment = self.get_object()
        user = request.user
        if user in comment.upvoted_by.all():
            comment.upvoted_by.remove(user)
        if user in comment.downvoted_by.all():
            comment.downvoted_by.remove(user)
            return Response({'status': 'downvote removed'})
        else:
            comment.downvoted_by.add(user)
            return Response({'status': 'downvoted'})

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(recipient=self.request.user).order_by('-timestamp')

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        self.get_queryset().update(is_read=True)
        return Response({'status': 'marked as read'})

class ReportViewSet(viewsets.ModelViewSet):
    queryset = Report.objects.all().order_by('-timestamp')
    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin':
            return Report.objects.all().order_by('-timestamp')
        return Report.objects.filter(reporter=user).order_by('-timestamp')

    def perform_create(self, serializer):
        # Force default status to 'pending' to prevent callers from self-resolving reports
        serializer.save(reporter=self.request.user, status='pending')

    def update(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to update reports."}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to update reports."}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin'):
            return Response({"error": "Admin privilege required to delete reports."}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def resolve(self, request, pk=None):
        report = self.get_object()
        report.status = 'resolved'
        report.save()
        return Response({'status': 'Report resolved'})
        
    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def dismiss(self, request, pk=None):
        report = self.get_object()
        report.status = 'dismissed'
        report.save()
        return Response({'status': 'Report dismissed'})

class ExamViewSet(viewsets.ModelViewSet):
    serializer_class = ExamSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrAdminOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin':
            return Exam.objects.all().order_by('date')
        return Exam.objects.filter(user=user).order_by('date')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class GoogleLoginView(APIView):
    """
    Exchanges a Google ID token from the app for this API's JWT pair.
    Matches an existing account by verified email, or creates a student account.
    """
    permission_classes = [permissions.AllowAny]
    throttle_classes = [AuthRateThrottle]

    def post(self, request):
        token = request.data.get('id_token')
        if not token:
            return Response({"error": "id_token is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            info = google_id_token.verify_oauth2_token(
                token, google_requests.Request(), audience=settings.GOOGLE_OAUTH_CLIENT_IDS
            )
        except google_auth_exceptions.TransportError:
            logger.exception("Could not reach Google to verify an ID token")
            return Response({"error": "Google sign-in is unavailable, try again later"}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except (ValueError, google_auth_exceptions.GoogleAuthError):
            return Response({"error": "Invalid Google token"}, status=status.HTTP_401_UNAUTHORIZED)

        email = info.get('email')
        if not email or not info.get('email_verified'):
            return Response({"error": "Google account email is not verified"}, status=status.HTTP_401_UNAUTHORIZED)

        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            if User.objects.filter(username=email).exists():
                return Response({"error": "Username already taken"}, status=status.HTTP_400_BAD_REQUEST)
            # Same shape as /users/register/: username is the email, role is always 'user'.
            # No password is set, so this account can only sign in with Google.
            user = User.objects.create_user(
                username=email,
                email=email,
                first_name=info.get('given_name', ''),
                last_name=info.get('family_name', ''),
                role='user',
            )

        if not user.is_active:
            return Response({"error": "This account is disabled"}, status=status.HTTP_403_FORBIDDEN)
        # Admin accounts must use their password, so access to a Google account alone can't open the dashboard.
        if user.is_staff or user.role == 'admin':
            return Response({"error": "Admin accounts must sign in with a password"}, status=status.HTTP_403_FORBIDDEN)

        refresh = RefreshToken.for_user(user)
        return Response({'refresh': str(refresh), 'access': str(refresh.access_token)})


class AssistantChatView(APIView):
    """
    Streams a Gemini reply for the Academic Assistant as plain text chunks.
    The app sends the new message plus the earlier turns of the conversation.
    """
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [AssistantRateThrottle]

    MAX_MESSAGE_CHARS = 4000
    MAX_HISTORY_TURNS = 20

    def post(self, request):
        message = request.data.get('message')
        history = request.data.get('history') or []
        if not isinstance(message, str) or not message.strip():
            return Response({"error": "message is required"}, status=status.HTTP_400_BAD_REQUEST)
        if len(message) > self.MAX_MESSAGE_CHARS:
            return Response({"error": f"message must be at most {self.MAX_MESSAGE_CHARS} characters"}, status=status.HTTP_400_BAD_REQUEST)
        if not isinstance(history, list):
            return Response({"error": "history must be a list"}, status=status.HTTP_400_BAD_REQUEST)

        contents = []
        for turn in history[-self.MAX_HISTORY_TURNS:]:
            if not isinstance(turn, dict) or turn.get('role') not in ('user', 'model') or not isinstance(turn.get('text'), str):
                return Response({"error": "each history item needs a role of 'user' or 'model' and a text"}, status=status.HTTP_400_BAD_REQUEST)
            if turn['text'].strip():
                contents.append({'role': turn['role'], 'parts': [{'text': turn['text'][:self.MAX_MESSAGE_CHARS]}]})
        contents.append({'role': 'user', 'parts': [{'text': message.strip()}]})

        if not settings.GEMINI_API_KEY:
            return Response({"error": "The assistant is not configured on the server"}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            client = genai.Client(api_key=settings.GEMINI_API_KEY)
            stream = client.models.generate_content_stream(model=settings.GEMINI_MODEL, contents=contents)
            # Pull the first chunk here so a bad key or quota error becomes a proper error response
            # instead of an empty 200.
            first = next(stream, None)
        except Exception:
            logger.exception("Gemini request failed")
            return Response({"error": "The assistant could not reply, try again later"}, status=status.HTTP_502_BAD_GATEWAY)

        def chunks():
            # The generator holds the client: if it were garbage collected after post() returns,
            # it would close the connection the stream is still reading from.
            try:
                if first is not None and first.text:
                    yield first.text
                for chunk in stream:
                    if chunk.text:
                        yield chunk.text
            except Exception:
                logger.exception("Gemini stream broke off")
            finally:
                client.close()

        return StreamingHttpResponse(chunks(), content_type='text/plain; charset=utf-8')
