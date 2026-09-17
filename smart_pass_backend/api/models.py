from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    # AbstractUser provides username, email, password, etc.
    # We add fields needed by the Flutter app.
    role = models.CharField(max_length=50, default='user')
    major = models.CharField(max_length=100, default='عام')
    
    @property
    def name(self):
        full = f"{self.first_name} {self.last_name}".strip()
        return full if full else self.username

    def __str__(self):
        return self.username

class Post(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    content = models.TextField()
    image_url = models.URLField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    upvoted_by = models.ManyToManyField(User, related_name='upvoted_posts', blank=True)
    downvoted_by = models.ManyToManyField(User, related_name='downvoted_posts', blank=True)
    
    # Optional comments count (can also be derived from a Comment model later)
    comments_count = models.IntegerField(default=0)

    @property
    def upvotes(self):
        return self.upvoted_by.count()
        
    @property
    def author_name(self):
        # Fallback to username if first_name/last_name not set
        name = f"{self.author.first_name} {self.author.last_name}".strip()
        return name if name else self.author.username
        
    @property
    def author_major(self):
        return self.author.major

    def __str__(self):
        return f"Post by {self.author.username} at {self.timestamp}"


class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    upvoted_by = models.ManyToManyField(User, related_name='upvoted_comments', blank=True)
    downvoted_by = models.ManyToManyField(User, related_name='downvoted_comments', blank=True)

    @property
    def upvotes(self):
        return self.upvoted_by.count()
        
    @property
    def author_name(self):
        name = f"{self.author.first_name} {self.author.last_name}".strip()
        return name if name else self.author.username

    def __str__(self):
        return f"Comment by {self.author.username} on {self.post.id}"

class Notification(models.Model):
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    message = models.CharField(max_length=255)
    post_content = models.CharField(max_length=255, blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"To {self.recipient.username}: {self.message}"


class Report(models.Model):
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_submitted')
    reported_post = models.ForeignKey(Post, on_delete=models.CASCADE, null=True, blank=True, related_name='reports')
    reported_comment = models.ForeignKey(Comment, on_delete=models.CASCADE, null=True, blank=True, related_name='reports')
    reason = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='pending') # pending, resolved, dismissed

    def __str__(self):
        return f"Report by {self.reporter.name} - Status: {self.status}"


class Exam(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='exams')
    course_name = models.CharField(max_length=100)
    date = models.DateTimeField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.course_name} for {self.user.username}"
