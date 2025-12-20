import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';

class DoctorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();

  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;
  bool _isLoading = false;
  String? _error;

  List<Doctor> get doctors => _doctors;
  Doctor? get selectedDoctor => _selectedDoctor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDoctors({String? specialization, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use API endpoint to get doctors from the doctors collection
      final response = await _apiService.getDoctors(
        specialization: specialization,
        search: search,
      );
      
      if (response['success'] == true) {
        final doctorsData = response['data']?['doctors'] as List? ?? [];
        _doctors = doctorsData.map((data) {
          return Doctor(
            doctorId: data['doctorId'] ?? '',
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'],
            specialization: data['specialization'] ?? '',
            bio: data['bio'],
            yearsOfExperience: data['yearsOfExperience'] ?? 0,
            rating: (data['rating'] ?? 0.0).toDouble(),
            reviewCount: data['reviewCount'] ?? 0,
            profileImageUrl: data['profileImageUrl'],
            availability: {},
            createdAt: DateTime.now(), // API doesn't return these, use current time
            updatedAt: DateTime.now(),
          );
        }).toList();
        _error = null;
      } else {
        throw Exception(response['error']?['message'] ?? 'Failed to load doctors');
      }
    } catch (e) {
      _error = e.toString();
      _doctors = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Doctor>> getDoctorsStream() {
    return _firestoreService.getDoctorsStream();
  }

  Future<void> loadDoctor(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use API endpoint to get doctor from the doctors collection
      final response = await _apiService.getDoctor(doctorId);
      
      if (response['success'] == true) {
        final data = response['data'];
        final availabilityData = data['availability'] as Map<String, dynamic>? ?? {};
        
        // Convert availability map to DoctorAvailability objects
        final availability = <String, DoctorAvailability>{};
        availabilityData.forEach((key, value) {
          if (value is Map) {
            availability[key] = DoctorAvailability.fromMap(Map<String, dynamic>.from(value));
          }
        });
        
        _selectedDoctor = Doctor(
          doctorId: data['doctorId'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'],
          specialization: data['specialization'] ?? '',
          bio: data['bio'],
          yearsOfExperience: data['yearsOfExperience'] ?? 0,
          rating: (data['rating'] ?? 0.0).toDouble(),
          reviewCount: data['reviewCount'] ?? 0,
          profileImageUrl: data['profileImageUrl'],
          availability: availability,
          createdAt: DateTime.now(), // API doesn't return these
          updatedAt: DateTime.now(),
        );
        _error = null;
      } else {
        throw Exception(response['error']?['message'] ?? 'Failed to load doctor');
      }
    } catch (e) {
      _error = e.toString();
      _selectedDoctor = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final response = await _apiService.getAvailableSlots(
        doctorId: doctorId,
        date: date.toIso8601String().split('T')[0],
      );
      return response['data'];
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> updateAvailability({
    required String doctorId,
    required Map<String, dynamic> availability,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateDoctorAvailability(
        doctorId: doctorId,
        availability: availability,
      );

      if (!response['success']) {
        throw Exception('Failed to update availability');
      }

      await loadDoctor(doctorId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDoctor(Doctor? doctor) {
    _selectedDoctor = doctor;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


