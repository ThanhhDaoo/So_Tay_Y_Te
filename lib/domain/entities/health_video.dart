import 'dart:convert';

class HealthVideo {
  final String id;
  final String title;
  final String category;
  final String durationLabel;
  final String thumbnailUrl;
  final String videoUrl;
  final String instructorName;
  final String description;
  final List<String> keySteps;
  final bool isSaved;
  final DateTime? lastWatchedAt;
  final DateTime createdAt;

  const HealthVideo({
    required this.id,
    required this.title,
    required this.category,
    required this.durationLabel,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.instructorName,
    required this.description,
    this.keySteps = const [],
    this.isSaved = false,
    this.lastWatchedAt,
    required this.createdAt,
  });

  HealthVideo copyWith({
    bool? isSaved,
    DateTime? lastWatchedAt,
  }) {
    return HealthVideo(
      id: id,
      title: title,
      category: category,
      durationLabel: durationLabel,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      instructorName: instructorName,
      description: description,
      keySteps: keySteps,
      isSaved: isSaved ?? this.isSaved,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'duration_label': durationLabel,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'instructor_name': instructorName,
      'description': description,
      'key_steps_json': jsonEncode(keySteps),
      'is_saved': isSaved ? 1 : 0,
      'last_watched_at': lastWatchedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthVideo.fromMap(Map<String, dynamic> map) {
    List<String> steps = const [];
    final rawSteps = map['key_steps_json'] as String?;
    if (rawSteps != null && rawSteps.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSteps);
        if (decoded is List) {
          steps = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return HealthVideo(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Dưỡng sinh',
      durationLabel: (map['duration_label'] as String?) ?? '10 phút',
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
      videoUrl: (map['video_url'] as String?) ?? '',
      instructorName: (map['instructor_name'] as String?) ?? 'Chuyên gia Phục hồi chức năng',
      description: (map['description'] as String?) ?? '',
      keySteps: steps,
      isSaved: ((map['is_saved'] as num?)?.toInt() ?? 0) == 1,
      lastWatchedAt: map['last_watched_at'] != null
          ? DateTime.tryParse(map['last_watched_at'] as String)
          : null,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
