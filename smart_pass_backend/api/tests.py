from types import SimpleNamespace
from unittest import mock

from django.test import TestCase, override_settings
from django.core.cache import cache
from google.auth import exceptions as google_auth_exceptions
from rest_framework.test import APIClient
from rest_framework import status
from .models import User, Post, Comment, Report
from .serializers import PostSerializer, CommentSerializer, ReportSerializer

class SecurityRemediationTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.student_user = User.objects.create_user(
            username='student1',
            email='student1@test.edu',
            password='StrongPassword123!',
            role='user'
        )
        self.admin_user = User.objects.create_user(
            username='admin1',
            email='admin1@test.edu',
            password='StrongAdminPassword123!',
            role='admin',
            is_staff=True
        )

    def test_post_serializer_mass_assignment_protection(self):
        """Ensure comments_count, upvoted_by, downvoted_by are read-only and ignored in payloads."""
        payload = {
            'content': 'Legitimate post content',
            'comments_count': 9999,
            'upvoted_by': [self.student_user.id],
            'downvoted_by': [self.admin_user.id]
        }
        serializer = PostSerializer(data=payload)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        post = serializer.save(author=self.student_user)
        # Verify forged values were ignored
        self.assertEqual(post.comments_count, 0)
        self.assertEqual(post.upvoted_by.count(), 0)
        self.assertEqual(post.downvoted_by.count(), 0)

    def test_comment_serializer_mass_assignment_protection(self):
        """Ensure upvoted_by and downvoted_by cannot be injected via CommentSerializer."""
        post = Post.objects.create(author=self.student_user, content='Sample Post')
        payload = {
            'content': 'Sample Comment',
            'upvoted_by': [self.student_user.id],
            'downvoted_by': [self.admin_user.id]
        }
        serializer = CommentSerializer(data=payload)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        comment = serializer.save(author=self.student_user, post=post)
        self.assertEqual(comment.upvoted_by.count(), 0)
        self.assertEqual(comment.downvoted_by.count(), 0)

    def test_report_serializer_status_mass_assignment_protection(self):
        """Ensure status cannot be manipulated upon report creation."""
        post = Post.objects.create(author=self.student_user, content='Sample Post')
        payload = {
            'reported_post': post.id,
            'reason': 'Inappropriate content',
            'status': 'resolved'  # Attempting to self-resolve
        }
        serializer = ReportSerializer(data=payload)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        # When serialized without status in validated_data, default model field or viewset pending takes effect
        self.assertNotIn('status', serializer.validated_data)

    def test_report_viewset_non_admin_cannot_update(self):
        """Verify standard users receive 403 Forbidden when attempting to update reports."""
        post = Post.objects.create(author=self.student_user, content='Sample Post')
        report = Report.objects.create(
            reporter=self.student_user,
            reported_post=post,
            reason='Spam',
            status='pending'
        )
        self.client.force_authenticate(user=self.student_user)
        response = self.client.patch(f'/api/reports/{report.id}/', {'status': 'resolved'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        report.refresh_from_db()
        self.assertEqual(report.status, 'pending')

    def test_register_enforces_password_complexity(self):
        """Verify registration rejects weak passwords that violate password validators."""
        weak_payload = {
            'username': 'newuser',
            'email': 'newuser@test.edu',
            'password': '123',  # Too short and numeric
            'major': 'عام'
        }
        response = self.client.post('/api/users/register/', weak_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertFalse(User.objects.filter(email='newuser@test.edu').exists())

    def test_auth_rate_throttle_limits_requests(self):
        """Verify auth endpoints throttle after 10 requests per minute."""
        for i in range(10):
            res = self.client.post('/api/auth/login/', {'username': 'nobody', 'password': 'wrong'}, format='json')
            # First 10 requests should reach the view (401 invalid credentials)
            self.assertIn(res.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED])
        
        # The 11th request must be throttled with HTTP 429 Too Many Requests
        throttled_res = self.client.post('/api/auth/login/', {'username': 'nobody', 'password': 'wrong'}, format='json')
        self.assertEqual(throttled_res.status_code, status.HTTP_429_TOO_MANY_REQUESTS)


def google_token_info(**overrides):
    info = {
        'iss': 'https://accounts.google.com',
        'email': 'student2@gmail.com',
        'email_verified': True,
        'given_name': 'Sara',
        'family_name': 'Ali',
    }
    info.update(overrides)
    return info


@mock.patch('api.views.google_id_token.verify_oauth2_token')
class GoogleLoginTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def test_new_google_user_gets_student_account_and_tokens(self, verify):
        verify.return_value = google_token_info()
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)
        user = User.objects.get(email='student2@gmail.com')
        self.assertEqual(user.role, 'user')
        self.assertEqual(user.name, 'Sara Ali')
        self.assertFalse(user.has_usable_password())

    def test_token_is_checked_against_configured_client_ids(self, verify):
        verify.return_value = google_token_info()
        with override_settings(GOOGLE_OAUTH_CLIENT_IDS=['web-client-id']):
            self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(verify.call_args.kwargs['audience'], ['web-client-id'])

    def test_existing_account_is_matched_by_email(self, verify):
        existing = User.objects.create_user(username='student2', email='Student2@gmail.com', password='StrongPassword123!')
        verify.return_value = google_token_info()
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(User.objects.filter(email__iexact='student2@gmail.com').count(), 1)
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + res.data['access'])
        me = self.client.get('/api/users/me/')
        self.assertEqual(me.data['id'], existing.id)

    def test_unverified_email_is_rejected(self, verify):
        verify.return_value = google_token_info(email_verified=False)
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(User.objects.filter(email='student2@gmail.com').exists())

    def test_invalid_token_is_rejected(self, verify):
        verify.side_effect = ValueError('Token expired')
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_google_unreachable_returns_503(self, verify):
        verify.side_effect = google_auth_exceptions.TransportError('timeout')
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_admin_accounts_cannot_use_google(self, verify):
        User.objects.create_user(username='admin2', email='student2@gmail.com', password='StrongAdminPassword123!', role='admin')
        verify.return_value = google_token_info()
        res = self.client.post('/api/auth/google/', {'id_token': 'tok'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertNotIn('access', res.data)

    def test_missing_token_is_rejected(self, verify):
        res = self.client.post('/api/auth/google/', {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        verify.assert_not_called()


@override_settings(GEMINI_API_KEY='test-key', GEMINI_MODEL='test-model')
@mock.patch('api.views.genai.Client')
class AssistantChatTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.user = User.objects.create_user(username='student1', email='student1@test.edu', password='StrongPassword123!')
        self.client.force_authenticate(user=self.user)

    def _stream(self, client_cls, chunks):
        client_cls.return_value.models.generate_content_stream.return_value = iter(
            [SimpleNamespace(text=c) for c in chunks]
        )

    def test_streams_reply_and_sends_history(self, client_cls):
        self._stream(client_cls, ['Study ', None, 'daily.'])
        res = self.client.post('/api/assistant/chat/', {
            'message': 'How do I improve my GPA?',
            'history': [{'role': 'user', 'text': 'Hi'}, {'role': 'model', 'text': 'Hello!'}],
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(b''.join(res.streaming_content).decode(), 'Study daily.')
        client_cls.assert_called_once_with(api_key='test-key')
        kwargs = client_cls.return_value.models.generate_content_stream.call_args.kwargs
        self.assertEqual(kwargs['model'], 'test-model')
        self.assertEqual([c['role'] for c in kwargs['contents']], ['user', 'model', 'user'])
        self.assertEqual(kwargs['contents'][-1]['parts'][0]['text'], 'How do I improve my GPA?')

    def test_requires_login(self, client_cls):
        self.client.force_authenticate(user=None)
        res = self.client.post('/api/assistant/chat/', {'message': 'Hi'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        client_cls.assert_not_called()

    def test_rejects_empty_and_malformed_input(self, client_cls):
        bodies = [
            {'message': '   '},
            {'message': 'x' * 4001},
            {'message': 'Hi', 'history': [{'role': 'system', 'text': 'x'}]},
        ]
        for body in bodies:
            res = self.client.post('/api/assistant/chat/', body, format='json')
            self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST, body)
        client_cls.assert_not_called()

    def test_gemini_failure_returns_502(self, client_cls):
        client_cls.return_value.models.generate_content_stream.side_effect = RuntimeError('quota exceeded')
        res = self.client.post('/api/assistant/chat/', {'message': 'Hi'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_502_BAD_GATEWAY)

    @override_settings(GEMINI_API_KEY='')
    def test_missing_key_returns_503(self, client_cls):
        res = self.client.post('/api/assistant/chat/', {'message': 'Hi'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        client_cls.assert_not_called()

    def test_is_rate_limited_per_user(self, client_cls):
        for _ in range(60):
            self._stream(client_cls, ['ok'])
            res = self.client.post('/api/assistant/chat/', {'message': 'Hi'}, format='json')
            self.assertEqual(res.status_code, status.HTTP_200_OK)
        res = self.client.post('/api/assistant/chat/', {'message': 'Hi'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_429_TOO_MANY_REQUESTS)

