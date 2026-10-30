class Lesson {
  final String id;
  final String titleBn;
  final String subtitleBn;
  final List<String> letterIds;

  const Lesson({
    required this.id,
    required this.titleBn,
    required this.subtitleBn,
    required this.letterIds,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        titleBn: (j['titleBn'] ?? j['nameBn'] ?? '') as String,
        subtitleBn: (j['subtitleBn'] ?? j['descriptionBn'] ?? '') as String,
        letterIds:
            ((j['letterIds'] as List<dynamic>?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleBn': titleBn,
        'subtitleBn': subtitleBn,
        'letterIds': letterIds,
      };
}
