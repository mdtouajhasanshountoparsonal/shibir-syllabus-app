import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Downloads and stores book files in the app's documents directory.
///
/// Only files explicitly permitted for offline storage should be downloaded.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// Downloads [url] and returns the saved file path.
  ///
  /// [onProgress] receives values between 0 and 1 when the server reports a
  /// content length.
  Future<String> download({
    required String bookId,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    final client = http.Client();
    try {
      var response = await _sendWithRetry(client, url);

      if (response.statusCode != 200) {
        throw Exception('ডাউনলোড ব্যর্থ: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final extension = _extensionOf(url);
      final file = File('${booksDir.path}/$bookId$extension');
      final sink = file.openWrite();
      var received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call((received / total).clamp(0.0, 1.0));
      }
      await sink.flush();
      await sink.close();
      onProgress?.call(1.0);
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Sends a GET request with browser-like headers, retrying transient
  /// rejections (the hosts occasionally answer 406/429/503 under load).
  Future<http.StreamedResponse> _sendWithRetry(
    http.Client client,
    String url,
  ) async {
    const retryStatuses = {406, 408, 429, 500, 502, 503, 504};
    http.StreamedResponse? last;
    for (var attempt = 0; attempt < 4; attempt++) {
      final request = http.Request('GET', Uri.parse(url));
      final origin = Uri.parse(url).origin;
      request.headers.addAll({
        'User-Agent': AppConstants.browserUserAgent,
        'Accept': 'application/pdf,application/octet-stream,*/*',
        'Accept-Language': 'bn,en;q=0.8',
        if (origin.isNotEmpty) 'Referer': '$origin/',
      });
      final response =
          await client.send(request).timeout(const Duration(seconds: 30));
      last = response;
      if (response.statusCode == 200 ||
          !retryStatuses.contains(response.statusCode)) {
        return response;
      }
      await response.stream.drain<void>();
      await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
    }
    return last!;
  }

  Future<bool> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static String _extensionOf(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.pdf';
    final ext = path.substring(dot);
    return ext.length <= 5 ? ext : '.pdf';
  }

  static bool isHttpUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');
}
