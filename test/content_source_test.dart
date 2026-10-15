import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shibir_syllabus_tracker/core/utils/manifest_url_validator.dart';
import 'package:shibir_syllabus_tracker/data/models/content_manifest.dart';
import 'package:shibir_syllabus_tracker/data/sources/github_content_source.dart';

void main() {
  group('ManifestUrlValidator', () {
    test('accepts a raw GitHub manifest url', () {
      expect(
        ManifestUrlValidator.validate(
          'https://raw.githubusercontent.com/u/r/main/manifest.json',
        ),
        isNull,
      );
    });

    test('rejects empty, schemeless and non-json urls', () {
      expect(ManifestUrlValidator.validate(''), isNotNull);
      expect(ManifestUrlValidator.validate('raw.github.com/x/manifest.json'),
          isNotNull);
      expect(ManifestUrlValidator.validate('https://example.com/readme.md'),
          isNotNull);
    });

    test('detects raw GitHub hosts', () {
      expect(
        ManifestUrlValidator.looksLikeRawGithub(
          'https://raw.githubusercontent.com/u/r/main/manifest.json',
        ),
        isTrue,
      );
    });
  });

  group('GithubContentSource', () {
    test('resolves relative content URLs against the manifest directory',
        () async {
      final requested = <String>[];
      const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        if (request.url.path.endsWith('manifest.json')) {
          return http.Response(
            '{"schemaVersion":1,"contentVersion":"1.0.0",'
            '"stagesUrl":"stages.json","booksUrl":"data/books.json"}',
            200,
            headers: jsonHeaders,
          );
        }
        if (request.url.path.endsWith('stages.json')) {
          return http.Response(
            '{"stages":[{"id":"worker","title":"কর্মী","items":[]}]}',
            200,
            headers: jsonHeaders,
          );
        }
        if (request.url.path.endsWith('books.json')) {
          return http.Response('{"books":[]}', 200, headers: jsonHeaders);
        }
        return http.Response('not found', 404);
      });

      final source = GithubContentSource(client: client);
      final manifestUrl =
          'https://example.com/content/manifest.json';
      final manifest = await source.fetchManifest(manifestUrl);
      final remote = await source.fetchRaw(manifest, manifestUrl);

      expect(manifest.contentVersion, '1.0.0');
      expect(remote.stages, contains('worker'));
      expect(
        requested,
        containsAll([
          'https://example.com/content/manifest.json',
          'https://example.com/content/stages.json',
          'https://example.com/content/data/books.json',
        ]),
      );
    });

    test('throws ContentSyncException on HTTP failure', () async {
      final client = MockClient((request) async => http.Response('nope', 500));
      final source = GithubContentSource(client: client);
      expect(
        () => source.fetchManifest('https://example.com/manifest.json'),
        throwsA(isA<ContentSyncException>()),
      );
    });
  });

  group('ContentManifest', () {
    test('parses urls and version', () {
      final manifest = ContentManifest.fromJson({
        'schemaVersion': 1,
        'contentVersion': '2.1.0',
        'stagesUrl': 'stages.json',
        'booksUrl': 'https://cdn.example.com/books.json',
      });
      expect(manifest.contentVersion, '2.1.0');
      expect(manifest.stagesUrl, 'stages.json');
      expect(manifest.booksUrl, 'https://cdn.example.com/books.json');
    });
  });
}
