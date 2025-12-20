import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as models;

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userData = {
      'email': email,
      'name': name,
      'role': 'patient',
      'phone': phone,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userData);

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
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userData = {
      'email': email,
      'name': name,
      'role': 'doctor',
      'phone': phone,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'bio': bio,
      'rating': 0.0,
      'reviewCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userData);

    return userCredential;
  }

  // Sign In
  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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

