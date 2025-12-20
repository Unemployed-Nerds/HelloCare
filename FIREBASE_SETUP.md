# Firebase Setup Instructions

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "HelloCare"
4. Follow the setup wizard

## 2. Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.unemloyednerds.hellocare`
3. Download `google-services.json`
4. Place it in `android/app/` directory

## 3. Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Enable "Email/Password" sign-in method

## 4. Create Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Start in test mode (for development)
4. Choose a location for your database

## 5. Update Android Configuration

The `google-services.json` file should already be in place. If not, ensure it's in `android/app/`.

## 6. Security Rules (for Firestore)

Update your Firestore security rules to:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Appointments collection
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid);
    }
  }
}
```

## 7. Backend API Configuration

Update the base URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://your-api-url.com/v1';
```

Replace with your actual backend API URL.


