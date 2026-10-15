import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/letter.dart';
import '../models/lesson.dart';

class QuranLearningRepository {
  QuranLearningRepository._();
  static final QuranLearningRepository instance = QuranLearningRepository._();

  List<ArabicLetter>? _letters;
  List<Lesson>? _lessons;

  Future<List<ArabicLetter>> getLetters() async {
    if (_letters != null) return _letters!;
    final data = await rootBundle.loadString('assets/content/quran_learning.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final list = (map['letters'] as List<dynamic>).cast<Map<String, dynamic>>();
    _letters = list.map(ArabicLetter.fromJson).toList();
    return _letters!;
  }

  Future<List<Lesson>> getLessons() async {
    if (_lessons != null) return _lessons!;
    final data = await rootBundle.loadString('assets/content/quran_learning.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final list = (map['lessons'] as List<dynamic>).cast<Map<String, dynamic>>();
    _lessons = list.map(Lesson.fromJson).toList();
    return _lessons!;
  }
}
