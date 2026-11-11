// lib/models/user_model.dart

import '../utils/constants.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? clinicOrLabName;
  final String? address;
  final List<String> availabilityTimes;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.clinicOrLabName,
    this.address,
    this.availabilityTimes = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role:
          json['role'] == 'technician' ? UserRole.technician : UserRole.dentist,
      clinicOrLabName: json['clinicOrLabName'],
      address: json['address'],
      availabilityTimes:
          List<String>.from(json['availabilityTimes'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role == UserRole.technician ? 'technician' : 'dentist',
      'clinicOrLabName': clinicOrLabName,
      'address': address,
      'availabilityTimes': availabilityTimes,
    };
  }

  String get displayName {
    if (role == UserRole.dentist) return 'Dr. $fullName';
    return 'Mr. $fullName';
  }
}
