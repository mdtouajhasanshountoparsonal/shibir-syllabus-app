/// Global app constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Shibir Syllabus';
  static const String appTagline = 'পড়াশোনা • মুখস্থ • অগ্রগতি';

  /// GitHub content repository configuration.
  ///
  /// Point [githubManifestUrl] at the raw `manifest.json` of your content
  /// repository, e.g.
  /// `https://raw.githubusercontent.com/USER/shibir-syllabus-data/main/manifest.json`.
  /// While it is empty the app runs fully from bundled offline assets.
  static const String githubManifestUrl =
      'https://raw.githubusercontent.com/mdtouajhasanshountoparsonal/shibir-syllabus-data/main/manifest.json';

  static const Duration networkTimeout = Duration(seconds: 10);

  /// Browser-like User-Agent. Some hosts (icsbook.info, shibircloud.com) reject
  /// non-browser agents such as Dart's default with HTTP 406.
  static const String browserUserAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static const String manifestAsset = 'assets/content/manifest.json';
  static const String stagesAsset = 'assets/content/stages.json';
  static const String booksAsset = 'assets/content/books.json';
  static const String memorizationAsset = 'assets/content/memorization.json';
  static const String quizzesAsset = 'assets/content/quizzes.json';
  static const String scheduleAsset = 'assets/content/schedule.json';
  static const String programsAsset = 'assets/content/programs.json';
}

/// Hive box names.
class HiveBoxes {
  HiveBoxes._();

  static const String progress = 'progress';
  static const String bookProgress = 'book_progress';
  static const String memorization = 'memorization_progress';
  static const String quranLearning = 'quran_learning_progress';
  static const String content = 'content_cache';
  static const String settings = 'settings';
}

/// Shared preference keys.
class PrefKeys {
  PrefKeys._();

  static const String contentVersion = 'content_version';
  static const String lastSyncAt = 'last_sync_at';
  static const String manifestUrl = 'manifest_url';
  static const String dailyGoalMinutes = 'daily_goal_minutes';
  static const String dailyStreak = 'daily_streak';
  static const String lastStudyDate = 'last_study_date';
  static const String todayReadMinutes = 'today_read_minutes';
  static const String recentSearches = 'recent_searches';
  static const String reminderEnabled = 'reminder_enabled';
  static const String reminderHour = 'reminder_hour';
  static const String reminderMinute = 'reminder_minute';
}
