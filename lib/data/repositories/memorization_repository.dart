import '../../core/utils/date_utils.dart';
import '../../services/local_store.dart';
import '../models/enums.dart';
import '../models/memorization.dart';
import '../models/progress.dart';

/// Manages memorization status and spaced-repetition scheduling.
class MemorizationRepository {
  MemorizationRepository._();

  static final MemorizationRepository instance = MemorizationRepository._();

  final LocalStore _store = LocalStore.instance;

  MemorizationProgress get(String itemId) =>
      _store.readMemoProgress(itemId) ?? MemorizationProgress(itemId: itemId);

  Map<String, MemorizationProgress> all() => _store.readAllMemoProgress();

  /// Marks the item as memorized for today and schedules the next review.
  Future<void> markMemorized(String itemId, {DateTime? now}) async {
    final current = get(itemId);
    final updated = current.schedule(now ?? DateTime.now());
    await _store.writeMemoProgress(updated);
  }

  /// Records a failed recall: send it back for tomorrow's practice.
  Future<void> markNeedsPractice(String itemId, {DateTime? now}) async {
    final current = get(itemId);
    final from = now ?? DateTime.now();
    final updated = current.copyWith(
      status: MemoStatus.learning,
      intervalIndex: 0,
      nextReview: DateTime(from.year, from.month, from.day)
          .add(const Duration(days: 1)),
      lastReviewedAt: from,
    );
    await _store.writeMemoProgress(updated);
  }

  Future<void> markLearning(String itemId) async {
    final current = get(itemId);
    await _store.writeMemoProgress(current.markLearning());
  }

  /// Items whose next review date is today or earlier.
  List<MemorizationItem> dueItems(
    List<MemorizationItem> items, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final progress = all();
    return items.where((item) {
      final p = progress[item.id];
      if (p == null) return false;
      return p.isDue(at);
    }).toList(growable: false);
  }

  /// New (never reviewed) items available to start memorizing.
  List<MemorizationItem> newItems(List<MemorizationItem> items) {
    final progress = all();
    return items
        .where((item) => !progress.containsKey(item.id))
        .toList(growable: false);
  }

  int get memorizedCount => all()
      .values
      .where((p) => p.status == MemoStatus.memorized)
      .length;

  /// Simple consecutive-day streak based on review dates.
  int get reviewStreak {
    final dates = all()
        .values
        .map((p) => p.lastReviewedAt)
        .whereType<DateTime>()
        .map(DateUtilsX.dayKey)
        .toSet();
    if (dates.isEmpty) return 0;
    var streak = 0;
    var cursor = DateUtilsX.today();
    while (dates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
