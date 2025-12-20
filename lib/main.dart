import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/theme.dart';
import 'utils/router.dart';
import 'providers/user_provider.dart';
import 'providers/report_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/module_provider.dart';
import 'providers/voice_assistant_provider.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize cache
  await CacheService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UserProvider _userProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _userProvider = UserProvider();
    _router = createAppRouter(_userProvider);
    
    // Listen to auth state changes and refresh router
    _userProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    // Refresh router when auth state changes to re-evaluate redirects
    _router.refresh();
  }

  @override
  void dispose() {
    _userProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => ModuleProvider()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantProvider()),
      ],
      child: MaterialApp.router(
        title: 'HelloCare',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
