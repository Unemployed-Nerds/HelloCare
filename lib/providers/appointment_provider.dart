import 'dart:async';
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
    final controller = StreamController<List<Appointment>>.broadcast();
    Timer? pollTimer;
    
    // Helper function to emit empty list safely
    void emitEmpty() {
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
    
    // Emit empty list immediately so StreamBuilder doesn't hang
    emitEmpty();
    
    // Fetch from API immediately
    _fetchDoctorAppointmentsFromAPI(doctorId, controller);
    
    // Set up periodic API polling every 30 seconds
    pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!controller.isClosed) {
        _fetchDoctorAppointmentsFromAPI(doctorId, controller);
      } else {
        timer.cancel();
      }
    });
    
    // Clean up when stream is closed
    controller.onCancel = () {
      pollTimer?.cancel();
    };
    
    return controller.stream;
  }

  Future<void> _fetchDoctorAppointmentsFromAPI(
    String doctorId,
    StreamController<List<Appointment>> controller,
  ) async {
    try {
      final response = await _apiService.getDoctorAppointments();
      
      if (response['success'] == true && response['data'] != null) {
        final appointmentsData = response['data']['appointments'] as List<dynamic>? ?? [];
        
        final appointments = <Appointment>[];
        for (var data in appointmentsData) {
          try {
            // Handle date parsing - it might be a string or already a date
            DateTime parseDate(dynamic dateValue) {
              if (dateValue == null) return DateTime.now();
              if (dateValue is String) {
                // Handle date-only strings (YYYY-MM-DD) for appointment dates
                if (dateValue.length == 10 && dateValue.split('-').length == 3) {
                  return DateTime.parse('${dateValue}T00:00:00Z');
                }
                return DateTime.parse(dateValue);
              } else if (dateValue is DateTime) {
                return dateValue;
              } else {
                return DateTime.now();
              }
            }
            
            DateTime parseDateTime(dynamic dateTimeValue) {
              if (dateTimeValue == null) return DateTime.now();
              if (dateTimeValue is String) {
                return DateTime.parse(dateTimeValue);
              } else if (dateTimeValue is DateTime) {
                return dateTimeValue;
              } else {
                return DateTime.now();
              }
            }
            
            final appointment = Appointment(
              appointmentId: data['appointmentId'] ?? '',
              doctorId: data['doctorId'] ?? doctorId,
              doctorName: data['doctorName'] ?? '',
              doctorSpecialization: data['doctorSpecialization'],
              patientId: data['patientId'] ?? '',
              patientName: data['patientName'] ?? '',
              date: parseDate(data['date']),
              time: data['time'] ?? '',
              duration: data['duration'] ?? 30,
              status: data['status'] ?? 'pending',
              notes: data['notes'],
              doctorNotes: data['doctorNotes'],
              createdAt: parseDateTime(data['createdAt']),
              updatedAt: data['updatedAt'] != null ? parseDateTime(data['updatedAt']) : null,
            );
            
            appointments.add(appointment);
          } catch (e) {
            // Skip this appointment but continue with others
          }
        }
        
        // Sort by date and time (descending)
        appointments.sort((a, b) {
          final dateCompare = b.date.compareTo(a.date);
          if (dateCompare != 0) return dateCompare;
          return b.time.compareTo(a.time);
        });
        
        if (!controller.isClosed) {
          controller.add(appointments);
        }
      } else {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    } catch (e) {
      // Emit empty list instead of error so UI doesn't break
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
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


