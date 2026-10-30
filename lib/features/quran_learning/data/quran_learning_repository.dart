import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/letter.dart';
import '../models/lesson.dart';
import '../models/level.dart';

/// Loads Quran Learning content from the bundled JSON asset.
///
/// Content is offline-first: the JSON ships with the app and is parsed once and
/// cached in memory. This keeps the learning flow working without a network.
class QuranLearningRepository {
  QuranLearningRepository._();
  static final QuranLearningRepository instance = QuranLearningRepository._();

  static const String assetPath = 'assets/content/quran_learning.json';

  Map<String, dynamic>? _raw;
  List<ArabicLetter>? _letters;
  List<LearningLevel>? _levels;
  List<PracticeWord>? _words;
  List<ReadingAyah>? _ayahs;

  Future<Map<String, dynamic>> _load() async {
    if (_raw != null) return _raw!;
    final data = await rootBundle.loadString(assetPath);
    _raw = jsonDecode(data) as Map<String, dynamic>;
    return _raw!;
  }

  Future<List<ArabicLetter>> getLetters() async {
    if (_letters != null) return _letters!;
    final map = await _load();
    final list = ((map['letters'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((e) => ArabicLetter.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    _letters = list;
    return _letters!;
  }

  Future<List<LearningLevel>> getLevels() async {
    if (_levels != null) return _levels!;
    final map = await _load();
    _levels = ((map['levels'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((e) => LearningLevel.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _levels!;
  }

  Future<List<Lesson>> getLessons() async {
    final levels = await getLevels();
    return [for (final l in levels) ...l.lessons];
  }

  Future<List<PracticeWord>> getWords() async {
    if (_words != null) return _words!;
    final map = await _load();
    _words = ((map['words'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((e) => PracticeWord.fromJson(e.cast<String, dynamic>()))
        .toList();
    return _words!;
  }

  Future<List<ReadingAyah>> getAyahs() async {
    if (_ayahs != null) return _ayahs!;
    final map = await _load();
    _ayahs = ((map['ayahs'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((e) => ReadingAyah.fromJson(e.cast<String, dynamic>()))
        .toList();
    return _ayahs!;
  }
}
