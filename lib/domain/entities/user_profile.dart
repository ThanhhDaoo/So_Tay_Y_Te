class UserProfile {
  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContact;
  final bool isPro;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContact,
    this.isPro = false,
  });
}
