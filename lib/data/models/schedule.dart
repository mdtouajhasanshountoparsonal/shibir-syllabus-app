/// A single practice entry in a month's schedule (label → value).
class SchedulePractice {
  const SchedulePractice({required this.label, required this.value});

  final String label;
  final String value;

  factory SchedulePractice.fromJson(Map<String, dynamic> json) {
    return SchedulePractice(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

/// One month row of the study schedule (কুরআন, হাদিস, সাহিত্য, আলোচনা, চর্চা).
class ScheduleMonth {
  const ScheduleMonth({
    required this.id,
    required this.month,
    this.quran = '',
    this.hadith = '',
    this.literature = const [],
    this.discussion = '',
    this.practice = const [],
  });

  final String id;
  final String month;
  final String quran;
  final String hadith;
  final List<String> literature;
  final String discussion;
  final List<SchedulePractice> practice;

  factory ScheduleMonth.fromJson(Map<String, dynamic> json) {
    final literature = (json['literature'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final practice = (json['practice'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SchedulePractice.fromJson)
        .where((p) => p.label.isNotEmpty || p.value.isNotEmpty)
        .toList(growable: false);
    return ScheduleMonth(
      id: json['id']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      quran: json['quran']?.toString() ?? '',
      hadith: json['hadith']?.toString() ?? '',
      literature: literature,
      discussion: json['discussion']?.toString() ?? '',
      practice: practice,
    );
  }
}

/// A year grouping of monthly schedule rows.
class ScheduleYear {
  const ScheduleYear({required this.year, required this.months});

  final String year;
  final List<ScheduleMonth> months;

  factory ScheduleYear.fromJson(Map<String, dynamic> json) {
    final raw = (json['months'] as List<dynamic>? ?? const []);
    return ScheduleYear(
      year: json['year']?.toString() ?? '',
      months: raw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleMonth.fromJson)
          .where((m) => m.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// The full 2025–2027 study schedule document and extra guidance notes.
class ScheduleData {
  const ScheduleData({
    this.title = '',
    this.subtitle = '',
    this.sourceUrl = '',
    this.sourceLabel = '',
    this.notes = const [],
    this.years = const [],
  });

  final String title;
  final String subtitle;
  final String sourceUrl;
  final String sourceLabel;
  final List<String> notes;
  final List<ScheduleYear> years;

  bool get isEmpty => years.isEmpty;

  static const ScheduleData empty = ScheduleData();

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    final rawYears = (json['years'] as List<dynamic>? ?? const []);
    final notes = (json['notes'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return ScheduleData(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      sourceLabel: json['sourceLabel']?.toString() ?? '',
      notes: notes,
      years: rawYears
          .whereType<Map<String, dynamic>>()
          .map(ScheduleYear.fromJson)
          .where((y) => y.months.isNotEmpty)
          .toList(growable: false),
    );
  }
}
