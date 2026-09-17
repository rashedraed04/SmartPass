from rest_framework import permissions

class IsOwnerOrAdminOrReadOnly(permissions.BasePermission):
    """
    Custom permission:
    - Safe methods (GET, HEAD, OPTIONS) are allowed for authenticated requests.
    - Write/Delete methods are only allowed for the object owner or staff/admin.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
            
        user = request.user
        if not user or not user.is_authenticated:
            return False
            
        if getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin':
            return True
            
        # Check author (Post, Comment)
        if hasattr(obj, 'author'):
            return obj.author == user
            
        # Check user (Exam)
        if hasattr(obj, 'user'):
            return obj.user == user
            
        # Check reporter (Report)
        if hasattr(obj, 'reporter'):
            return obj.reporter == user
            
        # Direct User model comparison
        if obj == user:
            return True
            
        return False


class IsAdminRole(permissions.BasePermission):
    """
    Allows access only to users with role == 'admin' or is_staff == True.
    """
    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and 
            user.is_authenticated and 
            (getattr(user, 'is_staff', False) or getattr(user, 'role', '') == 'admin')
        )
