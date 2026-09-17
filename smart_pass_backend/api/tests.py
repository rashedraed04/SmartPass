from django.test import TestCase
from django.core.cache import cache
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

