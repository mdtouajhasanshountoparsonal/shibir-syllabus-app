/// A word the learner keeps getting wrong. Persisted in Hive as a Map.
class WeakWord {
  final String id;
  final String arabic;
  final String reference; // e.g. সূরা আল-ফাতিহা ১:৬
  final String kind; // letter | harakat | join | word | makhraj | tajweed
  final int wrongCount;
  final int correctStreak;
  final DateTime lastPracticed;
  final DateTime nextReview;
  final List<String> splitParts;

  const WeakWord({
    required this.id,
    required this.arabic,
    required this.reference,
    required this.kind,
    required this.wrongCount,
    required this.correctStreak,
    required this.lastPracticed,
    required this.nextReview,
    required this.splitParts,
  });

  bool get mastered => correctStreak >= 3;

  String get kindLabelBn {
    switch (kind) {
      case 'letter':
        return 'হরফ চেনা';
      case 'harakat':
        return 'হরকত';
      case 'join':
        return 'যুক্ত হরফ';
      case 'makhraj':
        return 'উচ্চারণ';
      case 'tajweed':
        return 'মাদ/তাজবিদ';
      case 'word':
      default:
        return 'শব্দ পড়া';
    }
  }

  WeakWord copyWith({
    int? wrongCount,
    int? correctStreak,
    DateTime? lastPracticed,
    DateTime? nextReview,
    List<String>? splitParts,
    String? kind,
  }) {
    return WeakWord(
      id: id,
      arabic: arabic,
      reference: reference,
      kind: kind ?? this.kind,
      wrongCount: wrongCount ?? this.wrongCount,
      correctStreak: correctStreak ?? this.correctStreak,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      nextReview: nextReview ?? this.nextReview,
      splitParts: splitParts ?? this.splitParts,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'arabic': arabic,
        'reference': reference,
        'kind': kind,
        'wrongCount': wrongCount,
        'correctStreak': correctStreak,
        'lastPracticed': lastPracticed.toIso8601String(),
        'nextReview': nextReview.toIso8601String(),
        'splitParts': splitParts,
      };

  factory WeakWord.fromMap(Map<dynamic, dynamic> m) => WeakWord(
        id: m['id']?.toString() ?? '',
        arabic: m['arabic']?.toString() ?? '',
        reference: m['reference']?.toString() ?? '',
        kind: m['kind']?.toString() ?? 'word',
        wrongCount: (m['wrongCount'] as num?)?.toInt() ?? 0,
        correctStreak: (m['correctStreak'] as num?)?.toInt() ?? 0,
        lastPracticed: DateTime.tryParse(m['lastPracticed']?.toString() ?? '') ??
            DateTime.now(),
        nextReview: DateTime.tryParse(m['nextReview']?.toString() ?? '') ??
            DateTime.now(),
        splitParts:
            ((m['splitParts'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}
