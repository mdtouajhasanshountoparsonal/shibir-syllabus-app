import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../services/local_store.dart';
import '../models/enums.dart';
import '../models/progress.dart';
import '../models/syllabus.dart';

/// Reads and writes per-item reading progress plus daily study counters.
class ProgressRepository {
  ProgressRepository._();

  static final ProgressRepository instance = ProgressRepository._();

  final LocalStore _store = LocalStore.instance;

  ReadingProgress get(String itemId) =>
      _store.readProgress(itemId) ?? ReadingProgress(itemId: itemId);

  Map<String, ReadingProgress> all() => _store.readAllProgress();

  Future<void> setStatus(String itemId, StudyStatus status) async {
    final current = get(itemId);
    await _store.writeProgress(
      current.copyWith(status: status, updatedAt: DateTime.now()),
    );
  }

  /// Records that the user studied [minutes] today and returns the updated
  /// daily total.
  Future<int> addStudyMinutes(int minutes) async {
    final today = DateUtilsX.today();
    final lastDay = DateUtilsX.decode(
      _store.getSetting<String>(PrefKeys.lastStudyDate),
    );
    var total = _store.getSetting<int>(PrefKeys.todayReadMinutes, fallback: 0) ?? 0;
    var streak = _store.getSetting<int>(PrefKeys.dailyStreak, fallback: 0) ?? 0;

    if (lastDay == null || !DateUtilsX.isSameDay(lastDay, today)) {
      // First study session of a new day.
      if (lastDay != null &&
          today.difference(DateUtilsX.dayKey(lastDay)).inDays == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
      total = 0;
    }

    total += minutes;
    await _store.setSetting(PrefKeys.todayReadMinutes, total);
    await _store.setSetting(PrefKeys.lastStudyDate, DateUtilsX.encode(today));
    await _store.setSetting(PrefKeys.dailyStreak, streak);
    return total;
  }

  int get todayReadMinutes =>
      _store.getSetting<int>(PrefKeys.todayReadMinutes, fallback: 0) ?? 0;

  int get dailyStreak =>
      _store.getSetting<int>(PrefKeys.dailyStreak, fallback: 0) ?? 0;

  int get dailyGoalMinutes =>
      _store.getSetting<int>(PrefKeys.dailyGoalMinutes, fallback: 30) ?? 30;

  Future<void> setDailyGoal(int minutes) =>
      _store.setSetting(PrefKeys.dailyGoalMinutes, minutes);

  int completedCount(Iterable<String> itemIds) {
    final allProgress = all();
    return itemIds
        .where((id) => allProgress[id]?.status == StudyStatus.completed)
        .length;
  }

  /// Returns the most recently updated item that is still in progress.
  ReadingProgress? continueCandidate(Iterable<SyllabusItem> items) {
    final allProgress = all();
    ReadingProgress? best;
    for (final item in items) {
      final p = allProgress[item.id];
      if (p == null) continue;
      if (p.status != StudyStatus.reading &&
          p.status != StudyStatus.needsRevision) {
        continue;
      }
      if (best == null ||
          (p.updatedAt != null &&
              (best.updatedAt == null || p.updatedAt!.isAfter(best.updatedAt!)))) {
        best = p;
      }
    }
    return best;
  }
}
