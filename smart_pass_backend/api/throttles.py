from rest_framework.throttling import AnonRateThrottle, UserRateThrottle

class AuthRateThrottle(AnonRateThrottle):
    """
    Dedicated throttle for authentication endpoints (/auth/login/, /auth/refresh/, /users/register/)
    to mitigate credential stuffing, brute-force, and registration flood attacks.
    """
    scope = 'auth'


class AssistantRateThrottle(UserRateThrottle):
    """
    Per-user limit on the Academic Assistant so one account cannot run up the Gemini bill.
    """
    scope = 'assistant'
