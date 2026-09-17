from rest_framework.throttling import AnonRateThrottle

class AuthRateThrottle(AnonRateThrottle):
    """
    Dedicated throttle for authentication endpoints (/auth/login/, /auth/refresh/, /users/register/)
    to mitigate credential stuffing, brute-force, and registration flood attacks.
    """
    scope = 'auth'
