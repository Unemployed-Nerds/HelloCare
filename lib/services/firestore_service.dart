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
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromFirestore(doc))
            .toList());
  }

  Future<List<Report>> getReports(String userId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
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
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  Stream<List<Appointment>> getDoctorAppointmentsStream(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
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
    final snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
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
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
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

