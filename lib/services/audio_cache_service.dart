import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Downloads recitation audio so it can be played fully offline.
///
/// Files are stored under `<documents>/audio/`. Names are derived from the
/// last path segment of the CDN URL (the global ayah number), which is stable
/// across recitations because we only ship one reciter per ayah.
class AudioCacheService {
  AudioCacheService._();
  static final AudioCacheService instance = AudioCacheService._();

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deterministic local filename for [url].
  Future<File> localFileFor(String url) async {
    final dir = await _dir();
    final segment = Uri.parse(url).pathSegments.lastWhere(
          (s) => s.isNotEmpty,
          orElse: () => '',
        );
    final digits = RegExp(r'\d+').firstMatch(segment)?.group(0);
    final name = digits != null
        ? 'ayah_$digits.mp3'
        : 'ayah_${url.hashCode.toRadixString(16)}.mp3';
    return File('${dir.path}/$name');
  }

  Future<bool> isCached(String url) async {
    return (await localFileFor(url)).exists();
  }

  /// Returns the local file path for [url], downloading it if needed.
  ///
  /// Throws when the download fails so callers can fall back to the network
  /// source and retry later.
  Future<String> ensure(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await localFileFor(url);
    if (await file.exists()) {
      onProgress?.call(1.0);
      return file.path;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = AppConstants.browserUserAgent;
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('ডাউনলোড ব্যর্থ: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      await sink.close();
      onProgress?.call(1.0);
      return file.path;
    } catch (_) {
      // Never keep a truncated file around.
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }
}
