import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as models;
import 'api_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  firebase_auth.User? get currentUser => _auth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Patient Sign Up
  Future<firebase_auth.UserCredential> patientSignUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    // Call backend API for signup
    final signupData = {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
    };

    final response = await _apiService.patientSignup(signupData);

    if (!response['success']) {
      final errorMessage = response['error']?['message'] ?? 'Sign up failed';
      throw firebase_auth.FirebaseAuthException(
        code: 'signup-failed',
        message: errorMessage,
      );
    }

    // Get custom token from API response
    final customToken = response['data']?['token'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw firebase_auth.FirebaseAuthException(
        code: 'invalid-token',
        message: 'No token received from server',
      );
    }

    // Sign in with custom token
    final userCredential = await _auth.signInWithCustomToken(customToken);
    return userCredential;
  }

  // Doctor Sign Up
  Future<firebase_auth.UserCredential> doctorSignUp({
    required String email,
    required String password,
    required String name,
    required String specialization,
    required int yearsOfExperience,
    String? phone,
    String? bio,
  }) async {
    // Call backend API for signup
    final signupData = {
      'email': email,
      'password': password,
      'name': name,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
    };

    final response = await _apiService.doctorSignup(signupData);

    if (!response['success']) {
      final errorMessage = response['error']?['message'] ?? 'Sign up failed';
      throw firebase_auth.FirebaseAuthException(
        code: 'signup-failed',
        message: errorMessage,
      );
    }

    // Get custom token from API response
    final customToken = response['data']?['token'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw firebase_auth.FirebaseAuthException(
        code: 'invalid-token',
        message: 'No token received from server',
      );
    }

    // Sign in with custom token
    final userCredential = await _auth.signInWithCustomToken(customToken);
    return userCredential;
  }

  // Sign In
  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
    String? role, // Optional: 'patient' or 'doctor' to specify which endpoint
  }) async {
    // Determine which login endpoint to use based on role or try both
    Map<String, dynamic> response;
    
    if (role == 'patient') {
      response = await _apiService.patientLogin({
        'email': email,
        'password': password,
      });
    } else if (role == 'doctor') {
      response = await _apiService.doctorLogin({
        'email': email,
        'password': password,
      });
    } else {
      // Try patient first, then doctor if it fails
      try {
        response = await _apiService.patientLogin({
          'email': email,
          'password': password,
        });
      } catch (e) {
        response = await _apiService.doctorLogin({
          'email': email,
          'password': password,
        });
      }
    }

    if (!response['success']) {
      final errorMessage = response['error']?['message'] ?? 'Login failed';
      throw firebase_auth.FirebaseAuthException(
        code: 'login-failed',
        message: errorMessage,
      );
    }

    // Get custom token from API response
    final customToken = response['data']?['token'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw firebase_auth.FirebaseAuthException(
        code: 'invalid-token',
        message: 'No token received from server',
      );
    }

    // Sign in with custom token
    return await _auth.signInWithCustomToken(customToken);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Data
  Future<models.User?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return models.User.fromFirestore(doc);
    }
    return null;
  }

  // Update User Data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Get User Role
  Future<String?> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['role'] as String?;
    }
    return null;
  }
}

