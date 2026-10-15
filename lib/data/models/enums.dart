/// Reading status of a syllabus item.
enum StudyStatus {
  notStarted,
  reading,
  completed,
  needsRevision;

  static StudyStatus fromName(String? value) {
    return StudyStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StudyStatus.notStarted,
    );
  }

  String get labelBn {
    switch (this) {
      case StudyStatus.notStarted:
        return 'শুরু হয়নি';
      case StudyStatus.reading:
        return 'পড়ছি';
      case StudyStatus.completed:
        return 'শেষ করেছি';
      case StudyStatus.needsRevision:
        return 'আবার পড়তে হবে';
    }
  }
}

/// Memorization status, deliberately separate from reading status.
enum MemoStatus {
  notStarted,
  learning,
  memorized;

  static MemoStatus fromName(String? value) {
    return MemoStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemoStatus.notStarted,
    );
  }

  String get labelBn {
    switch (this) {
      case MemoStatus.notStarted:
        return 'শুরু হয়নি';
      case MemoStatus.learning:
        return 'মুখস্থ চলছে';
      case MemoStatus.memorized:
        return 'মুখস্থ হয়েছে';
    }
  }
}

/// Content type of a syllabus item / library entry.
enum ItemType {
  book,
  quran,
  hadith,
  memorization,
  other,
  assessment;

  static ItemType fromName(String? value) {
    return ItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemType.other,
    );
  }

  String get labelBn {
    switch (this) {
      case ItemType.book:
        return 'পাঠ্যবই';
      case ItemType.quran:
        return 'কুরআন';
      case ItemType.hadith:
        return 'হাদিস';
      case ItemType.memorization:
        return 'মুখস্থ';
      case ItemType.other:
        return 'অন্যান্য';
      case ItemType.assessment:
        return 'মূল্যায়ন';
    }
  }
}

/// Available formats for a library book.
enum BookFormat {
  pdf,
  epub,
  link;

  static BookFormat fromName(String? value) {
    return BookFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookFormat.link,
    );
  }

  String get labelBn {
    switch (this) {
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.link:
        return 'বাহ্যিক লিংক';
    }
  }
}

/// Availability of a book for the user.
enum BookAccess {
  online,
  downloaded;

  static BookAccess fromName(String? value) {
    return BookAccess.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookAccess.online,
    );
  }

  String get labelBn => this == BookAccess.downloaded ? 'ডাউনলোড করা' : 'অনলাইন';
}
