import '../data/models/book.dart';
import '../data/models/content_manifest.dart';
import '../data/models/memorization.dart';
import '../data/models/syllabus.dart';

enum SearchKind { stageItem, book, memorization }

/// A single search result with enough context to navigate.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.stageId = '',
    this.item,
    this.book,
    this.memorization,
  });

  final SearchKind kind;
  final String title;
  final String subtitle;
  final String stageId;
  final SyllabusItem? item;
  final Book? book;
  final MemorizationItem? memorization;
}

/// In-memory search over the currently loaded content bundle.
class SearchService {
  SearchService._();

  static List<SearchHit> search(ContentBundle bundle, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = <SearchHit>[];

    for (final stage in bundle.stages) {
      for (final item in stage.items) {
        if (_matches(q, [item.title, item.description, item.author, item.category])) {
          hits.add(
            SearchHit(
              kind: SearchKind.stageItem,
              title: item.title,
              subtitle: '${stage.title} • ${item.type.labelBn}',
              stageId: stage.id,
              item: item,
            ),
          );
        }
      }
    }

    for (final book in bundle.books) {
      if (_matches(q, [book.title, book.author, book.publisher, book.category])) {
        hits.add(
          SearchHit(
            kind: SearchKind.book,
            title: book.title,
            subtitle: 'বই • ${book.author.isEmpty ? 'লেখক অজানা' : book.author}',
            book: book,
          ),
        );
      }
    }

    for (final memo in bundle.memorizationItems) {
      if (_matches(q, [memo.title, memo.meaning, memo.reference, memo.transliteration])) {
        hits.add(
          SearchHit(
            kind: SearchKind.memorization,
            title: memo.title,
            subtitle: 'মুখস্থ${memo.reference.isEmpty ? '' : ' • ${memo.reference}'}',
            memorization: memo,
          ),
        );
      }
    }

    return hits;
  }

  static bool _matches(String query, List<String> fields) {
    for (final field in fields) {
      if (field.toLowerCase().contains(query)) return true;
    }
    return false;
  }
}
