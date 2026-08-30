import 'event.dart';

/// Pure date math for events. All functions take an explicit `today` (local
/// midnight) so they are deterministic and unit-testable.
class Countdown {
  const Countdown._();

  /// Whole calendar days from [from] to [to]. Positive when [to] is later.
  /// Both operands are reduced to their date component first, so partial days
  /// and DST shifts don't leak in.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Builds a valid date, clamping the day down when the month is shorter
  /// (e.g. Feb 29 -> Feb 28, or the 31st -> 30th).
  static DateTime _clamped(int year, int month, int day) {
    final lastOfMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastOfMonth ? lastOfMonth : day);
  }

  /// The occurrence the event is currently counting toward.
  ///
  /// * [RepeatRule.none] — the target date itself.
  /// * [RepeatRule.yearly] — the next month/day anniversary that is today or
  ///   later.
  /// * [RepeatRule.monthly] — the next same-day-of-month, today or later.
  /// * [RepeatRule.weekly] — the next same weekday, today or later.
  static DateTime nextOccurrence(Event event, DateTime today) {
    final t = DateTime(
        event.targetDate.year, event.targetDate.month, event.targetDate.day);
    final now = DateTime(today.year, today.month, today.day);

    switch (event.repeat) {
      case RepeatRule.none:
        return t;

      case RepeatRule.yearly:
        var candidate = _clamped(now.year, t.month, t.day);
        if (candidate.isBefore(now)) {
          candidate = _clamped(now.year + 1, t.month, t.day);
        }
        return candidate;

      case RepeatRule.monthly:
        var candidate = _clamped(now.year, now.month, t.day);
        if (candidate.isBefore(now)) {
          candidate = _clamped(now.year, now.month + 1, t.day);
        }
        return candidate;

      case RepeatRule.weekly:
        final delta = (t.weekday - now.weekday + 7) % 7;
        return now.add(Duration(days: delta));
    }
  }

  /// Days remaining until the next occurrence. 0 means today; negative only for
  /// non-repeating events whose date has passed.
  static int daysLeft(Event event, DateTime today) =>
      daysBetween(today, nextOccurrence(event, today));

  /// Days elapsed since the (first) target date. Negative if it's in the future.
  static int daysSince(Event event, DateTime today) =>
      daysBetween(event.targetDate, today);

  /// The number shown on the card, per the event's [CountMode].
  static int displayCount(Event event, DateTime today) {
    switch (event.countMode) {
      case CountMode.daysLeft:
      case CountMode.repeatNext:
        return daysLeft(event, today);
      case CountMode.daysSince:
        return daysSince(event, today);
    }
  }

  /// The date a given day-count [milestone] falls on.
  ///
  /// * elapsed events ([CountMode.daysSince]) — `targetDate + N` ("N日目")
  /// * countdown events — `nextOccurrence - N` ("N日前")
  static DateTime milestoneDate(Event event, int milestone, DateTime today) {
    if (event.countMode == CountMode.daysSince) {
      return DateTime(event.targetDate.year, event.targetDate.month,
          event.targetDate.day + milestone);
    }
    final occ = nextOccurrence(event, today);
    return DateTime(occ.year, occ.month, occ.day - milestone);
  }

  /// Whether a milestone reads as "before" the day (countdown) or "since" it.
  static bool milestoneIsBefore(Event event) =>
      event.countMode != CountMode.daysSince;

  /// Every milestone with its date, signed day distance and whether it's passed.
  /// Sorted soonest-first among the upcoming ones, passed ones last.
  static List<({int days, DateTime date, int daysAway, bool passed})>
      allMilestones(Event event, DateTime today) {
    final list = [
      for (final m in ({...event.milestones}.toList()..sort()))
        () {
          final date = milestoneDate(event, m, today);
          final away = daysBetween(today, date);
          return (days: m, date: date, daysAway: away, passed: away < 0);
        }(),
    ];
    list.sort((a, b) {
      if (a.passed != b.passed) return a.passed ? 1 : -1;
      return a.daysAway.compareTo(b.daysAway);
    });
    return list;
  }

  /// The soonest milestone that is today or still ahead, or null if none remain.
  static ({int days, DateTime date, int daysAway})? upcomingMilestone(
      Event event, DateTime today) {
    for (final m in allMilestones(event, today)) {
      if (!m.passed) return (days: m.days, date: m.date, daysAway: m.daysAway);
    }
    return null;
  }

  /// Default milestones to celebrate for a "days since" event.
  static const List<int> defaultMilestones = [100, 200, 365, 500, 1000];

  /// Default "N日前" milestones for a countdown event.
  static const List<int> defaultBeforeMilestones = [90, 30, 7];
}
