import 'package:flutter_test/flutter_test.dart';
import 'package:shibir_syllabus_tracker/data/sources/content_parser.dart';

void main() {
  group('ContentParser', () {
    test('parses stages and drops empty ids', () {
      const raw = '''
      {
        "stages": [
          {
            "id": "worker",
            "title": "কর্মী",
            "items": [
              {"id": "a", "title": "Item A", "type": "book"},
              {"id": "", "title": "Bad"}
            ]
          }
        ]
      }
      ''';
      final stages = ContentParser.parseStages(raw);
      expect(stages, hasLength(1));
      expect(stages.first.id, 'worker');
      expect(stages.first.items, hasLength(1));
      expect(stages.first.items.first.type.name, 'book');
    });

    test('rejects unsupported schema versions', () {
      const raw = '{"schemaVersion": 99, "contentVersion": "1.0.0"}';
      expect(
        () => ContentParser.parseManifest(raw),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('parses books with chapters', () {
      const raw = '''
      {
        "books": [
          {
            "id": "book_1",
            "title": "T",
            "format": "pdf",
            "chapters": [{"id": "c1", "title": "C", "pageStart": 1, "pageEnd": 5}]
          }
        ]
      }
      ''';
      final books = ContentParser.parseBooks(raw);
      expect(books, hasLength(1));
      expect(books.first.format.name, 'pdf');
      expect(books.first.chapters.first.pageLabel, 'পৃষ্ঠা 1–5');
    });

    test('throws on invalid json', () {
      expect(
        () => ContentParser.parseStages('not json'),
        throwsA(isA<ContentFormatException>()),
      );
    });
  });
}
