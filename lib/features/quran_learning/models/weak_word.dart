class WeakWord {
  final String id;
  final String arabic;
  final String reference; // e.g. সূরা আল-ফাতিহা ১:৬
  final int wrongCount;
  final DateTime lastPracticed;
  final DateTime nextReview;
  final List<String> splitParts;

  const WeakWord({
    required this.id,
    required this.arabic,
    required this.reference,
    required this.wrongCount,
    required this.lastPracticed,
    required this.nextReview,
    required this.splitParts,
  });

  WeakWord copyWith({
    int? wrongCount,
    DateTime? lastPracticed,
    DateTime? nextReview,
    List<String>? splitParts,
  }) {
    return WeakWord(
      id: id,
      arabic: arabic,
      reference: reference,
      wrongCount: wrongCount ?? this.wrongCount,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      nextReview: nextReview ?? this.nextReview,
      splitParts: splitParts ?? this.splitParts,
    );
  }
}
