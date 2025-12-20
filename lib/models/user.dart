import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String email;
  final String name;
  final String role; // 'patient' or 'doctor'
  final String? phone;
  final DateTime? dateOfBirth;
  
  // Medical information (for patients)
  final String? medicalHistory;
  final List<String>? allergies;
  final String? emergencyContact;
  final String? emergencyContactPhone;
  
  // Doctor-specific fields
  final String? specialization;
  final int? yearsOfExperience;
  final String? bio;
  final double? rating;
  final int? reviewCount;
  final String? profileImageUrl;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.medicalHistory,
    this.allergies,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.specialization,
    this.yearsOfExperience,
    this.bio,
    this.rating,
    this.reviewCount,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userId: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      medicalHistory: data['medicalHistory'],
      allergies: data['allergies'] != null
          ? List<String>.from(data['allergies'])
          : null,
      emergencyContact: data['emergencyContact'],
      emergencyContactPhone: data['emergencyContactPhone'],
      specialization: data['specialization'],
      yearsOfExperience: data['yearsOfExperience'],
      bio: data['bio'],
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  User copyWith({
    String? userId,
    String? email,
    String? name,
    String? role,
    String? phone,
    DateTime? dateOfBirth,
    String? medicalHistory,
    List<String>? allergies,
    String? emergencyContact,
    String? emergencyContactPhone,
    String? specialization,
    int? yearsOfExperience,
    String? bio,
    double? rating,
    int? reviewCount,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


