from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, PostViewSet, CommentViewSet, NotificationViewSet, ReportViewSet, ExamViewSet
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .throttles import AuthRateThrottle

class ThrottledTokenObtainPairView(TokenObtainPairView):
    throttle_classes = [AuthRateThrottle]

class ThrottledTokenRefreshView(TokenRefreshView):
    throttle_classes = [AuthRateThrottle]

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'posts', PostViewSet)
router.register(r'comments', CommentViewSet)
router.register(r'notifications', NotificationViewSet)
router.register(r'reports', ReportViewSet)
router.register(r'exams', ExamViewSet, basename='exam')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', ThrottledTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', ThrottledTokenRefreshView.as_view(), name='token_refresh'),
]
