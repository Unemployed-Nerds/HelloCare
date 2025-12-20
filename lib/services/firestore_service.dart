import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../models/doctor.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reports
  Future<void> addReport(Report report) async {
    await _firestore
        .collection('reports')
        .doc(report.reportId)
        .set(report.toFirestore());
  }

  Stream<List<Report>> getReportsStream(String userId) {
    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) {
          final reports = <Report>[];
          for (var doc in snapshot.docs) {
            try {
              reports.add(Report.fromFirestore(doc));
            } catch (e) {
              print('Error parsing report document ${doc.id}: $e');
              // Skip invalid documents instead of breaking the entire stream
            }
          }
          return reports;
        });
  }

  Future<List<Report>> getReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadDate', descending: true)
          .get();
      
      final reports = <Report>[];
      for (var doc in snapshot.docs) {
        try {
          reports.add(Report.fromFirestore(doc));
        } catch (e) {
          print('Error parsing report document ${doc.id}: $e');
          // Skip invalid documents instead of breaking the entire list
        }
      }
      return reports;
    } catch (e) {
      print('Error fetching reports: $e');
      // If the error is about missing index, provide helpful message
      if (e.toString().contains('index')) {
        throw Exception('Firestore index required. Please check Firebase console for index creation link.');
      }
      rethrow;
    }
  }

  Future<Report?> getReport(String reportId) async {
    final doc = await _firestore.collection('reports').doc(reportId).get();
    if (doc.exists) {
      return Report.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateReport(Report report) async {
    await _firestore
        .collection('reports')
        .doc(report.reportId)
        .update(report.toFirestore());
  }

  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }

  // Appointments
  Future<void> addAppointment(Appointment appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.appointmentId)
        .set(appointment.toFirestore());
  }

  Stream<List<Appointment>> getPatientAppointmentsStream(String patientId) {
    // Use simpler query with single orderBy to avoid composite index requirement
    // Sort by time on client side instead
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final appointments = <Appointment>[];
          for (var doc in snapshot.docs) {
            try {
              appointments.add(Appointment.fromFirestore(doc));
            } catch (e) {
              print('Error parsing appointment document ${doc.id}: $e');
              // Skip invalid documents instead of breaking the entire stream
            }
          }
          // Sort by date (descending) and time (descending) on client side
          appointments.sort((a, b) {
            final dateCompare = b.date.compareTo(a.date);
            if (dateCompare != 0) return dateCompare;
            return b.time.compareTo(a.time);
          });
          return appointments;
        })
        .handleError((error, stackTrace) {
          print('Error in getPatientAppointmentsStream: $error');
          print('Stack trace: $stackTrace');
          // If the error is about missing index, provide helpful message
          if (error.toString().contains('index')) {
            throw Exception('Firestore index required. Please check Firebase console for index creation link.');
          }
          // Re-throw to allow StreamBuilder to catch it
          throw error;
        });
  }

  Stream<List<Appointment>> getDoctorAppointmentsStream(String doctorId) {
    // Remove orderBy completely to avoid any index requirement
    // Sort entirely on client side
    print('Starting getDoctorAppointmentsStream for doctorId: $doctorId');
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          print('Received ${snapshot.docs.length} appointment documents');
          final appointments = <Appointment>[];
          for (var doc in snapshot.docs) {
            try {
              appointments.add(Appointment.fromFirestore(doc));
            } catch (e) {
              print('Error parsing appointment document ${doc.id}: $e');
              // Skip invalid documents instead of breaking the entire stream
            }
          }
          // Sort by date (descending) and time (descending) on client side
          appointments.sort((a, b) {
            final dateCompare = b.date.compareTo(a.date);
            if (dateCompare != 0) return dateCompare;
            return b.time.compareTo(a.time);
          });
          print('Returning ${appointments.length} sorted appointments');
          return appointments;
        })
        .handleError((error, stackTrace) {
          print('Error in getDoctorAppointmentsStream: $error');
          print('Stack trace: $stackTrace');
          // Re-throw to allow StreamBuilder to catch it
          throw error;
        });
  }

  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  }

  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    try {
      final query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: true)
          .orderBy('time', descending: true);
      
      final snapshot = await query.get();
      
      final appointments = <Appointment>[];
      for (var doc in snapshot.docs) {
        try {
          final appointment = Appointment.fromFirestore(doc);
          appointments.add(appointment);
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return appointments;
    } catch (e) {
      // Check for specific Firestore errors
      if (e.toString().contains('index')) {
        throw Exception('Firestore index required. Please check Firebase console for index creation link.');
      }
      
      rethrow;
    }
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    final doc = await _firestore.collection('appointments').doc(appointmentId).get();
    if (doc.exists) {
      return Appointment.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.appointmentId)
        .update(appointment.toFirestore());
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  // Users
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        try {
          final user = User.fromFirestore(doc);
          return user;
        } catch (e) {
          rethrow;
        }
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.userId).update(user.toFirestore());
  }

  // Doctors
  Stream<List<Doctor>> getDoctorsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Doctor(
                doctorId: doc.id,
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
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                updatedAt: (data['updatedAt'] as Timestamp).toDate(),
              );
            })
            .toList());
  }

  Future<List<Doctor>> getDoctors() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Doctor(
        doctorId: doc.id,
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
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<Doctor?> getDoctor(String doctorId) async {
    final doc = await _firestore.collection('users').doc(doctorId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return Doctor(
        doctorId: doc.id,
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
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    }
    return null;
  }
}

