# HelloCare Backend API Documentation

## Base URL
```
https://hellocare.p1ng.me/v1
```

## Authentication
All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <access_token>
```

The access token is obtained from Firebase Auth and should be sent with each request.

---

## Endpoints

### 1. Authentication

#### 1.1 Patient Sign Up
**POST** `/auth/patient/signup`

**Request Body:**
```json
{
  "email": "patient@example.com",
  "password": "securepassword123",
  "name": "John Doe",
  "phone": "+1234567890",
  "dateOfBirth": "1990-01-01"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Patient registered successfully",
  "data": {
    "userId": "user123",
    "email": "patient@example.com",
    "name": "John Doe",
    "role": "patient"
  }
}
```

#### 1.2 Patient Login
**POST** `/auth/patient/login`

**Request Body:**
```json
{
  "email": "patient@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "firebase_id_token",
    "userId": "user123",
    "email": "patient@example.com",
    "name": "John Doe",
    "role": "patient"
  }
}
```

#### 1.3 Doctor Sign Up
**POST** `/auth/doctor/signup`

**Request Body:**
```json
{
  "email": "doctor@example.com",
  "password": "securepassword123",
  "name": "Dr. Jane Smith",
  "phone": "+1234567890",
  "specialization": "Cardiology",
  "yearsOfExperience": 10,
  "bio": "Experienced cardiologist..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Doctor registered successfully",
  "data": {
    "userId": "doctor123",
    "email": "doctor@example.com",
    "name": "Dr. Jane Smith",
    "role": "doctor"
  }
}
```

#### 1.4 Doctor Login
**POST** `/auth/doctor/login`

**Request Body:**
```json
{
  "email": "doctor@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "firebase_id_token",
    "userId": "doctor123",
    "email": "doctor@example.com",
    "name": "Dr. Jane Smith",
    "role": "doctor"
  }
}
```

---

### 2. Reports

#### 2.1 Get S3 Upload URL
**POST** `/reports/upload-url`

**Request Body:**
```json
{
  "fileName": "report_123.pdf",
  "fileType": "application/pdf",
  "fileSize": 1024000
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "uploadUrl": "https://s3.amazonaws.com/bucket/path/to/file?presigned_url",
    "fileKey": "reports/user123/report_123.pdf",
    "expiresIn": 3600
  }
}
```

#### 2.2 Submit Report Metadata
**POST** `/reports`

**Request Body:**
```json
{
  "fileKey": "reports/user123/report_123.pdf",
  "fileName": "report_123.pdf",
  "fileType": "pdf",
  "title": "Blood Test Report",
  "reportDate": "2024-01-15",
  "category": "Lab Test",
  "doctorName": "Dr. Smith",
  "clinicName": "City Hospital"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Report submitted successfully",
  "data": {
    "reportId": "report123",
    "fileKey": "reports/user123/report_123.pdf",
    "fileName": "report_123.pdf",
    "fileType": "pdf",
    "title": "Blood Test Report",
    "reportDate": "2024-01-15",
    "category": "Lab Test",
    "doctorName": "Dr. Smith",
    "clinicName": "City Hospital",
    "uploadDate": "2024-01-20T10:30:00Z",
    "userId": "user123"
  }
}
```

#### 2.3 Get User Reports
**GET** `/reports`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `category` (optional): Filter by category
- `fileType` (optional): Filter by file type (image/pdf)
- `startDate` (optional): Filter by start date (ISO 8601)
- `endDate` (optional): Filter by end date (ISO 8601)
- `search` (optional): Search in title, doctor name, clinic name

**Response:**
```json
{
  "success": true,
  "data": {
    "reports": [
      {
        "reportId": "report123",
        "fileKey": "reports/user123/report_123.pdf",
        "fileName": "report_123.pdf",
        "fileType": "pdf",
        "title": "Blood Test Report",
        "reportDate": "2024-01-15",
        "category": "Lab Test",
        "doctorName": "Dr. Smith",
        "clinicName": "City Hospital",
        "uploadDate": "2024-01-20T10:30:00Z",
        "s3Url": "https://s3.amazonaws.com/bucket/path/to/file"
      }
    ],
    "total": 50,
    "page": 1,
    "limit": 20
  }
}
```

#### 2.4 Get Report Details
**GET** `/reports/{reportId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "reportId": "report123",
    "fileKey": "reports/user123/report_123.pdf",
    "fileName": "report_123.pdf",
    "fileType": "pdf",
    "title": "Blood Test Report",
    "reportDate": "2024-01-15",
    "category": "Lab Test",
    "doctorName": "Dr. Smith",
    "clinicName": "City Hospital",
    "uploadDate": "2024-01-20T10:30:00Z",
    "s3Url": "https://s3.amazonaws.com/bucket/path/to/file",
    "extractedText": "OCR extracted text from the document..."
  }
}
```

#### 2.5 Get S3 Download URL
**GET** `/reports/{reportId}/download-url`

**Response:**
```json
{
  "success": true,
  "data": {
    "downloadUrl": "https://s3.amazonaws.com/bucket/path/to/file?presigned_url",
    "expiresIn": 3600
  }
}
```

#### 2.6 Export Reports
**POST** `/reports/export`

**Request Body:**
```json
{
  "reportIds": ["report123", "report456", "report789"],
  "format": "zip"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "exportUrl": "https://s3.amazonaws.com/bucket/exports/export_123.zip",
    "expiresIn": 3600
  }
}
```

---

### 3. AI Features

#### 3.1 Get AI Summary
**GET** `/ai/summary`

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": "Based on your medical reports, your overall health status shows...",
    "generatedAt": "2024-01-20T10:30:00Z",
    "reportCount": 15,
    "lastReportDate": "2024-01-15"
  }
}
```

#### 3.2 Get AI Suggestions
**GET** `/ai/suggestions`

**Query Parameters:**
- `reportId` (optional): Get suggestions for a specific report. If not provided, returns overall suggestions.

**Response (Overall):**
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "type": "lifestyle",
        "title": "Improve Sleep Quality",
        "description": "Based on your reports, consider maintaining a regular sleep schedule...",
        "priority": "high"
      },
      {
        "type": "diet",
        "title": "Reduce Sodium Intake",
        "description": "Your recent reports indicate elevated blood pressure...",
        "priority": "medium"
      }
    ],
    "generatedAt": "2024-01-20T10:30:00Z"
  }
}
```

**Response (Per Report):**
```json
{
  "success": true,
  "data": {
    "reportId": "report123",
    "suggestions": [
      {
        "type": "follow_up",
        "title": "Schedule Follow-up Test",
        "description": "Your blood test results show...",
        "priority": "high"
      }
    ],
    "generatedAt": "2024-01-20T10:30:00Z"
  }
}
```

---

### 4. QR Code Sharing

#### 4.1 Generate QR Code for Reports
**POST** `/reports/qr/generate`

**Request Body:**
```json
{
  "reportIds": ["report123", "report456"],
  "expiresIn": 3600
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "qrToken": "encrypted_token_here",
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "expiresAt": "2024-01-20T11:30:00Z"
  }
}
```

#### 4.2 Validate QR Code Token
**POST** `/reports/qr/validate`

**Request Body:**
```json
{
  "qrToken": "encrypted_token_here"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "reportIds": ["report123", "report456"],
    "expiresAt": "2024-01-20T11:30:00Z"
  }
}
```

#### 4.3 Get Reports via QR Token (Doctor Access)
**GET** `/reports/qr/{qrToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "reports": [
      {
        "reportId": "report123",
        "fileName": "report_123.pdf",
        "fileType": "pdf",
        "title": "Blood Test Report",
        "reportDate": "2024-01-15",
        "s3Url": "https://s3.amazonaws.com/bucket/path/to/file"
      }
    ],
    "expiresAt": "2024-01-20T11:30:00Z"
  }
}
```

---

### 5. Doctors

#### 5.1 Get All Doctors
**GET** `/doctors`

**Query Parameters:**
- `specialization` (optional): Filter by specialization
- `search` (optional): Search in name, specialization, bio

**Response:**
```json
{
  "success": true,
  "data": {
    "doctors": [
      {
        "doctorId": "doctor123",
        "name": "Dr. Jane Smith",
        "email": "doctor@example.com",
        "phone": "+1234567890",
        "specialization": "Cardiology",
        "bio": "Experienced cardiologist with 10 years of experience...",
        "yearsOfExperience": 10,
        "rating": 4.8,
        "reviewCount": 150,
        "profileImageUrl": "https://s3.amazonaws.com/bucket/profiles/doctor123.jpg"
      }
    ]
  }
}
```

#### 5.2 Get Doctor Details
**GET** `/doctors/{doctorId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "doctorId": "doctor123",
    "name": "Dr. Jane Smith",
    "email": "doctor@example.com",
    "phone": "+1234567890",
    "specialization": "Cardiology",
    "bio": "Experienced cardiologist with 10 years of experience...",
    "yearsOfExperience": 10,
    "rating": 4.8,
    "reviewCount": 150,
    "profileImageUrl": "https://s3.amazonaws.com/bucket/profiles/doctor123.jpg",
    "availability": {
      "monday": {"start": "09:00", "end": "17:00", "available": true},
      "tuesday": {"start": "09:00", "end": "17:00", "available": true},
      "wednesday": {"start": "09:00", "end": "17:00", "available": true},
      "thursday": {"start": "09:00", "end": "17:00", "available": true},
      "friday": {"start": "09:00", "end": "17:00", "available": true},
      "saturday": {"start": null, "end": null, "available": false},
      "sunday": {"start": null, "end": null, "available": false}
    }
  }
}
```

#### 5.3 Update Doctor Availability
**PUT** `/doctors/{doctorId}/availability`

**Request Body:**
```json
{
  "availability": {
    "monday": {"start": "09:00", "end": "17:00", "available": true},
    "tuesday": {"start": "09:00", "end": "17:00", "available": true},
    "wednesday": {"start": "09:00", "end": "17:00", "available": true},
    "thursday": {"start": "09:00", "end": "17:00", "available": true},
    "friday": {"start": "09:00", "end": "17:00", "available": true},
    "saturday": {"start": null, "end": null, "available": false},
    "sunday": {"start": null, "end": null, "available": false}
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Availability updated successfully"
}
```

#### 5.4 Get Available Time Slots
**GET** `/doctors/{doctorId}/slots`

**Query Parameters:**
- `date`: Date in YYYY-MM-DD format

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2024-01-25",
    "slots": [
      {"time": "09:00", "available": true},
      {"time": "09:30", "available": true},
      {"time": "10:00", "available": false},
      {"time": "10:30", "available": true}
    ]
  }
}
```

---

### 6. Appointments

#### 6.1 Book Appointment
**POST** `/appointments`

**Request Body:**
```json
{
  "doctorId": "doctor123",
  "date": "2024-01-25",
  "time": "10:00",
  "duration": 30,
  "notes": "Follow-up consultation"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Appointment booked successfully",
  "data": {
    "appointmentId": "appt123",
    "doctorId": "doctor123",
    "doctorName": "Dr. Jane Smith",
    "patientId": "user123",
    "patientName": "John Doe",
    "date": "2024-01-25",
    "time": "10:00",
    "duration": 30,
    "status": "pending",
    "notes": "Follow-up consultation",
    "createdAt": "2024-01-20T10:30:00Z"
  }
}
```

#### 6.2 Get Patient Appointments
**GET** `/appointments/patient`

**Query Parameters:**
- `status` (optional): Filter by status (pending/confirmed/completed/cancelled)
- `startDate` (optional): Filter by start date
- `endDate` (optional): Filter by end date
- `doctorId` (optional): Filter by doctor

**Response:**
```json
{
  "success": true,
  "data": {
    "appointments": [
      {
        "appointmentId": "appt123",
        "doctorId": "doctor123",
        "doctorName": "Dr. Jane Smith",
        "doctorSpecialization": "Cardiology",
        "date": "2024-01-25",
        "time": "10:00",
        "duration": 30,
        "status": "pending",
        "notes": "Follow-up consultation",
        "createdAt": "2024-01-20T10:30:00Z"
      }
    ]
  }
}
```

#### 6.3 Get Doctor Appointments
**GET** `/appointments/doctor`

**Query Parameters:**
- `status` (optional): Filter by status
- `date` (optional): Filter by specific date
- `startDate` (optional): Filter by start date
- `endDate` (optional): Filter by end date

**Response:**
```json
{
  "success": true,
  "data": {
    "appointments": [
      {
        "appointmentId": "appt123",
        "patientId": "user123",
        "patientName": "John Doe",
        "date": "2024-01-25",
        "time": "10:00",
        "duration": 30,
        "status": "pending",
        "notes": "Follow-up consultation",
        "doctorNotes": null,
        "createdAt": "2024-01-20T10:30:00Z"
      }
    ]
  }
}
```

#### 6.4 Get Appointment Details
**GET** `/appointments/{appointmentId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "appointmentId": "appt123",
    "doctorId": "doctor123",
    "doctorName": "Dr. Jane Smith",
    "patientId": "user123",
    "patientName": "John Doe",
    "date": "2024-01-25",
    "time": "10:00",
    "duration": 30,
    "status": "pending",
    "notes": "Follow-up consultation",
    "doctorNotes": null,
    "createdAt": "2024-01-20T10:30:00Z"
  }
}
```

#### 6.5 Update Appointment Status
**PUT** `/appointments/{appointmentId}/status`

**Request Body:**
```json
{
  "status": "confirmed"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Appointment status updated successfully"
}
```

#### 6.6 Add Doctor Notes to Appointment
**PUT** `/appointments/{appointmentId}/notes`

**Request Body:**
```json
{
  "doctorNotes": "Patient showed improvement. Recommended follow-up in 2 weeks."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notes updated successfully"
}
```

#### 6.7 Cancel Appointment
**DELETE** `/appointments/{appointmentId}`

**Response:**
```json
{
  "success": true,
  "message": "Appointment cancelled successfully"
}
```

---

### 7. Payment (Mock)

#### 7.1 Process Payment
**POST** `/payment/process`

**Request Body:**
```json
{
  "appointmentId": "appt123",
  "amount": 100.00,
  "currency": "USD",
  "paymentMethod": "card"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment processed successfully (mock)",
  "data": {
    "transactionId": "txn_mock_123",
    "amount": 100.00,
    "currency": "USD",
    "status": "completed",
    "processedAt": "2024-01-20T10:30:00Z"
  }
}
```

---

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes:
- `UNAUTHORIZED`: Authentication required or invalid token
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `VALIDATION_ERROR`: Invalid request data
- `SERVER_ERROR`: Internal server error
- `RATE_LIMIT_EXCEEDED`: Too many requests

---

## S3 Integration Flow

### Upload Flow:
1. Client requests upload URL from `/reports/upload-url`
2. Backend generates presigned S3 URL
3. Client uploads file directly to S3 using presigned URL
4. Client submits report metadata to `/reports`
5. Backend processes file (OCR, extraction) and stores metadata in Firestore

### Download Flow:
1. Client requests download URL from `/reports/{reportId}/download-url`
2. Backend generates presigned S3 URL
3. Client downloads file using presigned URL

---

## Notes

- All dates should be in ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:mm:ssZ)
- All times should be in 24-hour format (HH:mm)
- File sizes are in bytes
- Presigned URLs expire after the specified `expiresIn` seconds (default: 3600)
- QR tokens should be encrypted and time-limited
- The backend should handle OCR processing asynchronously after file upload
- AI summaries and suggestions should be generated/updated when new reports are uploaded


