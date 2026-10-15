import 'book.dart';
import 'memorization.dart';
import 'quiz.dart';
import 'schedule.dart';
import 'syllabus.dart';

/// Describes the published content bundle and where to fetch each part.
class ContentManifest {
  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    this.updatedAt = '',
    this.stagesUrl = '',
    this.booksUrl = '',
    this.memorizationUrl = '',
    this.quizzesUrl = '',
    this.scheduleUrl = '',
    this.programsUrl = '',
  });

  final int schemaVersion;
  final String contentVersion;
  final String updatedAt;
  final String stagesUrl;
  final String booksUrl;
  final String memorizationUrl;
  final String quizzesUrl;
  final String scheduleUrl;
  final String programsUrl;

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    return ContentManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      contentVersion: json['contentVersion']?.toString() ?? '0.0.0',
      updatedAt: json['updatedAt']?.toString() ?? '',
      stagesUrl: json['stagesUrl']?.toString() ?? '',
      booksUrl: json['booksUrl']?.toString() ?? '',
      memorizationUrl: json['memorizationUrl']?.toString() ?? '',
      quizzesUrl: json['quizzesUrl']?.toString() ?? '',
      scheduleUrl: json['scheduleUrl']?.toString() ?? '',
      programsUrl: json['programsUrl']?.toString() ?? '',
    );
  }
}

/// The full set of content shown in the app.
class ContentBundle {
  const ContentBundle({
    required this.stages,
    required this.books,
    required this.memorizationItems,
    required this.quizzes,
    this.schedule = ScheduleData.empty,
    this.programs = const [],
    this.version = '0.0.0',
  });

  const ContentBundle.empty()
      : stages = const [],
        books = const [],
        memorizationItems = const [],
        quizzes = const [],
        schedule = ScheduleData.empty,
        programs = const [],
        version = '0.0.0';

  final List<SyllabusStage> stages;
  final List<Book> books;
  final List<MemorizationItem> memorizationItems;
  final List<QuizQuestion> quizzes;
  final ScheduleData schedule;
  final List<SyllabusProgram> programs;
  final String version;

  bool get isEmpty =>
      stages.isEmpty &&
      books.isEmpty &&
      memorizationItems.isEmpty &&
      quizzes.isEmpty &&
      schedule.isEmpty &&
      programs.isEmpty;
}
