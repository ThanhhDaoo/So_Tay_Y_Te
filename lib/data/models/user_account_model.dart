import '../../domain/entities/user_account.dart';
import 'auth_identity_model.dart';

class UserAccountModel extends UserAccount {
  const UserAccountModel({
    required super.id,
    required super.patientCode,
    required super.fullName,
    required super.primaryContact,
    required super.passwordHash,
    required super.salt,
    super.dateOfBirth,
    super.gender,
    super.bloodType,
    super.avatarUrl,
    super.isGuest = false,
    required super.createdAt,
    super.identities = const [],
  });

  factory UserAccountModel.fromMap(
    Map<String, dynamic> map, [
    List<AuthIdentityModel> identities = const [],
  ]) {
    return UserAccountModel(
      id: map['id'] as String,
      patientCode: map['patient_code'] as String,
      fullName: map['full_name'] as String,
      primaryContact: map['primary_contact'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      dateOfBirth: map['date_of_birth'] as String?,
      gender: map['gender'] as String?,
      bloodType: map['blood_type'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isGuest: (map['is_guest'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      identities: identities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_code': patientCode,
      'full_name': fullName,
      'primary_contact': primaryContact,
      'password_hash': passwordHash,
      'salt': salt,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_type': bloodType,
      'avatar_url': avatarUrl,
      'is_guest': isGuest ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserAccountModel.fromEntity(UserAccount entity) {
    return UserAccountModel(
      id: entity.id,
      patientCode: entity.patientCode,
      fullName: entity.fullName,
      primaryContact: entity.primaryContact,
      passwordHash: entity.passwordHash,
      salt: entity.salt,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      bloodType: entity.bloodType,
      avatarUrl: entity.avatarUrl,
      isGuest: entity.isGuest,
      createdAt: entity.createdAt,
      identities: entity.identities,
    );
  }
}

