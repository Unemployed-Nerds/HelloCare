import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// Wrapper widget that handles Android back gesture navigation
/// Intercepts back button presses and edge swipe gestures
class BackGestureWrapper extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const BackGestureWrapper({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // Always intercept back gesture and handle through GoRouter
        if (!didPop) {
          final router = GoRouter.of(context);
          
          // Check if we can pop in the router
          if (context.canPop()) {
            // Navigate back through the router if there's history
            context.pop();
          } else {
            // Since we're using context.go() which doesn't maintain history,
            // we need to manually navigate back based on the route hierarchy
            if (currentLocation.startsWith('/patient/') && 
                currentLocation != '/patient/main') {
              // Child routes of patient -> go to patient main
              router.go('/patient/main');
            } else if (currentLocation.startsWith('/doctor/') && 
                       currentLocation != '/doctor/portal') {
              // Child routes of doctor -> go to doctor portal
              router.go('/doctor/portal');
            } else if (currentLocation != '/role-selection' &&
                       (currentLocation.startsWith('/patient-') || 
                        currentLocation.startsWith('/doctor-'))) {
              // Auth pages -> go to role selection
              router.go('/role-selection');
            }
            // For root routes (/role-selection, /patient/main, /doctor/portal),
            // allow the system to handle (which may close the app)
          }
        }
      },
      child: child,
    );
  }
}

GoRouter createAppRouter(UserProvider userProvider) {
  return GoRouter(
    initialLocation: '/role-selection',
    redirect: (context, state) {
      final isAuthenticated = userProvider.isAuthenticated;
      final currentUser = userProvider.currentUser;
      
      final isAuthRoute = state.matchedLocation.startsWith('/role-selection') ||
          state.matchedLocation.startsWith('/patient-login') ||
          state.matchedLocation.startsWith('/patient-signup') ||
          state.matchedLocation.startsWith('/doctor-login') ||
          state.matchedLocation.startsWith('/doctor-signup');

      // If authenticated and on auth route, redirect to appropriate main page
      // (but only if user data is loaded, otherwise wait for it)
      if (isAuthenticated && isAuthRoute) {
        if (currentUser != null) {
          if (currentUser.role == 'patient') {
            return '/patient/main';
          } else if (currentUser.role == 'doctor') {
            return '/doctor/portal';
          }
        }
        // If authenticated but user data not loaded yet, stay on auth route
        // The redirect will be re-evaluated once user data loads
        return null;
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return '/role-selection';
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
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const RoleSelectionPage(),
      ),
    ),
    GoRoute(
      path: '/patient-login',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const PatientLoginPage(),
      ),
    ),
    GoRoute(
      path: '/patient-signup',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const PatientSignupPage(),
      ),
    ),
    GoRoute(
      path: '/doctor-login',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorLoginPage(),
      ),
    ),
    GoRoute(
      path: '/doctor-signup',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorSignupPage(),
      ),
    ),

    // Patient Routes
    GoRoute(
      path: '/patient/main',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const PatientMainPage(),
      ),
    ),
    GoRoute(
      path: '/patient/submit-report',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const SubmitReportPage(),
      ),
    ),
    GoRoute(
      path: '/patient/reports',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const ReportsListPage(),
      ),
    ),
    GoRoute(
      path: '/patient/report/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return BackGestureWrapper(
          currentLocation: state.matchedLocation,
          child: ReportDetailPage(reportId: reportId),
        );
      },
    ),
    GoRoute(
      path: '/patient/ai-summary',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const AISummaryPage(),
      ),
    ),
    GoRoute(
      path: '/patient/suggestions',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const SuggestionsPage(),
      ),
    ),
    GoRoute(
      path: '/patient/book-appointment',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const BookAppointmentPage(),
      ),
    ),
    GoRoute(
      path: '/patient/appointments',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const AppointmentsPage(),
      ),
    ),
    GoRoute(
      path: '/patient/share-reports',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const ShareReportsPage(),
      ),
    ),
    GoRoute(
      path: '/patient/export-reports',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const ExportReportsPage(),
      ),
    ),
    GoRoute(
      path: '/patient/profile',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const ProfilePage(),
      ),
    ),

    // Doctor Routes
    GoRoute(
      path: '/doctor/portal',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorPortalPage(),
      ),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorAppointmentsPage(),
      ),
    ),
    GoRoute(
      path: '/doctor/availability',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorAvailabilityPage(),
      ),
    ),
    GoRoute(
      path: '/doctor/profile',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const DoctorProfilePage(),
      ),
    ),
    GoRoute(
      path: '/doctor/scan-qr',
      builder: (context, state) => BackGestureWrapper(
        currentLocation: state.matchedLocation,
        child: const ScanQRPage(),
      ),
    ),
    GoRoute(
      path: '/doctor/patient-reports',
      builder: (context, state) {
        final qrToken = state.uri.queryParameters['token'];
        return BackGestureWrapper(
          currentLocation: state.matchedLocation,
          child: ViewPatientReportsPage(qrToken: qrToken),
        );
      },
    ),
  ],
  );
}

