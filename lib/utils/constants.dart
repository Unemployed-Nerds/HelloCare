class AppConstants {
  // App Info
  static const String appName = 'HelloCare';
  static const String packageName = 'com.unemloyednerds.hellocare';
  
  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  
  // Report Types
  static const String reportTypeImage = 'image';
  static const String reportTypePdf = 'pdf';
  
  // Appointment Status
  static const String appointmentStatusPending = 'pending';
  static const String appointmentStatusConfirmed = 'confirmed';
  static const String appointmentStatusCompleted = 'completed';
  static const String appointmentStatusCancelled = 'cancelled';
  
  // Appointment Duration (in minutes)
  static const int appointmentDuration = 30;
  
  // Default Doctor Availability
  static const int defaultStartHour = 9;
  static const int defaultEndHour = 17;
  
  // Default Pinned Modules
  static const List<String> defaultPinnedModules = [
    'submit_report',
    'view_reports',
    'appointments',
  ];
  
  // Module IDs
  static const String moduleSubmitReport = 'submit_report';
  static const String moduleViewReports = 'view_reports';
  static const String moduleAISummary = 'ai_summary';
  static const String moduleSuggestions = 'suggestions';
  static const String moduleBookAppointment = 'book_appointment';
  static const String moduleMyAppointments = 'my_appointments';
  static const String moduleShareReports = 'share_reports';
  static const String moduleExportReports = 'export_reports';
  static const String moduleProfile = 'profile';
  static const String moduleDoctorPortal = 'doctor_portal';
  
  // Storage Keys
  static const String keyPinnedModules = 'pinned_modules';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
}


