class Lesson {
  final String id;
  final String titleBn;
  final String level;
  final String descriptionBn;
  final List<String> letterIds;
  final String icon;
  final bool isUnlocked;
  final double progress;

  const Lesson({
    required this.id,
    required this.titleBn,
    required this.level,
    required this.descriptionBn,
    required this.letterIds,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        titleBn: j['nameBn'] ?? j['titleBn'] ?? '',
        level: j['level'] as String,
        descriptionBn: j['descriptionBn'] ?? '',
        letterIds: (j['letterIds'] as List<dynamic>).cast<String>(),
        icon: j['icon'] ?? 'school',
        isUnlocked: j['isUnlocked'] ?? false,
        progress: (j['progress'] ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleBn': titleBn,
        'level': level,
        'descriptionBn': descriptionBn,
        'letterIds': letterIds,
        'icon': icon,
        'isUnlocked': isUnlocked,
        'progress': progress,
      };
}
