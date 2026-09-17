from rest_framework import serializers
from .models import User, Post, Comment, Notification, Report, Exam

class UserSerializer(serializers.ModelSerializer):
    """
    Standard User Serializer:
    'role' is strictly read-only to prevent mass-assignment privilege escalation.
    """
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'role', 'major')
        read_only_fields = ('id', 'role')

class AdminUserSerializer(serializers.ModelSerializer):
    """
    Admin-only User Serializer:
    Allows administrators to view and update user roles.
    """
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'role', 'major')
        read_only_fields = ('id',)

class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField()
    author_major = serializers.ReadOnlyField()
    upvotes = serializers.ReadOnlyField()
    
    class Meta:
        model = Post
        fields = ('id', 'author', 'author_name', 'author_major', 'content', 'image_url', 'timestamp', 'upvotes', 'comments_count', 'upvoted_by', 'downvoted_by')
        read_only_fields = ('id', 'author', 'timestamp', 'upvotes', 'comments_count', 'upvoted_by', 'downvoted_by')

class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField()
    upvotes = serializers.ReadOnlyField()
    
    class Meta:
        model = Comment
        fields = ('id', 'post', 'author', 'author_name', 'content', 'timestamp', 'upvotes', 'upvoted_by', 'downvoted_by')
        read_only_fields = ('id', 'author', 'post', 'timestamp', 'upvotes', 'upvoted_by', 'downvoted_by')

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'
        read_only_fields = ('id', 'recipient', 'timestamp')

class ReportSerializer(serializers.ModelSerializer):
    reporter_name = serializers.CharField(source='reporter.name', read_only=True)
    reporter_email = serializers.CharField(source='reporter.email', read_only=True)
    post_content = serializers.CharField(source='reported_post.content', read_only=True)
    comment_content = serializers.CharField(source='reported_comment.content', read_only=True)
    
    class Meta:
        model = Report
        fields = ['id', 'reporter', 'reporter_name', 'reporter_email', 'reported_post', 'reported_comment', 'post_content', 'comment_content', 'reason', 'timestamp', 'status']
        read_only_fields = ['id', 'reporter', 'timestamp', 'status']

class ExamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exam
        fields = ['id', 'user', 'course_name', 'date', 'timestamp']
        read_only_fields = ['id', 'user', 'timestamp']
