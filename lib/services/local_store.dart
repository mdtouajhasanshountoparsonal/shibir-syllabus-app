import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../data/models/progress.dart';

/// Thin wrapper around Hive boxes. Stores maps/strings so no code generation
/// is required and the schema stays easy to evolve.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  late Box _progress;
  late Box _bookProgress;
  late Box _memorization;
  late Box _quranLearning;
  late Box _content;
  late Box _settings;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _progress = await Hive.openBox(HiveBoxes.progress);
    _bookProgress = await Hive.openBox(HiveBoxes.bookProgress);
    _memorization = await Hive.openBox(HiveBoxes.memorization);
    _quranLearning = await Hive.openBox(HiveBoxes.quranLearning);
    _content = await Hive.openBox(HiveBoxes.content);
    _settings = await Hive.openBox(HiveBoxes.settings);
    _ready = true;
  }

  // --- Content cache -------------------------------------------------------

  Map<String, String?> readContentCache() {
    return {
      'manifest': _content.get('manifest') as String?,
      'stages': _content.get('stages') as String?,
      'books': _content.get('books') as String?,
      'memorization': _content.get('memorization') as String?,
      'quizzes': _content.get('quizzes') as String?,
      'schedule': _content.get('schedule') as String?,
      'programs': _content.get('programs') as String?,
      'version': _content.get('version') as String?,
    };
  }

  Future<void> writeContentCache({
    required String manifest,
    required String stages,
    required String books,
    required String memorization,
    required String quizzes,
    required String version,
    String schedule = '',
    String programs = '',
  }) async {
    await _content.putAll({
      'manifest': manifest,
      'stages': stages,
      'books': books,
      'memorization': memorization,
      'quizzes': quizzes,
      'schedule': schedule,
      'programs': programs,
      'version': version,
    });
  }

  Future<void> clearContentCache() => _content.clear();

  // --- Reading progress ----------------------------------------------------

  ReadingProgress? readProgress(String itemId) {
    final raw = _progress.get(itemId);
    if (raw is Map) return ReadingProgress.fromMap(raw);
    return null;
  }

  Future<void> writeProgress(ReadingProgress progress) =>
      _progress.put(progress.itemId, progress.toMap());

  Map<String, ReadingProgress> readAllProgress() {
    final result = <String, ReadingProgress>{};
    for (final key in _progress.keys) {
      final raw = _progress.get(key);
      if (raw is Map) {
        final p = ReadingProgress.fromMap(raw);
        result[p.itemId] = p;
      }
    }
    return result;
  }

  // --- Book progress -------------------------------------------------------

  BookProgress? readBookProgress(String bookId) {
    final raw = _bookProgress.get(bookId);
    if (raw is Map) return BookProgress.fromMap(raw);
    return null;
  }

  Future<void> writeBookProgress(BookProgress progress) =>
      _bookProgress.put(progress.bookId, progress.toMap());

  Map<String, BookProgress> readAllBookProgress() {
    final result = <String, BookProgress>{};
    for (final key in _bookProgress.keys) {
      final raw = _bookProgress.get(key);
      if (raw is Map) {
        final p = BookProgress.fromMap(raw);
        result[p.bookId] = p;
      }
    }
    return result;
  }

  // --- Memorization progress ----------------------------------------------

  MemorizationProgress? readMemoProgress(String itemId) {
    final raw = _memorization.get(itemId);
    if (raw is Map) return MemorizationProgress.fromMap(raw);
    return null;
  }

  Future<void> writeMemoProgress(MemorizationProgress progress) =>
      _memorization.put(progress.itemId, progress.toMap());

  Map<String, MemorizationProgress> readAllMemoProgress() {
    final result = <String, MemorizationProgress>{};
    for (final key in _memorization.keys) {
      final raw = _memorization.get(key);
      if (raw is Map) {
        final p = MemorizationProgress.fromMap(raw);
        result[p.itemId] = p;
      }
    }
    return result;
  }

  // --- Settings ------------------------------------------------------------

  T? getSetting<T>(String key, {T? fallback}) {
    final value = _settings.get(key);
    if (value is T) return value;
    return fallback;
  }

  Future<void> setSetting(String key, Object? value) =>
      _settings.put(key, value);

  /// Wipes only user content cache (used by "reset content" in settings).
  Future<void> wipeContentCache() => _content.clear();

  // --- Quran Learning progress --------------------------------------------

  dynamic quranGet(String key) => _quranLearning.get(key);

  Future<void> quranPut(String key, Object? value) =>
      _quranLearning.put(key, value);

  Future<void> quranDelete(String key) => _quranLearning.delete(key);

  Map<String, dynamic> readAllQuranLearning() {
    final result = <String, dynamic>{};
    for (final key in _quranLearning.keys) {
      result[key.toString()] = _quranLearning.get(key);
    }
    return result;
  }

  // --- Recent searches -----------------------------------------------------

  List<String> getRecentSearches() {
    final raw = _settings.get(PrefKeys.recentSearches);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  Future<List<String>> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getRecentSearches();
    final list = getRecentSearches().where((e) => e != trimmed).toList();
    list.insert(0, trimmed);
    final capped = list.take(8).toList();
    await _settings.put(PrefKeys.recentSearches, capped);
    return capped;
  }

  Future<void> clearRecentSearches() =>
      _settings.delete(PrefKeys.recentSearches);
}
