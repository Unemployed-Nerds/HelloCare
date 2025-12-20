import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAvailability {
  final String? start;
  final String? end;
  final bool available;

  DoctorAvailability({
    this.start,
    this.end,
    required this.available,
  });

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    return DoctorAvailability(
      start: map['start'],
      end: map['end'],
      available: map['available'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
      'available': available,
    };
  }
}

class Doctor {
  final String doctorId;
  final String name;
  final String email;
  final String? phone;
  final String specialization;
  final String? bio;
  final int yearsOfExperience;
  final double rating;
  final int reviewCount;
  final String? profileImageUrl;
  final Map<String, DoctorAvailability> availability;
  final DateTime createdAt;
  final DateTime updatedAt;

  Doctor({
    required this.doctorId,
    required this.name,
    required this.email,
    this.phone,
    required this.specialization,
    this.bio,
    required this.yearsOfExperience,
    required this.rating,
    required this.reviewCount,
    this.profileImageUrl,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final availabilityMap = <String, DoctorAvailability>{};
    if (data['availability'] != null) {
      (data['availability'] as Map<String, dynamic>).forEach((key, value) {
        availabilityMap[key] = DoctorAvailability.fromMap(value);
      });
    }
    
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
      availability: availabilityMap,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final availabilityMap = <String, dynamic>{};
    availability.forEach((key, value) {
      availabilityMap[key] = value.toMap();
    });
    
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'bio': bio,
      'yearsOfExperience': yearsOfExperience,
      'rating': rating,
      'reviewCount': reviewCount,
      'profileImageUrl': profileImageUrl,
      'availability': availabilityMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Doctor copyWith({
    String? doctorId,
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? bio,
    int? yearsOfExperience,
    double? rating,
    int? reviewCount,
    String? profileImageUrl,
    Map<String, DoctorAvailability>? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


