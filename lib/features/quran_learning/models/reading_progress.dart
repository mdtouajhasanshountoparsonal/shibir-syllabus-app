import 'weak_word.dart';

/// Aggregated, offline learning progress for the Quran Learning section.
class ReadingProgress {
  final String currentLessonId;
  final String currentLessonTitle;
  final String lastLetterId;
  final Set<String> learnedLetters;
  final Set<String> completedLessons;
  final int totalLetters;
  final DateTime? lastAccessed;
  final List<WeakWord> weakWords;

  const ReadingProgress({
    required this.currentLessonId,
    required this.currentLessonTitle,
    required this.lastLetterId,
    required this.learnedLetters,
    required this.completedLessons,
    required this.totalLetters,
    required this.lastAccessed,
    required this.weakWords,
  });

  static const empty = ReadingProgress(
    currentLessonId: '',
    currentLessonTitle: '',
    lastLetterId: '',
    learnedLetters: {},
    completedLessons: {},
    totalLetters: 0,
    lastAccessed: null,
    weakWords: [],
  );

  int get learnedCount => learnedLetters.length;

  double get overallProgress {
    if (totalLetters == 0) return 0;
    return (learnedLetters.length / totalLetters).clamp(0.0, 1.0);
  }

  ReadingProgress copyWith({
    String? currentLessonId,
    String? currentLessonTitle,
    String? lastLetterId,
    Set<String>? learnedLetters,
    Set<String>? completedLessons,
    int? totalLetters,
    DateTime? lastAccessed,
    List<WeakWord>? weakWords,
  }) {
    return ReadingProgress(
      currentLessonId: currentLessonId ?? this.currentLessonId,
      currentLessonTitle: currentLessonTitle ?? this.currentLessonTitle,
      lastLetterId: lastLetterId ?? this.lastLetterId,
      learnedLetters: learnedLetters ?? this.learnedLetters,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLetters: totalLetters ?? this.totalLetters,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      weakWords: weakWords ?? this.weakWords,
    );
  }
}
