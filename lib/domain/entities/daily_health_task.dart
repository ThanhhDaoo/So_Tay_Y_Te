enum HealthTaskCategory {
  bloodPressure,
  medication,
  exercise,
  hydration,
  custom,
}

class DailyHealthTask {
  final String id;
  final String? userId;
  final String memberId;
  final String dateKey;
  final String title;
  final String? subtitle;
  final HealthTaskCategory category;
  final String? timeLabel;
  final String? linkedSlotId; // 'morning' | 'noon' | 'afternoon' | 'night'
  final bool isCompleted;
  final DateTime? completedAt;

  const DailyHealthTask({
    required this.id,
    this.userId,
    this.memberId = 'primary',
    required this.dateKey,
    required this.title,
    this.subtitle,
    this.category = HealthTaskCategory.custom,
    this.timeLabel,
    this.linkedSlotId,
    this.isCompleted = false,
    this.completedAt,
  });

  String get categoryLabelVi {
    switch (category) {
      case HealthTaskCategory.bloodPressure:
        return 'Đo huyết áp';
      case HealthTaskCategory.medication:
        return 'Uống thuốc';
      case HealthTaskCategory.exercise:
        return 'Vận động';
      case HealthTaskCategory.hydration:
        return 'Dinh dưỡng';
      case HealthTaskCategory.custom:
        return 'Việc trong ngày';
    }
  }

  DailyHealthTask copyWith({
    String? id,
    String? userId,
    String? memberId,
    String? dateKey,
    String? title,
    String? subtitle,
    HealthTaskCategory? category,
    String? timeLabel,
    String? linkedSlotId,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyHealthTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      timeLabel: timeLabel ?? this.timeLabel,
      linkedSlotId: linkedSlotId ?? this.linkedSlotId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? '',
      'member_id': memberId,
      'date_key': dateKey,
      'title': title,
      'subtitle': subtitle,
      'category': category.name,
      'time_label': timeLabel,
      'linked_slot_id': linkedSlotId,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory DailyHealthTask.fromMap(Map<String, dynamic> map) {
    final rawCat = map['category'] as String?;
    final cat = HealthTaskCategory.values.firstWhere(
      (e) => e.name == rawCat,
      orElse: () => HealthTaskCategory.custom,
    );
    return DailyHealthTask(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      memberId: (map['member_id'] as String?) ?? 'primary',
      dateKey: (map['date_key'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      subtitle: map['subtitle'] as String?,
      category: cat,
      timeLabel: map['time_label'] as String?,
      linkedSlotId: map['linked_slot_id'] as String?,
      isCompleted: ((map['is_completed'] as num?)?.toInt() ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );
  }
}
