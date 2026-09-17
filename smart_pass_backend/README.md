# Smart Pass Backend

This is the Django backend for the Smart Student platform.

## Setup Instructions

1. Ensure you have Python installed.
2. Create and activate a virtual environment (e.g., `python -m venv venv`, then `venv\Scripts\activate` on Windows).
3. Install dependencies: `pip install -r requirements.txt`.
4. Create a `.env` file in the root directory (where `manage.py` is located) with the required environment variables (e.g., `DJANGO_SECRET_KEY`).
5. Run migrations: `python manage.py migrate`.
6. Start the server: `python manage.py runserver`.

## Environment Variables
- `DJANGO_SECRET_KEY`: Secret key for Django security.
