import 'package:intl/intl.dart';

/// Date helpers used for study tracking and spaced revision.
class DateUtilsX {
  DateUtilsX._();

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _prettyFormat = DateFormat('d MMM yyyy');

  /// Normalizes a date to midnight (used as a day key).
  static DateTime dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  /// The current day key.
  static DateTime today() => dayKey(DateTime.now());

  /// Serializes a date to `yyyy-MM-dd`.
  static String encode(DateTime date) => _dayFormat.format(date);

  /// Parses a `yyyy-MM-dd` string, returning null on failure.
  static DateTime? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return _dayFormat.parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  /// Human friendly date, e.g. `13 Oct 2026`.
  static String pretty(DateTime date) => _prettyFormat.format(date);

  /// Relative label such as `আজ`, `গতকাল`, `আগামীকাল` or a pretty date.
  static String relativeBn(DateTime date) {
    final target = dayKey(date);
    final now = today();
    final diff = target.difference(now).inDays;
    switch (diff) {
      case 0:
        return 'আজ';
      case 1:
        return 'আগামীকাল';
      case -1:
        return 'গতকাল';
      case -2:
        return '২ দিন আগে';
      default:
        if (diff > 1) return '$diff দিন পরে';
        return pretty(date);
    }
  }

  /// Whether two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
