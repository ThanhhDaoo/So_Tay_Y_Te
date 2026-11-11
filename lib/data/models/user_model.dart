import '../../domain/entities/user_profile.dart';

class UserModel extends UserProfile {
  const UserModel({
    required super.id,
    required super.fullName,
    super.dateOfBirth,
    super.bloodType,
    super.allergies,
    super.chronicConditions,
    super.emergencyContact,
    super.isPro,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      bloodType: json['blood_type'] as String?,
      allergies: (json['allergies'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      chronicConditions: (json['chronic_conditions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      emergencyContact: json['emergency_contact'] as String?,
      isPro: json['is_pro'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'blood_type': bloodType,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'emergency_contact': emergencyContact,
      'is_pro': isPro,
    };
  }

  UserProfile toEntity() => this;
}
