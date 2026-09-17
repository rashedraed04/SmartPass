# Smart Pass Backend

This is the robust backend API for the Smart Pass platform, built to handle student authentication, data management, and secure communications.

## Tech Stack Overview
- **Django**: High-level Python web framework.
- **Django REST Framework (DRF)**: Powerful and flexible toolkit for building Web APIs.
- **PostgreSQL**: Advanced open-source relational database system.

## Setup Instructions

Follow these steps to configure and run the project locally.

### 1. Prerequisites
Ensure you have Python and PostgreSQL installed on your system.

### 2. Virtual Environment Setup
It is highly recommended to use a virtual environment to manage dependencies.
Create a virtual environment:
```bash
python -m venv venv
```
Activate the virtual environment (Windows):
```bash
venv\Scripts\activate
```
*(On macOS/Linux, use `source venv/bin/activate`)*

### 3. Install Dependencies
Install all required Python packages from the requirements file:
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Create a `.env` file in the root directory (where `manage.py` is located) and configure the necessary variables based on your setup:
```env
DJANGO_SECRET_KEY=your_secret_key_here
# Add your database configuration if required
# DB_NAME=your_db_name
# DB_USER=your_db_user
# DB_PASSWORD=your_db_password
```

### 5. Apply Database Migrations
Set up your database schema by running:
```bash
python manage.py migrate
```

### 6. Start the Development Server
Run the local development server:
```bash
python manage.py runserver
```

The server should now be running at `http://127.0.0.1:8000/`.
