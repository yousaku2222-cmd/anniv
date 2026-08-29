import 'package:anniv/features/events/domain/countdown.dart';
import 'package:anniv/features/events/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event({
  required DateTime target,
  RepeatRule repeat = RepeatRule.none,
  CountMode countMode = CountMode.daysLeft,
  List<int> milestones = const [],
}) {
  final now = DateTime(2020);
  return Event(
    id: 'e1',
    title: 't',
    type: EventType.custom,
    targetDate: target,
    repeat: repeat,
    countMode: countMode,
    milestones: milestones,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('daysBetween', () {
    test('ignores time-of-day', () {
      expect(
        Countdown.daysBetween(
            DateTime(2026, 8, 29, 23, 59), DateTime(2026, 8, 30, 0, 1)),
        1,
      );
    });

    test('is negative when target is in the past', () {
      expect(
        Countdown.daysBetween(DateTime(2026, 8, 30), DateTime(2026, 8, 29)),
        -1,
      );
    });
  });

  group('nextOccurrence', () {
    test('non-repeating returns the target date', () {
      final e = _event(target: DateTime(2026, 12, 24));
      expect(Countdown.nextOccurrence(e, DateTime(2026, 8, 29)),
          DateTime(2026, 12, 24));
    });

    test('yearly rolls to next year once the day has passed', () {
      final e = _event(target: DateTime(2000, 3, 10), repeat: RepeatRule.yearly);
      expect(Countdown.nextOccurrence(e, DateTime(2026, 3, 11)),
          DateTime(2027, 3, 10));
      expect(Countdown.nextOccurrence(e, DateTime(2026, 3, 10)),
          DateTime(2026, 3, 10));
    });

    test('yearly Feb 29 clamps to Feb 28 in non-leap years', () {
      final e = _event(target: DateTime(2024, 2, 29), repeat: RepeatRule.yearly);
      expect(Countdown.nextOccurrence(e, DateTime(2026, 1, 1)),
          DateTime(2026, 2, 28));
    });

    test('weekly returns the next matching weekday', () {
      // 2026-08-31 is a Monday.
      final e = _event(target: DateTime(2026, 8, 31), repeat: RepeatRule.weekly);
      // 2026-09-02 is a Wednesday -> next Monday is 2026-09-07.
      expect(Countdown.nextOccurrence(e, DateTime(2026, 9, 2)),
          DateTime(2026, 9, 7));
    });
  });

  group('displayCount', () {
    test('daysLeft counts down to a future date', () {
      final e = _event(target: DateTime(2026, 9, 8));
      expect(Countdown.displayCount(e, DateTime(2026, 8, 29)), 10);
    });

    test('daysSince counts up from a past date', () {
      final e = _event(
          target: DateTime(2025, 8, 29), countMode: CountMode.daysSince);
      expect(Countdown.displayCount(e, DateTime(2026, 8, 29)), 365);
    });
  });

  group('upcomingMilestone', () {
    test('returns the soonest milestone still ahead', () {
      final e = _event(
        target: DateTime(2026, 1, 1),
        countMode: CountMode.daysSince,
        milestones: [100, 200, 365],
      );
      final m = Countdown.upcomingMilestone(e, DateTime(2026, 5, 1));
      expect(m, isNotNull);
      expect(m!.days, 200); // day 100 already passed by May 1
    });

    test('returns null when every milestone has passed', () {
      final e = _event(
        target: DateTime(2020, 1, 1),
        countMode: CountMode.daysSince,
        milestones: [100],
      );
      expect(Countdown.upcomingMilestone(e, DateTime(2026, 1, 1)), isNull);
    });
  });
}
