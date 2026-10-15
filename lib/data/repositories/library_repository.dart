import '../../services/local_store.dart';
import '../models/progress.dart';

/// Manages reading position, bookmarks, notes and download state per book.
class LibraryRepository {
  LibraryRepository._();

  static final LibraryRepository instance = LibraryRepository._();

  final LocalStore _store = LocalStore.instance;

  BookProgress get(String bookId) =>
      _store.readBookProgress(bookId) ?? BookProgress(bookId: bookId);

  Map<String, BookProgress> all() => _store.readAllBookProgress();

  bool isBookmarked(String bookId, int page) =>
      get(bookId).bookmarks.contains(page);

  Future<void> setLastPage(String bookId, int page) async {
    final current = get(bookId);
    await _store.writeBookProgress(
      current.copyWith(lastPage: page, updatedAt: DateTime.now()),
    );
  }

  Future<void> toggleBookmark(String bookId, int page) async {
    final current = get(bookId);
    final bookmarks = List<int>.from(current.bookmarks);
    if (bookmarks.contains(page)) {
      bookmarks.remove(page);
    } else {
      bookmarks.add(page);
      bookmarks.sort();
    }
    await _store.writeBookProgress(
      current.copyWith(bookmarks: bookmarks, updatedAt: DateTime.now()),
    );
  }

  Future<void> addNote(String bookId, String text, {int page = 0}) async {
    final current = get(bookId);
    final note = BookNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      page: page,
      createdAt: DateTime.now(),
    );
    final notes = List<BookNote>.from(current.notes)..add(note);
    await _store.writeBookProgress(
      current.copyWith(notes: notes, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    final current = get(bookId);
    final notes =
        current.notes.where((n) => n.id != noteId).toList(growable: false);
    await _store.writeBookProgress(
      current.copyWith(notes: notes, updatedAt: DateTime.now()),
    );
  }

  Future<void> setDownloaded(
    String bookId, {
    required bool downloaded,
    String localPath = '',
  }) async {
    final current = get(bookId);
    await _store.writeBookProgress(
      current.copyWith(
        downloaded: downloaded,
        localPath: localPath,
        updatedAt: DateTime.now(),
      ),
    );
  }

  List<BookProgress> downloadedBooks() =>
      all().values.where((p) => p.downloaded).toList(growable: false);

  int get totalNotes => all().values.fold(0, (sum, p) => sum + p.notes.length);
}
