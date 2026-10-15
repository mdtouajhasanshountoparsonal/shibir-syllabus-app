import 'enums.dart';

/// A single syllabus entry shown inside a stage.
class SyllabusItem {
  const SyllabusItem({
    required this.id,
    required this.title,
    required this.type,
    this.category = '',
    this.description = '',
    this.author = '',
    this.bookId = '',
    this.memoId = '',
    this.sourceUrl = '',
    this.estimatedMinutes = 0,
  });

  final String id;
  final String title;
  final ItemType type;
  final String category;
  final String description;
  final String author;

  /// Optional reference to a book in the digital library.
  final String bookId;

  /// Optional reference to a memorization item.
  final String memoId;
  final String sourceUrl;
  final int estimatedMinutes;

  factory SyllabusItem.fromJson(Map<String, dynamic> json) {
    return SyllabusItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'শিরোনামহীন',
      type: ItemType.fromName(json['type']?.toString()),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      memoId: json['memoId']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? json['url']?.toString() ?? '',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A subject inside a program (e.g. আল কুরআন, আল হাদিস).
class SyllabusStage {
  const SyllabusStage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.items,
    this.goals = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final List<SyllabusItem> items;

  /// Learning outcomes / objectives for this subject.
  final List<String> goals;

  factory SyllabusStage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final rawGoals = (json['goals'] as List<dynamic>? ?? const []);
    return SyllabusStage(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      goals: rawGoals.map((g) => g.toString()).toList(growable: false),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SyllabusItem.fromJson)
          .toList(growable: false),
    );
  }
}

/// A top-level program such as কর্মী / সাথী / সদস্য সিলেবাস.
class SyllabusProgram {
  const SyllabusProgram({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.heading = '',
    this.description = '',
    this.colorValue = 0,
    this.sourceUrl = '',
    this.stageIds = const [],
  });

  final String id;
  final String title;
  final String subtitle;

  /// Full heading shown on the program page, e.g.
  /// "কর্মী পাঠ মূল্যায়ন পরীক্ষার সিলেবাস ২০২৬".
  final String heading;
  final String description;
  final int colorValue;
  final String sourceUrl;
  final List<String> stageIds;

  factory SyllabusProgram.fromJson(Map<String, dynamic> json) {
    final ids = (json['stageIds'] as List<dynamic>? ?? const []);
    return SyllabusProgram(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      heading: json['heading']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0,
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      stageIds: ids.map((e) => e.toString()).toList(growable: false),
    );
  }
}
