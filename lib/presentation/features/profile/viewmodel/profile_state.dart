class FamilyMemberChip {
  const FamilyMemberChip({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarAsset,
  });

  final String id;
  final String name;
  final String subtitle;
  final String avatarAsset;
}

class AllergyItem {
  const AllergyItem({
    required this.title,
    required this.severityLabel,
    required this.isHighRisk,
    required this.reaction,
    required this.iconAsset,
    this.includes,
  });

  final String title;
  final String severityLabel;
  final bool isHighRisk;
  final String? includes;
  final String reaction;
  final String iconAsset;
}

class ChronicConditionItem {
  const ChronicConditionItem({
    required this.title,
    required this.statusText,
    required this.iconAsset,
  });

  final String title;
  final String statusText;
  final String iconAsset;
}

class ImmunizationItem {
  const ImmunizationItem({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.isCompleted,
    required this.iconAsset,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final bool isCompleted;
  final String iconAsset;
}

class MemberMedicalProfile {
  const MemberMedicalProfile({
    required this.id,
    required this.fullName,
    required this.recordCode,
    required this.bhytStatus,
    required this.dob,
    required this.region,
    required this.heroImageAsset,
    required this.vitalsUpdatedAt,
    required this.bloodType,
    required this.bloodNote,
    required this.bmiValue,
    required this.bmiStatusLabel,
    required this.heightText,
    required this.weightText,
    required this.allergies,
    required this.chronicConditions,
    required this.immunizations,
  });

  final String id;
  final String fullName;
  final String recordCode;
  final String bhytStatus;
  final String dob;
  final String region;
  final String heroImageAsset;
  final String vitalsUpdatedAt;
  final String bloodType;
  final String bloodNote;
  final String bmiValue;
  final String bmiStatusLabel;
  final String heightText;
  final String weightText;
  final List<AllergyItem> allergies;
  final List<ChronicConditionItem> chronicConditions;
  final List<ImmunizationItem> immunizations;
}

class ProfileState {
  const ProfileState({
    required this.familyMembers,
    required this.selectedMemberId,
    required this.profilesById,
    this.isEditLocked = true,
  });

  final List<FamilyMemberChip> familyMembers;
  final String selectedMemberId;
  final Map<String, MemberMedicalProfile> profilesById;
  final bool isEditLocked;

  MemberMedicalProfile get activeProfile =>
      profilesById[selectedMemberId] ?? profilesById.values.first;

  ProfileState copyWith({
    String? selectedMemberId,
    bool? isEditLocked,
  }) {
    return ProfileState(
      familyMembers: familyMembers,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      profilesById: profilesById,
      isEditLocked: isEditLocked ?? this.isEditLocked,
    );
  }
}

