import 'package:flutter_test/flutter_test.dart';
import 'package:shibir_syllabus_tracker/data/models/enums.dart';
import 'package:shibir_syllabus_tracker/data/models/progress.dart';

void main() {
  group('MemorizationProgress spaced repetition', () {
    test('first success schedules a 1-day review', () {
      final start = DateTime(2026, 10, 13, 9);
      final p = MemorizationProgress(itemId: 'm1').schedule(start);
      expect(p.status, MemoStatus.memorized);
      expect(p.reviewCount, 1);
      expect(p.intervalIndex, 1);
      expect(p.nextReview, DateTime(2026, 10, 14));
    });

    test('successive successes grow the interval', () {
      final start = DateTime(2026, 10, 13);
      var p = MemorizationProgress(itemId: 'm1');
      p = p.schedule(start); // +1 day -> next index 1
      p = p.schedule(start.add(const Duration(days: 1))); // +3 days
      expect(p.intervalIndex, 2);
      expect(p.nextReview, DateTime(2026, 10, 17));
    });

    test('interval stops growing at 30 days', () {
      final start = DateTime(2026, 10, 13);
      var p = MemorizationProgress(itemId: 'm1');
      for (var i = 0; i < 6; i++) {
        p = p.schedule(start);
      }
      expect(p.intervalIndex, MemorizationProgress.kReviewIntervals.length - 1);
    });

    test('due detection', () {
      final now = DateTime(2026, 10, 13);
      final notDue = MemorizationProgress(
        itemId: 'm1',
        status: MemoStatus.memorized,
        nextReview: now.add(const Duration(days: 2)),
      );
      expect(notDue.isDue(now), isFalse);

      final due = MemorizationProgress(
        itemId: 'm1',
        status: MemoStatus.learning,
        nextReview: now.subtract(const Duration(days: 1)),
      );
      expect(due.isDue(now), isTrue);

      final neverReviewed = MemorizationProgress(itemId: 'm1');
      expect(neverReviewed.isDue(now), isTrue);
    });
  });

  group('ReadingProgress serialization', () {
    test('round-trips through a map', () {
      final original = ReadingProgress(
        itemId: 'x',
        status: StudyStatus.reading,
        updatedAt: DateTime(2026, 10, 13),
      );
      final restored = ReadingProgress.fromMap(original.toMap());
      expect(restored.itemId, 'x');
      expect(restored.status, StudyStatus.reading);
      expect(restored.updatedAt, DateTime(2026, 10, 13));
    });
  });
}
