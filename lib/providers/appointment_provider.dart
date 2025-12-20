import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class AppointmentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatientAppointments(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _firestoreService.getPatientAppointments(patientId);
      await _cacheService.cacheAppointments(_appointments);
      _error = null;
    } catch (e) {
      try {
        _appointments = await _cacheService.getCachedAppointments();
        _error = 'Using cached data. Please check your connection.';
      } catch (cacheError) {
        _error = e.toString();
        _appointments = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctorAppointments(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _firestoreService.getDoctorAppointments(doctorId);
      await _cacheService.cacheAppointments(_appointments);
      _error = null;
    } catch (e) {
      try {
        _appointments = await _cacheService.getCachedAppointments();
        _error = 'Using cached data. Please check your connection.';
      } catch (cacheError) {
        _error = e.toString();
        _appointments = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Appointment>> getPatientAppointmentsStream(String patientId) {
    return _firestoreService.getPatientAppointmentsStream(patientId);
  }

  Stream<List<Appointment>> getDoctorAppointmentsStream(String doctorId) {
    return _firestoreService.getDoctorAppointmentsStream(doctorId);
  }

  Future<bool> bookAppointment({
    required String doctorId,
    required String patientId,
    required String patientName,
    required DateTime date,
    required String time,
    int duration = 30,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.bookAppointment({
        'doctorId': doctorId,
        'date': date.toIso8601String().split('T')[0],
        'time': time,
        'duration': duration,
        'notes': notes,
      });

      if (!response['success']) {
        throw Exception(response['error']?['message'] ?? 'Failed to book appointment');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      if (!response['success']) {
        throw Exception('Failed to update appointment status');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDoctorNotes({
    required String appointmentId,
    required String doctorNotes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.addDoctorNotes(
        appointmentId: appointmentId,
        doctorNotes: doctorNotes,
      );

      if (!response['success']) {
        throw Exception('Failed to add notes');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
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


