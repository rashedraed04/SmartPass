# Smart Student Frontend

This is the mobile application for the Smart Pass platform, designed to provide an intuitive and seamless experience for students.

## Tech Stack Overview
- **Flutter**: Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
- **Dart**: The programming language used to develop Flutter apps.

## Setup Instructions

Follow these steps to configure and run the application locally.

### 1. Prerequisites
Ensure you have the Flutter SDK installed and configured on your system. 

### 2. Fetch Dependencies
Navigate to the project directory and retrieve all necessary packages:
```bash
flutter pub get
```

### 3. Configure Environment Variables
The application reads its settings from a `.env` file, which is bundled into the app, so never put secrets in it.
Copy the provided example file to create your own configuration:
- Copy `.env.example` and rename it to `.env`.
- Set `API_BASE_URL` if the default doesn't fit your setup.

### 4. Run the Application
Start the app on an attached device or emulator:
```bash
flutter run
```

## Available Environment Variables
- `API_BASE_URL`: The endpoint base URL for the backend API.
- The Gemini key for the Academic Assistant is not set here: it lives in the backend's `.env`, because this file is bundled into the app.
