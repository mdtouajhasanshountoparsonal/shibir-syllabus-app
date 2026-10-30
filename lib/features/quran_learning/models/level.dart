import 'lesson.dart';

/// A course level (Level 1–5) that groups related lessons.
class LearningLevel {
  final String id;
  final int order;
  final String titleBn;
  final String subtitleBn;
  final String badge;
  final int colorValue;
  final List<String> goals;
  final List<Lesson> lessons;

  const LearningLevel({
    required this.id,
    required this.order,
    required this.titleBn,
    required this.subtitleBn,
    required this.badge,
    required this.colorValue,
    required this.goals,
    required this.lessons,
  });

  factory LearningLevel.fromJson(Map<String, dynamic> j) => LearningLevel(
        id: j['id'] as String,
        order: (j['order'] as num?)?.toInt() ?? 0,
        titleBn: (j['titleBn'] ?? '') as String,
        subtitleBn: (j['subtitleBn'] ?? '') as String,
        badge: (j['badge'] ?? '') as String,
        colorValue: (j['color'] as num?)?.toInt() ?? 0,
        goals: ((j['goals'] as List<dynamic>?) ?? const []).cast<String>(),
        lessons: ((j['lessons'] as List<dynamic>?) ?? const [])
            .whereType<Map>()
            .map((e) => Lesson.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

/// A joined practice word with its Bangla meaning and optional surah reference.
class PracticeWord {
  final String id;
  final String arabic;
  final List<String> parts;
  final String nameBn;
  final String surah;

  const PracticeWord({
    required this.id,
    required this.arabic,
    required this.parts,
    required this.nameBn,
    required this.surah,
  });

  factory PracticeWord.fromJson(Map<String, dynamic> j) => PracticeWord(
        id: j['id'] as String,
        arabic: (j['arabic'] ?? '') as String,
        parts: ((j['parts'] as List<dynamic>?) ?? const []).cast<String>(),
        nameBn: (j['nameBn'] ?? '') as String,
        surah: (j['surah'] ?? '') as String,
      );
}

/// A reading ayah used in the reading practice screen.
class ReadingAyah {
  final String surah;
  final int number;
  final String arabic;
  final List<String> words;
  final String meaning;

  const ReadingAyah({
    required this.surah,
    required this.number,
    required this.arabic,
    required this.words,
    required this.meaning,
  });

  factory ReadingAyah.fromJson(Map<String, dynamic> j) => ReadingAyah(
        surah: (j['surah'] ?? '') as String,
        number: (j['number'] as num?)?.toInt() ?? 0,
        arabic: (j['arabic'] ?? '') as String,
        words: ((j['words'] as List<dynamic>?) ?? const []).cast<String>(),
        meaning: (j['meaning'] ?? '') as String,
      );

  String get reference => '$surah ${bnNumber(number)}';
}

/// Converts Western digits in [n] to Bengali digits (e.g. 12 -> ১২).
String bnNumber(int n) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n
      .toString()
      .split('')
      .map((c) => int.tryParse(c) != null ? bn[int.parse(c)] : c)
      .join();
}
