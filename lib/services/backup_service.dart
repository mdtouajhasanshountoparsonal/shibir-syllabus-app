import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/progress.dart';
import 'local_store.dart';

/// Raised when an imported backup file is not a valid backup.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Counts of what was restored, used to show a summary to the user.
class BackupSummary {
  const BackupSummary({
    required this.reading,
    required this.books,
    required this.memorization,
    required this.recentSearches,
  });

  final int reading;
  final int books;
  final int memorization;
  final int recentSearches;
}

/// Exports and restores user data (progress, notes, bookmarks, memorization,
/// daily counters and recent searches) as a portable JSON file.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _appTag = 'shibir_syllabus_tracker';
  static const int _schema = 1;
  static const String _fileName = 'shibir_backup.json';

  final LocalStore _store = LocalStore.instance;

  Map<String, dynamic> _build() {
    return {
      'app': _appTag,
      'schema': _schema,
      'exportedAt': DateTime.now().toIso8601String(),
      'reading': {
        for (final entry in _store.readAllProgress().entries)
          entry.key: entry.value.toMap(),
      },
      'books': {
        for (final entry in _store.readAllBookProgress().entries)
          entry.key: entry.value.toMap(),
      },
      'memorization': {
        for (final entry in _store.readAllMemoProgress().entries)
          entry.key: entry.value.toMap(),
      },
      'settings': {
        PrefKeys.dailyGoalMinutes:
            _store.getSetting<int>(PrefKeys.dailyGoalMinutes),
        PrefKeys.dailyStreak: _store.getSetting<int>(PrefKeys.dailyStreak),
        PrefKeys.lastStudyDate: _store.getSetting<String>(PrefKeys.lastStudyDate),
        PrefKeys.todayReadMinutes:
            _store.getSetting<int>(PrefKeys.todayReadMinutes),
      },
      'recentSearches': _store.getRecentSearches(),
    };
  }

  /// Writes a backup file to the app's documents directory and returns it.
  Future<File> writeBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_build()),
    );
    return file;
  }

  /// Returns the JSON of the most recent local backup file, if it exists.
  Future<String?> readLocalBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (await file.exists()) return file.readAsString();
    return null;
  }

  /// Copies the backup JSON to the system clipboard.
  Future<void> copyToClipboard() async {
    final file = await writeBackupFile();
    final content = await file.readAsString();
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Restores from the JSON currently on the clipboard.
  /// Returns null when the clipboard is empty.
  Future<BackupSummary?> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return null;
    return restore(text);
  }

  /// Shares the backup file through the platform share sheet.
  Future<void> shareBackup() async {
    final file = await writeBackupFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'শিবির সিলেবাস ব্যাকআপ',
    );
  }

  /// Restores data from a raw JSON string.
  Future<BackupSummary> restore(String rawJson) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (_) {
      throw const BackupException('ফাইলটি বৈধ JSON নয়।');
    }
    if (decoded is! Map || decoded['app'] != _appTag) {
      throw const BackupException('ফাইলটি এই অ্যাপের ব্যাকআপ নয়।');
    }
    final schema = (decoded['schema'] as num?)?.toInt() ?? 0;
    if (schema > _schema) {
      throw BackupException(
        'ব্যাকআপ সংস্করণ ($schema) এই অ্যাপের চেয়ে নতুন। অ্যাপ আপডেট করো।',
      );
    }

    var reading = 0;
    var books = 0;
    var memorization = 0;

    final readingMap = decoded['reading'];
    if (readingMap is Map) {
      for (final entry in readingMap.entries) {
        final value = entry.value;
        if (value is Map) {
          final progress = ReadingProgress.fromMap(value);
          if (progress.itemId.isEmpty) continue;
          await _store.writeProgress(progress);
          reading++;
        }
      }
    }

    final bookMap = decoded['books'];
    if (bookMap is Map) {
      for (final entry in bookMap.entries) {
        final value = entry.value;
        if (value is Map) {
          final progress = BookProgress.fromMap(value);
          if (progress.bookId.isEmpty) continue;
          await _store.writeBookProgress(progress);
          books++;
        }
      }
    }

    final memoMap = decoded['memorization'];
    if (memoMap is Map) {
      for (final entry in memoMap.entries) {
        final value = entry.value;
        if (value is Map) {
          final progress = MemorizationProgress.fromMap(value);
          if (progress.itemId.isEmpty) continue;
          await _store.writeMemoProgress(progress);
          memorization++;
        }
      }
    }

    final settings = decoded['settings'];
    if (settings is Map) {
      for (final key in [
        PrefKeys.dailyGoalMinutes,
        PrefKeys.dailyStreak,
        PrefKeys.lastStudyDate,
        PrefKeys.todayReadMinutes,
      ]) {
        if (settings.containsKey(key) && settings[key] != null) {
          await _store.setSetting(key, settings[key]);
        }
      }
    }

    var recent = 0;
    final recentList = decoded['recentSearches'];
    if (recentList is List) {
      final queries = recentList.map((e) => e.toString()).toList();
      await _store.setSetting(PrefKeys.recentSearches, queries);
      recent = queries.length;
    }

    return BackupSummary(
      reading: reading,
      books: books,
      memorization: memorization,
      recentSearches: recent,
    );
  }
}
