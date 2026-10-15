import 'dart:convert';

import '../models/book.dart';
import '../models/content_manifest.dart';
import '../models/memorization.dart';
import '../models/quiz.dart';
import '../models/schedule.dart';
import '../models/syllabus.dart';

/// Thrown when remote/local JSON content is missing required structure.
class ContentFormatException implements Exception {
  ContentFormatException(this.message);
  final String message;
  @override
  String toString() => 'ContentFormatException: $message';
}

/// Parses the various content JSON documents into strongly typed models.
class ContentParser {
  ContentParser._();

  static const int supportedSchemaVersion = 1;

  static Map<String, dynamic> _decodeObject(String raw, String label) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw ContentFormatException('$label is not valid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ContentFormatException('$label must be a JSON object');
    }
    return decoded;
  }

  static ContentManifest parseManifest(String raw) {
    final obj = _decodeObject(raw, 'manifest');
    final manifest = ContentManifest.fromJson(obj);
    if (manifest.schemaVersion > supportedSchemaVersion) {
      throw ContentFormatException(
        'Unsupported schemaVersion ${manifest.schemaVersion}',
      );
    }
    return manifest;
  }

  static List<SyllabusStage> parseStages(String raw) {
    final obj = _decodeObject(raw, 'stages');
    return (obj['stages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SyllabusStage.fromJson)
        .where((s) => s.id.isNotEmpty)
        .map(
          (s) => SyllabusStage(
            id: s.id,
            title: s.title,
            subtitle: s.subtitle,
            description: s.description,
            goals: s.goals,
            items: s.items.where((i) => i.id.isNotEmpty).toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  static List<SyllabusProgram> parsePrograms(String raw) {
    final obj = _decodeObject(raw, 'programs');
    return (obj['programs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SyllabusProgram.fromJson)
        .where((p) => p.id.isNotEmpty)
        .toList(growable: false);
  }

  static List<Book> parseBooks(String raw) {
    final obj = _decodeObject(raw, 'books');
    return (obj['books'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Book.fromJson)
        .where((b) => b.id.isNotEmpty)
        .toList(growable: false);
  }

  static List<MemorizationItem> parseMemorization(String raw) {
    final obj = _decodeObject(raw, 'memorization');
    return (obj['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MemorizationItem.fromJson)
        .where((m) => m.id.isNotEmpty)
        .toList(growable: false);
  }

  static List<QuizQuestion> parseQuizzes(String raw) {
    final obj = _decodeObject(raw, 'quizzes');
    return (obj['quizzes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .where((q) => q.id.isNotEmpty && q.options.isNotEmpty)
        .toList(growable: false);
  }

  static ScheduleData parseSchedule(String raw) {
    final obj = _decodeObject(raw, 'schedule');
    final inner = obj['schedule'];
    if (inner is Map<String, dynamic>) return ScheduleData.fromJson(inner);
    return ScheduleData.fromJson(obj);
  }

  static ContentBundle buildBundle({
    required List<SyllabusStage> stages,
    required List<Book> books,
    required List<MemorizationItem> memorization,
    required List<QuizQuestion> quizzes,
    required String version,
    ScheduleData schedule = ScheduleData.empty,
    List<SyllabusProgram> programs = const [],
  }) {
    return ContentBundle(
      stages: stages,
      books: books,
      memorizationItems: memorization,
      quizzes: quizzes,
      schedule: schedule,
      programs: programs,
      version: version,
    );
  }
}
