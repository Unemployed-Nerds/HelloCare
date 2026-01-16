# HelloCare Mobile

HelloCare is a comprehensive healthcare management mobile application built with Flutter. It empowers patients to securely store, manage, and share their medical records while providing AI-powered health insights.

## Features

- **Authentication**: Secure sign-up and login for patients using Firebase Authentication.
- **Medical Records**:
    - Upload and organize medical reports (PDF/Images).
    - View reports directly within the app.
- **QR Code Sharing**:
    - Generate secure QR codes to temporarily share specific medical records with doctors.
    - Control access and duration of shared links.
- **AI Health Companion**:
    - **Health Summary**: Get AI-generated summaries of your medical history.
    - **Smart Suggestions**: Receive personalized health tips based on your reports.
    - **Voice Interaction**: Talk to the AI assistant for hands-free health queries.
- **Scanner**: Built-in QR scanner for quick interactions.

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend/Auth**: Firebase (Auth, Firestore, Storage)
- **State Management**: Provider
- **Navigation**: GoRouter
- **Local Storage**: Hive
- **AI Integration**: Google Gemini (via Backend)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- Android Studio / Xcode (for mobile emulation)
- A configured Firebase project

## Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd HelloCare
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Add your `google-services.json` (Android) to `android/app/`.
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`.

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart`: Entry point of the application.
- `lib/features/`: Contains feature-specific code (Auth, Home, Reports, etc.).
- `lib/core/`: Shared utilities, services, and constants.

## Key Dependencies

- `firebase_auth`, `cloud_firestore`: Backend services.
- `camera`, `mobile_scanner`: QR scanning functionality.
- `pdfx`: PDF viewing support.
- `speech_to_text`, `flutter_tts`: Voice interaction features.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
