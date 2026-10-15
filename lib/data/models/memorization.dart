/// A single word of an ayah, with its Bangla gloss and timing (ms) inside the
/// ayah's own recitation. Timings drive the word-by-word highlight.
class MemoWord {
  const MemoWord({
    required this.arabic,
    this.bangla = '',
    this.startMs = 0,
    this.endMs = 0,
  });

  final String arabic;
  final String bangla;
  final int startMs;
  final int endMs;

  factory MemoWord.fromJson(Map<String, dynamic> json) {
    return MemoWord(
      arabic: json['a']?.toString() ?? '',
      bangla: json['b']?.toString() ?? '',
      startMs: MemoAyah.asInt(json['s']),
      endMs: MemoAyah.asInt(json['e']),
    );
  }
}

/// A single ayah inside a memorization entry.
class MemoAyah {
  const MemoAyah({
    required this.number,
    required this.numberInSurah,
    this.arabic = '',
    this.pronunciation = '',
    this.meaning = '',
    this.audioUrl = '',
    this.durationMs = 0,
    this.words = const [],
  });

  /// Global ayah number (1..6236) used for audio and identity.
  final int number;
  final int numberInSurah;
  final String arabic;
  final String pronunciation;
  final String meaning;
  final String audioUrl;

  /// Length of this ayah's recitation in milliseconds (0 if unknown).
  final int durationMs;

  /// Word breakdown used for word-by-word highlighting.
  final List<MemoWord> words;

  bool get hasWords => words.isNotEmpty;

  /// Index of the word being recited at [elapsedMs] within this ayah, or -1
  /// when there are no words.
  int wordIndexAt(int elapsedMs) {
    if (words.isEmpty) return -1;
    var index = 0;
    for (var i = 0; i < words.length; i++) {
      if (elapsedMs >= words[i].startMs) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  factory MemoAyah.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'];
    return MemoAyah(
      number: _asInt(json['number']),
      numberInSurah: _asInt(json['numberInSurah']),
      arabic: json['arabic']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      durationMs: _asInt(json['durationMs']),
      words: rawWords is List
          ? rawWords
              .whereType<Map>()
              .map((e) => MemoWord.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
    );
  }

  static int asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) => asInt(value);
}

/// A memorization entry (ayah, hadith, dua, etc.).
class MemorizationItem {
  const MemorizationItem({
    required this.id,
    required this.title,
    this.arabic = '',
    this.transliteration = '',
    this.meaning = '',
    this.reference = '',
    this.audioUrl = '',
    this.stage = '',
    this.ayahs = const [],
  });

  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String reference;
  final String audioUrl;
  final String stage;

  /// Per-ayah breakdown. Empty for flat entries (duas, single texts).
  final List<MemoAyah> ayahs;

  bool get hasAyahs => ayahs.isNotEmpty;

  factory MemorizationItem.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'];
    return MemorizationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'শিরোনামহীন',
      arabic: json['arabic']?.toString() ?? '',
      transliteration: json['transliteration']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      ayahs: rawAyahs is List
          ? rawAyahs
              .whereType<Map>()
              .map((e) => MemoAyah.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
    );
  }
}
