# Smart Pass

A student helper platform for IT students (CS, CIS and BIT) at the University of
Jordan, built as a graduation project. Students get an AI academic assistant, a GPA
planner, an exam tracker, a faculty directory and a community board; admins get a
dashboard to moderate the community and see platform stats. Arabic (RTL, default) and
English, light and dark themes.

Made by Rashed Al-Awamleh.

## Architecture

```
Flutter app (smart_student_frontend)
   │                         │
   │ REST + JWT              │ chat, streamed
   ▼                         ▼
Django REST API          Google Gemini
(smart_pass_backend)
   │
   ▼
PostgreSQL
```

- **Backend:** Django + Django REST Framework, JWT auth (SimpleJWT, 2-hour access
  tokens, rotating 7-day refresh tokens), PostgreSQL. Every endpoint needs a login
  except sign-up and getting tokens. Login, refresh and sign-up are throttled to 10
  requests per minute.
- **Permissions:** users can only edit or delete their own posts, comments and exams,
  and only see their own exams, notifications and reports. Admins (`role = "admin"` or
  Django staff) can moderate everything and resolve or dismiss reports.
- **AI assistant:** the app talks to Gemini directly through `google_generative_ai`,
  using the key from the app's `.env`. The backend is not involved.

## Features

| Feature | What it does |
| --- | --- |
| Academic Assistant | Gemini chat with streamed replies and quick prompts (improve my GPA, estimate my GPA, study tips) |
| GPA Calculator | Enter current GPA, completed hours, a target GPA and this semester's courses; it works out the semester average needed to reach the target |
| Exam Tracker | Personal list of upcoming exams, stored per user on the backend |
| College Guide | Searchable directory of CS, CIS and BIT faculty with their email addresses |
| Tech Community | Posts and comments with up/down votes, notifications and reporting |
| Admin | Stats dashboard, student list, community browser and a moderation queue for reports |

Google Sign-In appears on the login screen but is not connected to the backend yet;
email and password login works.

## Repository layout

| Folder | Contents |
| --- | --- |
| [`smart_pass_backend/`](smart_pass_backend) | Django project. `api/` holds the models (`User`, `Post`, `Comment`, `Notification`, `Report`, `Exam`), serializers, viewsets, permissions and tests |
| [`smart_student_frontend/`](smart_student_frontend) | Flutter app. `lib/screens/` holds the student and admin screens, `lib/services/` the API client and auth, `assets/translations/` the Arabic and English strings |

## API

All routes are under `/api/`.

| Route | Purpose |
| --- | --- |
| `auth/login/`, `auth/refresh/` | Get and refresh JWT tokens |
| `users/register/`, `users/me/`, `users/stats/` | Sign up, own profile, admin stats |
| `posts/`, `posts/{id}/comments/`, `posts/me/` | Community posts and their comments |
| `posts/{id}/upvote/`, `posts/{id}/downvote/` | Voting (also on `comments/{id}/`) |
| `notifications/`, `notifications/mark_all_read/` | The signed-in user's notifications |
| `reports/`, `reports/{id}/resolve/`, `reports/{id}/dismiss/` | Report content, admin moderation |
| `exams/` | The signed-in user's exams |

## Running locally

You need Python 3, PostgreSQL and the Flutter SDK (Dart 3.8.1 or newer).

**Backend**

```bash
cd smart_pass_backend
python -m venv venv
venv\Scripts\activate          # macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
```

Create `smart_pass_backend/.env`:

```env
DJANGO_SECRET_KEY=change-me
DJANGO_DEBUG=True
DB_NAME=smart_student_db
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
```

Settings refuse to start without `DJANGO_SECRET_KEY` unless `DJANGO_DEBUG` is true.

```bash
python manage.py migrate
python manage.py createsuperuser   # optional, for an admin account
python manage.py runserver
```

**App**

```bash
cd smart_student_frontend
cp .env.example .env               # then set GEMINI_API_KEY and API_BASE_URL
flutter pub get
flutter run
```

If `API_BASE_URL` is not set, the app uses `http://10.0.2.2:8000/api` on the Android
emulator and `http://127.0.0.1:8000/api` on desktop and web. On a physical phone, use
your computer's LAN address. `.env` is bundled into the app, so use a Gemini key that
is restricted to this app.

More setup detail: [backend README](smart_pass_backend/README.md),
[app README](smart_student_frontend/README.md).

## Tests

The backend tests run against an in-memory SQLite database, so PostgreSQL isn't needed:

```bash
cd smart_pass_backend
python manage.py test --settings=smart_backend.test_settings
```

They cover protection against writing read-only fields (authors, report status),
blocking non-admins from changing reports, password rules on sign-up, and throttling
on the auth endpoints.
