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

  // Helper method to safely convert date values from Firestore
  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      throw ArgumentError('Date value cannot be null');
    }
    
    // If it's already a DateTime, return it
    if (value is DateTime) {
      return value;
    }
    
    // If it's a Timestamp, convert it
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // If it's a string (ISO format), parse it
    if (value is String) {
      // Handle date-only strings (YYYY-MM-DD) for appointment dates
      if (value.length == 10 && value.split('-').length == 3) {
        return DateTime.parse('${value}T00:00:00Z');
      }
      // Handle full ISO strings
      return DateTime.parse(value);
    }
    
    // If it's a number (milliseconds since epoch)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    throw ArgumentError('Unable to parse date value: $value (type: ${value.runtimeType})');
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      appointmentId: doc.id,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialization: data['doctorSpecialization'],
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      date: _parseDate(data['date']),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 30,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      doctorNotes: data['doctorNotes'],
      createdAt: _parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseDate(data['updatedAt'])
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


