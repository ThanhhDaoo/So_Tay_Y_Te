import 'auth_identity.dart';

class UserAccount {
  final String id;
  final String patientCode;
  final String fullName;
  final String primaryContact;
  final String passwordHash;
  final String salt;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? avatarUrl;
  final bool isGuest;
  final DateTime createdAt;
  final List<AuthIdentity> identities;

  const UserAccount({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.primaryContact,
    required this.passwordHash,
    required this.salt,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.avatarUrl,
    this.isGuest = false,
    required this.createdAt,
    this.identities = const [],
  });

  UserAccount copyWith({
    String? id,
    String? patientCode,
    String? fullName,
    String? primaryContact,
    String? passwordHash,
    String? salt,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? avatarUrl,
    bool? isGuest,
    DateTime? createdAt,
    List<AuthIdentity>? identities,
  }) {
    return UserAccount(
      id: id ?? this.id,
      patientCode: patientCode ?? this.patientCode,
      fullName: fullName ?? this.fullName,
      primaryContact: primaryContact ?? this.primaryContact,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      identities: identities ?? this.identities,
    );
  }
}

