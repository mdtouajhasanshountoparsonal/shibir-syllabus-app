import 'enums.dart';

/// Reading progress + notes for a syllabus item.
class ReadingProgress {
  const ReadingProgress({
    required this.itemId,
    this.status = StudyStatus.notStarted,
    this.updatedAt,
  });

  final String itemId;
  final StudyStatus status;
  final DateTime? updatedAt;

  ReadingProgress copyWith({StudyStatus? status, DateTime? updatedAt}) {
    return ReadingProgress(
      itemId: itemId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'status': status.name,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ReadingProgress.fromMap(Map<dynamic, dynamic> map) {
    return ReadingProgress(
      itemId: map['itemId']?.toString() ?? '',
      status: StudyStatus.fromName(map['status']?.toString()),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }
}

/// A personal note attached to a book (optionally tied to a page).
class BookNote {
  const BookNote({
    required this.id,
    required this.text,
    this.page = 0,
    this.createdAt,
  });

  final String id;
  final String text;
  final int page;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'page': page,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory BookNote.fromMap(Map<dynamic, dynamic> map) {
    return BookNote(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      page: (map['page'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}

/// Reading progress + bookmarks + notes for a book.
class BookProgress {
  const BookProgress({
    required this.bookId,
    this.lastPage = 0,
    this.downloaded = false,
    this.localPath = '',
    this.bookmarks = const [],
    this.notes = const [],
    this.updatedAt,
  });

  final String bookId;
  final int lastPage;
  final bool downloaded;
  final String localPath;
  final List<int> bookmarks;
  final List<BookNote> notes;
  final DateTime? updatedAt;

  BookProgress copyWith({
    int? lastPage,
    bool? downloaded,
    String? localPath,
    List<int>? bookmarks,
    List<BookNote>? notes,
    DateTime? updatedAt,
  }) {
    return BookProgress(
      bookId: bookId,
      lastPage: lastPage ?? this.lastPage,
      downloaded: downloaded ?? this.downloaded,
      localPath: localPath ?? this.localPath,
      bookmarks: bookmarks ?? this.bookmarks,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'lastPage': lastPage,
        'downloaded': downloaded,
        'localPath': localPath,
        'bookmarks': bookmarks,
        'notes': notes.map((n) => n.toMap()).toList(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory BookProgress.fromMap(Map<dynamic, dynamic> map) {
    final rawBookmarks = (map['bookmarks'] as List<dynamic>? ?? const []);
    final rawNotes = (map['notes'] as List<dynamic>? ?? const []);
    return BookProgress(
      bookId: map['bookId']?.toString() ?? '',
      lastPage: (map['lastPage'] as num?)?.toInt() ?? 0,
      downloaded: map['downloaded'] == true,
      localPath: map['localPath']?.toString() ?? '',
      bookmarks: rawBookmarks
          .map((e) => (e as num).toInt())
          .toList(growable: true),
      notes: rawNotes
          .whereType<Map<dynamic, dynamic>>()
          .map(BookNote.fromMap)
          .toList(growable: true),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }
}

/// Spaced-repetition memorization progress.
///
/// Review intervals grow through [kReviewIntervals] (days) each time the user
/// confirms a successful recall.
class MemorizationProgress {
  const MemorizationProgress({
    required this.itemId,
    this.status = MemoStatus.notStarted,
    this.intervalIndex = 0,
    this.nextReview,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  static const List<int> kReviewIntervals = [1, 3, 7, 30];

  final String itemId;
  final MemoStatus status;
  final int intervalIndex;
  final DateTime? nextReview;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  bool isDue(DateTime now) {
    if (status == MemoStatus.memorized) return false;
    if (nextReview == null) return true;
    return !nextReview!.isAfter(now);
  }

  MemorizationProgress schedule(DateTime from) {
    final idx = intervalIndex.clamp(0, kReviewIntervals.length - 1);
    final days = kReviewIntervals[idx];
    final nextIdx = (idx + 1).clamp(0, kReviewIntervals.length - 1);
    return copyWith(
      status: MemoStatus.memorized,
      intervalIndex: nextIdx,
      nextReview: DateTime(from.year, from.month, from.day)
          .add(Duration(days: days)),
      reviewCount: reviewCount + 1,
      lastReviewedAt: from,
    );
  }

  MemorizationProgress markLearning() {
    return copyWith(status: MemoStatus.learning);
  }

  MemorizationProgress copyWith({
    MemoStatus? status,
    int? intervalIndex,
    DateTime? nextReview,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return MemorizationProgress(
      itemId: itemId,
      status: status ?? this.status,
      intervalIndex: intervalIndex ?? this.intervalIndex,
      nextReview: nextReview ?? this.nextReview,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'status': status.name,
        'intervalIndex': intervalIndex,
        'nextReview': nextReview?.toIso8601String(),
        'reviewCount': reviewCount,
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  factory MemorizationProgress.fromMap(Map<dynamic, dynamic> map) {
    return MemorizationProgress(
      itemId: map['itemId']?.toString() ?? '',
      status: MemoStatus.fromName(map['status']?.toString()),
      intervalIndex: (map['intervalIndex'] as num?)?.toInt() ?? 0,
      nextReview: DateTime.tryParse(map['nextReview']?.toString() ?? ''),
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      lastReviewedAt:
          DateTime.tryParse(map['lastReviewedAt']?.toString() ?? ''),
    );
  }
}
