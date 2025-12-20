import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String? doctorSpecialization;
  final String patientId;
  final String patientName;
  final DateTime date;
  final String time; // HH:mm format
  final int duration; // in minutes
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final String? doctorNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialization,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.notes,
    this.doctorNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      appointmentId: doc.id,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialization: data['doctorSpecialization'],
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 30,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      doctorNotes: data['doctorNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'patientId': patientId,
      'patientName': patientName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'duration': duration,
      'status': status,
      'notes': notes,
      'doctorNotes': doctorNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Appointment copyWith({
    String? appointmentId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialization,
    String? patientId,
    String? patientName,
    DateTime? date,
    String? time,
    int? duration,
    String? status,
    String? notes,
    String? doctorNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


