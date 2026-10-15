import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants/app_constants.dart';
import '../models/content_manifest.dart';
import '../models/schedule.dart';
import 'content_parser.dart';

/// Loads content that ships with the app (assets) or was cached from a
/// previous successful sync (Hive). Never touches the network.
class LocalContentSource {
  const LocalContentSource();

  /// Reads the bundled offline content. Always available.
  Future<ContentBundle> loadBundled() async {
    final manifestRaw = await rootBundle.loadString(AppConstants.manifestAsset);
    final manifest = ContentParser.parseManifest(manifestRaw);

    final stages = ContentParser.parseStages(
      await rootBundle.loadString(AppConstants.stagesAsset),
    );
    final books = ContentParser.parseBooks(
      await rootBundle.loadString(AppConstants.booksAsset),
    );
    final memorization = ContentParser.parseMemorization(
      await rootBundle.loadString(AppConstants.memorizationAsset),
    );
    final quizzes = ContentParser.parseQuizzes(
      await rootBundle.loadString(AppConstants.quizzesAsset),
    );
    final schedule = ContentParser.parseSchedule(
      await rootBundle.loadString(AppConstants.scheduleAsset),
    );
    final programs = ContentParser.parsePrograms(
      await rootBundle.loadString(AppConstants.programsAsset),
    );

    return ContentParser.buildBundle(
      stages: stages,
      books: books,
      memorization: memorization,
      quizzes: quizzes,
      schedule: schedule,
      programs: programs,
      version: manifest.contentVersion,
    );
  }

  /// Rebuilds a [ContentBundle] from cached JSON strings (if any).
  ContentBundle? bundleFromCache({
    required String? stages,
    required String? books,
    required String? memorization,
    required String? quizzes,
    required String version,
    String? schedule,
    String? programs,
  }) {
    if (stages == null &&
        books == null &&
        memorization == null &&
        quizzes == null &&
        schedule == null &&
        programs == null) {
      return null;
    }
    try {
      return ContentParser.buildBundle(
        stages: stages == null ? const [] : ContentParser.parseStages(stages),
        books: books == null ? const [] : ContentParser.parseBooks(books),
        memorization: memorization == null
            ? const []
            : ContentParser.parseMemorization(memorization),
        quizzes: quizzes == null ? const [] : ContentParser.parseQuizzes(quizzes),
        schedule: schedule == null
            ? ScheduleData.empty
            : ContentParser.parseSchedule(schedule),
        programs: programs == null
            ? const []
            : ContentParser.parsePrograms(programs),
        version: version,
      );
    } catch (_) {
      return null;
    }
  }
}
