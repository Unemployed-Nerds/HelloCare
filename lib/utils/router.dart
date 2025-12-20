import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/role_selection_page.dart';
import '../screens/auth/patient_login_page.dart';
import '../screens/auth/patient_signup_page.dart';
import '../screens/auth/doctor_login_page.dart';
import '../screens/auth/doctor_signup_page.dart';
import '../screens/patient/main_page.dart';
import '../screens/patient/submit_report_page.dart';
import '../screens/patient/reports_list_page.dart';
import '../screens/patient/report_detail_page.dart';
import '../screens/patient/ai_summary_page.dart';
import '../screens/patient/suggestions_page.dart';
import '../screens/patient/book_appointment_page.dart';
import '../screens/patient/appointments_page.dart';
import '../screens/patient/share_reports_page.dart';
import '../screens/patient/export_reports_page.dart';
import '../screens/patient/profile_page.dart';
import '../screens/doctor/doctor_portal_page.dart';
import '../screens/doctor/doctor_appointments_page.dart';
import '../screens/doctor/doctor_availability_page.dart';
import '../screens/doctor/doctor_profile_page.dart';
import '../screens/doctor/scan_qr_page.dart';
import '../screens/doctor/view_patient_reports_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/role-selection',
  redirect: (context, state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAuthenticated = userProvider.isAuthenticated;
    final currentUser = userProvider.currentUser;
    
    final isAuthRoute = state.matchedLocation.startsWith('/role-selection') ||
        state.matchedLocation.startsWith('/patient-login') ||
        state.matchedLocation.startsWith('/patient-signup') ||
        state.matchedLocation.startsWith('/doctor-login') ||
        state.matchedLocation.startsWith('/doctor-signup');

    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !isAuthRoute) {
      return '/role-selection';
    }

    // If authenticated and on auth route, redirect based on role
    if (isAuthenticated && isAuthRoute) {
      if (currentUser?.role == 'patient') {
        return '/patient/main';
      } else if (currentUser?.role == 'doctor') {
        return '/doctor/portal';
      }
    }

    // Role-based route protection
    if (isAuthenticated && currentUser != null) {
      final isPatientRoute = state.matchedLocation.startsWith('/patient');
      final isDoctorRoute = state.matchedLocation.startsWith('/doctor');

      if (currentUser.role == 'patient' && isDoctorRoute) {
        return '/patient/main';
      }
      if (currentUser.role == 'doctor' && isPatientRoute) {
        return '/doctor/portal';
      }
    }

    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/patient-login',
      builder: (context, state) => const PatientLoginPage(),
    ),
    GoRoute(
      path: '/patient-signup',
      builder: (context, state) => const PatientSignupPage(),
    ),
    GoRoute(
      path: '/doctor-login',
      builder: (context, state) => const DoctorLoginPage(),
    ),
    GoRoute(
      path: '/doctor-signup',
      builder: (context, state) => const DoctorSignupPage(),
    ),

    // Patient Routes
    GoRoute(
      path: '/patient/main',
      builder: (context, state) => const PatientMainPage(),
    ),
    GoRoute(
      path: '/patient/submit-report',
      builder: (context, state) => const SubmitReportPage(),
    ),
    GoRoute(
      path: '/patient/reports',
      builder: (context, state) => const ReportsListPage(),
    ),
    GoRoute(
      path: '/patient/report/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return ReportDetailPage(reportId: reportId);
      },
    ),
    GoRoute(
      path: '/patient/ai-summary',
      builder: (context, state) => const AISummaryPage(),
    ),
    GoRoute(
      path: '/patient/suggestions',
      builder: (context, state) => const SuggestionsPage(),
    ),
    GoRoute(
      path: '/patient/book-appointment',
      builder: (context, state) => const BookAppointmentPage(),
    ),
    GoRoute(
      path: '/patient/appointments',
      builder: (context, state) => const AppointmentsPage(),
    ),
    GoRoute(
      path: '/patient/share-reports',
      builder: (context, state) => const ShareReportsPage(),
    ),
    GoRoute(
      path: '/patient/export-reports',
      builder: (context, state) => const ExportReportsPage(),
    ),
    GoRoute(
      path: '/patient/profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // Doctor Routes
    GoRoute(
      path: '/doctor/portal',
      builder: (context, state) => const DoctorPortalPage(),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => const DoctorAppointmentsPage(),
    ),
    GoRoute(
      path: '/doctor/availability',
      builder: (context, state) => const DoctorAvailabilityPage(),
    ),
    GoRoute(
      path: '/doctor/profile',
      builder: (context, state) => const DoctorProfilePage(),
    ),
    GoRoute(
      path: '/doctor/scan-qr',
      builder: (context, state) => const ScanQRPage(),
    ),
    GoRoute(
      path: '/doctor/patient-reports',
      builder: (context, state) {
        final qrToken = state.uri.queryParameters['token'];
        return ViewPatientReportsPage(qrToken: qrToken);
      },
    ),
  ],
);


