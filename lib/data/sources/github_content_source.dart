import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/content_manifest.dart';
import 'content_parser.dart';

/// Raised when a remote content fetch fails. The caller should keep the
/// previously cached content (never wipe data on a failed sync).
class ContentSyncException implements Exception {
  ContentSyncException(this.message);
  final String message;
  @override
  String toString() => 'ContentSyncException: $message';
}

/// Raw (unparsed) content downloaded from the network, ready to be cached.
class RemoteContent {
  const RemoteContent({
    required this.manifest,
    required this.stages,
    required this.books,
    required this.memorization,
    required this.quizzes,
    this.schedule = '',
    this.programs = '',
  });

  final ContentManifest manifest;
  final String stages;
  final String books;
  final String memorization;
  final String quizzes;
  final String schedule;
  final String programs;
}

/// Fetches content published on GitHub (or any static host).
class GithubContentSource {
  GithubContentSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<ContentManifest> fetchManifest(String manifestUrl) async {
    final raw = await _getString(manifestUrl);
    return ContentParser.parseManifest(raw);
  }

  /// Downloads the raw JSON of every part referenced by [manifest].
  ///
  /// Any failure throws [ContentSyncException] so the app can safely fall back
  /// to its previous content.
  Future<RemoteContent> fetchRaw(
    ContentManifest manifest,
    String manifestUrl,
  ) async {
    final baseDir = _directoryOf(manifestUrl);
    final stagesUrl = _resolve(manifest.stagesUrl, baseDir);
    final booksUrl = _resolve(manifest.booksUrl, baseDir);
    final memorizationUrl = _resolve(manifest.memorizationUrl, baseDir);
    final quizzesUrl = _resolve(manifest.quizzesUrl, baseDir);
    final scheduleUrl = _resolve(manifest.scheduleUrl, baseDir);
    final programsUrl = _resolve(manifest.programsUrl, baseDir);

    final results = await Future.wait([
      if (stagesUrl != null) _getString(stagesUrl) else Future.value(''),
      if (booksUrl != null) _getString(booksUrl) else Future.value(''),
      if (memorizationUrl != null) _getString(memorizationUrl) else Future.value(''),
      if (quizzesUrl != null) _getString(quizzesUrl) else Future.value(''),
      if (scheduleUrl != null) _getString(scheduleUrl) else Future.value(''),
      if (programsUrl != null) _getString(programsUrl) else Future.value(''),
    ]);

    final remote = RemoteContent(
      manifest: manifest,
      stages: results[0],
      books: results[1],
      memorization: results[2],
      quizzes: results[3],
      schedule: results[4],
      programs: results[5],
    );

    // Validate that the payloads are parseable before we persist them.
    var parsedAny = false;
    if (remote.stages.isNotEmpty) {
      ContentParser.parseStages(remote.stages);
      parsedAny = true;
    }
    if (remote.books.isNotEmpty) {
      ContentParser.parseBooks(remote.books);
      parsedAny = true;
    }
    if (remote.memorization.isNotEmpty) {
      ContentParser.parseMemorization(remote.memorization);
      parsedAny = true;
    }
    if (remote.quizzes.isNotEmpty) {
      ContentParser.parseQuizzes(remote.quizzes);
      parsedAny = true;
    }
    if (remote.schedule.isNotEmpty) {
      ContentParser.parseSchedule(remote.schedule);
      parsedAny = true;
    }
    if (remote.programs.isNotEmpty) {
      ContentParser.parsePrograms(remote.programs);
      parsedAny = true;
    }
    if (!parsedAny) {
      throw ContentSyncException('Remote manifest produced empty content');
    }
    return remote;
  }

  Future<String> _getString(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(AppConstants.networkTimeout);
      if (response.statusCode != 200) {
        throw ContentSyncException('HTTP ${response.statusCode} for $url');
      }
      return response.body;
    } on ContentSyncException {
      rethrow;
    } catch (e) {
      throw ContentSyncException('Network error for $url: $e');
    }
  }

  static String _directoryOf(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final segments = uri.pathSegments;
    if (segments.isEmpty) return url;
    return uri
        .replace(pathSegments: segments.sublist(0, segments.length - 1))
        .toString();
  }

  static String? _resolve(String value, String baseDir) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    if (baseDir.isEmpty) return value;
    return '$baseDir/$value';
  }
}
