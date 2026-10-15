class ReadingProgress {
  final String currentLessonId;
  final String lastLetterId;
  final int completedLetters;
  final int totalLetters;
  final DateTime lastAccessed;
  final double overallProgress;

  const ReadingProgress({
    required this.currentLessonId,
    required this.lastLetterId,
    required this.completedLetters,
    required this.totalLetters,
    required this.lastAccessed,
    required this.overallProgress,
  });

  ReadingProgress copyWith({
    String? currentLessonId,
    String? lastLetterId,
    int? completedLetters,
    int? totalLetters,
    DateTime? lastAccessed,
    double? overallProgress,
  }) {
    return ReadingProgress(
      currentLessonId: currentLessonId ?? this.currentLessonId,
      lastLetterId: lastLetterId ?? this.lastLetterId,
      completedLetters: completedLetters ?? this.completedLetters,
      totalLetters: totalLetters ?? this.totalLetters,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}
