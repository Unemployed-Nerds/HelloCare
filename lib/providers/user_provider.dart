import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null || _authService.currentUser != null;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    final user = _authService.currentUser;
    if (user != null) {
      await loadUserData(user.uid);
    }
  }

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getUser(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> patientSignUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.patientSignUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
      );
      await loadUserData(userCredential.user!.uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> doctorSignUp({
    required String email,
    required String password,
    required String name,
    required String specialization,
    required int yearsOfExperience,
    String? phone,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.doctorSignUp(
        email: email,
        password: password,
        name: name,
        specialization: specialization,
        yearsOfExperience: yearsOfExperience,
        phone: phone,
        bio: bio,
      );
      await loadUserData(userCredential.user!.uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    String? role, // Optional: 'patient' or 'doctor'
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signIn(
        email: email,
        password: password,
        role: role,
      );
      await loadUserData(userCredential.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      // Extract meaningful error message from FirebaseAuthException
      _error = e.message ?? e.code ?? 'Login failed';
      return false;
    } catch (e) {
      // Handle other exceptions
      _error = e.toString().replaceFirst('Exception: ', '');
      if (_error!.startsWith('Login failed')) {
        _error = 'Login failed. Please check your credentials and try again.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateUser(user);
      _currentUser = user;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

