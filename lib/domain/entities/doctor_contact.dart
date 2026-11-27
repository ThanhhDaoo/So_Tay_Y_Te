class DoctorContact {
  final String id;
  final String? userId;
  final String memberId;
  final String fullName;
  final String specialty;
  final String hospitalName;
  final String phoneNumber;
  final String? avatarPath;
  final String? lastVisitDate;
  final String? lastVisitNote;
  final bool isPrimaryDoctor;
  final DateTime createdAt;

  const DoctorContact({
    required this.id,
    this.userId,
    this.memberId = 'primary',
    required this.fullName,
    required this.specialty,
    required this.hospitalName,
    required this.phoneNumber,
    this.avatarPath,
    this.lastVisitDate,
    this.lastVisitNote,
    this.isPrimaryDoctor = false,
    required this.createdAt,
  });

  DoctorContact copyWith({
    String? id,
    String? userId,
    String? memberId,
    String? fullName,
    String? specialty,
    String? hospitalName,
    String? phoneNumber,
    String? avatarPath,
    String? lastVisitDate,
    String? lastVisitNote,
    bool? isPrimaryDoctor,
    DateTime? createdAt,
  }) {
    return DoctorContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      fullName: fullName ?? this.fullName,
      specialty: specialty ?? this.specialty,
      hospitalName: hospitalName ?? this.hospitalName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      lastVisitNote: lastVisitNote ?? this.lastVisitNote,
      isPrimaryDoctor: isPrimaryDoctor ?? this.isPrimaryDoctor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? '',
      'member_id': memberId,
      'full_name': fullName,
      'specialty': specialty,
      'hospital_name': hospitalName,
      'phone_number': phoneNumber,
      'avatar_path': avatarPath,
      'last_visit_date': lastVisitDate,
      'last_visit_note': lastVisitNote,
      'is_primary_doctor': isPrimaryDoctor ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory DoctorContact.fromMap(Map<String, dynamic> map) {
    return DoctorContact(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      memberId: (map['member_id'] as String?) ?? 'primary',
      fullName: (map['full_name'] as String?) ?? 'Bác sĩ điều trị',
      specialty: (map['specialty'] as String?) ?? 'Nội tổng quát',
      hospitalName: (map['hospital_name'] as String?) ?? 'Bệnh viện / Phòng khám',
      phoneNumber: (map['phone_number'] as String?) ?? '',
      avatarPath: map['avatar_path'] as String?,
      lastVisitDate: map['last_visit_date'] as String?,
      lastVisitNote: map['last_visit_note'] as String?,
      isPrimaryDoctor: ((map['is_primary_doctor'] as num?)?.toInt() ?? 0) == 1,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
