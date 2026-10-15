import 'enums.dart';

/// A chapter inside a book.
class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    this.description = '',
    this.pageStart = 0,
    this.pageEnd = 0,
  });

  final String id;
  final String title;
  final String description;
  final int pageStart;
  final int pageEnd;

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pageStart: (json['pageStart'] as num?)?.toInt() ?? 0,
      pageEnd: (json['pageEnd'] as num?)?.toInt() ?? 0,
    );
  }

  String get pageLabel {
    if (pageStart == 0 && pageEnd == 0) return '';
    if (pageEnd == 0 || pageEnd == pageStart) return 'পৃষ্ঠা $pageStart';
    return 'পৃষ্ঠা $pageStart–$pageEnd';
  }
}

/// A book in the digital library. Metadata lives in GitHub JSON; the actual
/// file (if any) lives in device storage after download.
class Book {
  const Book({
    required this.id,
    required this.title,
    this.author = '',
    this.publisher = '',
    this.language = 'বাংলা',
    this.edition = '',
    this.pages = 0,
    this.description = '',
    this.stage = '',
    this.category = '',
    this.format = BookFormat.link,
    this.coverUrl = '',
    this.fileUrl = '',
    this.externalUrl = '',
    this.source = '',
    this.chapters = const [],
  });

  final String id;
  final String title;
  final String author;
  final String publisher;
  final String language;
  final String edition;
  final int pages;
  final String description;
  final String stage;
  final String category;
  final BookFormat format;
  final String coverUrl;
  final String fileUrl;
  final String externalUrl;
  final String source;
  final List<Chapter> chapters;

  bool get hasLocalFile => format == BookFormat.pdf && fileUrl.isNotEmpty;
  bool get hasExternalLink => externalUrl.isNotEmpty || fileUrl.isNotEmpty;

  factory Book.fromJson(Map<String, dynamic> json) {
    final rawChapters = (json['chapters'] as List<dynamic>? ?? const []);
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'শিরোনামহীন',
      author: json['author']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      language: json['language']?.toString() ?? 'বাংলা',
      edition: json['edition']?.toString() ?? '',
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      format: BookFormat.fromName(json['format']?.toString()),
      coverUrl: json['coverUrl']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      externalUrl: json['externalUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      chapters: rawChapters
          .whereType<Map<String, dynamic>>()
          .map(Chapter.fromJson)
          .toList(growable: false),
    );
  }
}
