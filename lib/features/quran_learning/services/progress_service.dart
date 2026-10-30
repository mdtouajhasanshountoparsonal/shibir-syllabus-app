import '../models/reading_progress.dart';
import '../models/weak_word.dart';
import '../../../services/local_store.dart';

/// Persists Quran Learning progress (learned letters, completed lessons,
/// current lesson and the spaced-revision weak-word list) in Hive.
class QuranProgressService {
  QuranProgressService._();

  static final QuranProgressService instance = QuranProgressService._();

  final LocalStore _store = LocalStore.instance;

  static const _kLearned = 'learnedLetters';
  static const _kCompleted = 'completedLessons';
  static const _kCurrentLesson = 'currentLessonId';
  static const _kCurrentTitle = 'currentLessonTitle';
  static const _kLastLetter = 'lastLetterId';
  static const _kWeak = 'weakWords';

  // Spaced-revision intervals (days) indexed by correct streak.
  static const List<int> _reviewDays = [0, 1, 3, 7, 14, 30];

  Set<String> _learned() =>
      (_store.quranGet(_kLearned) as List?)?.map((e) => e.toString()).toSet() ??
      <String>{};

  Set<String> _completed() =>
      (_store.quranGet(_kCompleted) as List?)
          ?.map((e) => e.toString())
          .toSet() ??
      <String>{};

  List<WeakWord> weakWords() {
    final raw = _store.quranGet(_kWeak);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => WeakWord.fromMap(e))
        .toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }

  List<WeakWord> dueWeakWords({DateTime? now}) {
    final at = now ?? DateTime.now();
    return weakWords()
        .where((w) => !w.mastered && !w.nextReview.isAfter(at))
        .toList();
  }

  ReadingProgress load({int totalLetters = 0}) {
    final currentId = _store.quranGet(_kCurrentLesson)?.toString() ?? '';
    return ReadingProgress(
      currentLessonId: currentId,
      currentLessonTitle: _store.quranGet(_kCurrentTitle)?.toString() ?? '',
      lastLetterId: _store.quranGet(_kLastLetter)?.toString() ?? '',
      learnedLetters: _learned(),
      completedLessons: _completed(),
      totalLetters: totalLetters,
      lastAccessed: DateTime.now(),
      weakWords: weakWords(),
    );
  }

  bool isLetterLearned(String id) => _learned().contains(id);

  bool isLessonCompleted(String id) => _completed().contains(id);

  Future<void> markLetterLearned(String id) async {
    final set = _learned()..add(id);
    await _store.quranPut(_kLearned, set.toList());
  }

  Future<void> markLessonCompleted(String id) async {
    final set = _completed()..add(id);
    await _store.quranPut(_kCompleted, set.toList());
  }

  Future<void> setCurrentLesson(String id, String title) async {
    await _store.quranPut(_kCurrentLesson, id);
    await _store.quranPut(_kCurrentTitle, title);
  }

  Future<void> setLastLetter(String id) => _store.quranPut(_kLastLetter, id);

  String? get lastLetterId => _store.quranGet(_kLastLetter)?.toString();

  String? get currentLessonId => _store.quranGet(_kCurrentLesson)?.toString();

  /// Records a mistake for [arabic]; keeps a single entry per word and resets
  /// its correct streak.
  Future<void> recordMistake({
    required String arabic,
    required String reference,
    required String kind,
    List<String> parts = const [],
  }) async {
    final list = weakWords();
    final idx = list.indexWhere((w) => w.arabic == arabic && w.kind == kind);
    final now = DateTime.now();
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(
        wrongCount: list[idx].wrongCount + 1,
        correctStreak: 0,
        lastPracticed: now,
        nextReview: now,
      );
    } else {
      list.add(WeakWord(
        id: '${kind}_${arabic.hashCode}',
        arabic: arabic,
        reference: reference,
        kind: kind,
        wrongCount: 1,
        correctStreak: 0,
        lastPracticed: now,
        nextReview: now,
        splitParts: parts,
      ));
    }
    await _saveWeak(list);
  }

  /// Records a correct recall for [weak]; grows the spaced-revision interval.
  Future<void> recordCorrect(WeakWord weak) async {
    final list = weakWords();
    final idx = list.indexWhere((w) => w.id == weak.id);
    if (idx < 0) return;
    final streak = list[idx].correctStreak + 1;
    final days = _reviewDays[streak.clamp(0, _reviewDays.length - 1)];
    list[idx] = list[idx].copyWith(
      correctStreak: streak,
      lastPracticed: DateTime.now(),
      nextReview: DateTime.now().add(Duration(days: days)),
    );
    await _saveWeak(list);
  }

  Future<void> removeWeakWord(String id) async {
    final list = weakWords()..removeWhere((w) => w.id == id);
    await _saveWeak(list);
  }

  Future<void> _saveWeak(List<WeakWord> list) =>
      _store.quranPut(_kWeak, [for (final w in list) w.toMap()]);

  Future<void> reset() async {
    await _store.quranDelete(_kLearned);
    await _store.quranPut(_kCompleted, <String>[]);
    await _store.quranPut(_kCurrentLesson, '');
    await _store.quranPut(_kCurrentTitle, '');
    await _store.quranPut(_kLastLetter, '');
    await _store.quranPut(_kWeak, const []);
  }
}
