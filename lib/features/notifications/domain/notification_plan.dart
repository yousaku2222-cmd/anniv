import '../../events/domain/countdown.dart';
import '../../events/domain/event.dart';
import '../../settings/domain/app_settings.dart';

/// A single OS-level notification to be scheduled at [fireAt].
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.eventId,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  /// Stable 31-bit id derived from the event + occurrence + kind, so re-planning
  /// produces the same ids and the scheduler can diff instead of clearing all.
  final int id;
  final String eventId;
  final DateTime fireAt;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ScheduledNotification &&
      other.id == id &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, fireAt, title, body);

  @override
  String toString() =>
      'ScheduledNotification(#$id $fireAt "$title" / "$body")';
}

/// Turns the event list into a bounded, time-ordered set of notifications.
///
/// Pure and deterministic: every input is passed explicitly. The scheduler
/// (platform side) just mirrors whatever this returns.
class NotificationPlanner {
  const NotificationPlanner._();

  /// iOS allows at most 64 pending notifications; stay well under.
  static const int maxScheduled = 60;

  /// How far ahead to schedule. Repeating events are re-planned on app start.
  static const int horizonDays = 365;

  static List<ScheduledNotification> plan({
    required List<Event> events,
    required AppSettings settings,
    required DateTime now,
  }) {
    final horizon = now.add(const Duration(days: horizonDays));
    final result = <ScheduledNotification>[];

    for (final event in events) {
      if (event.isHidden) continue;
      result.addAll(_forEvent(event, settings, now, horizon));
    }

    result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    if (result.length > maxScheduled) {
      return result.sublist(0, maxScheduled);
    }
    return result;
  }

  static Iterable<ScheduledNotification> _forEvent(
    Event event,
    AppSettings settings,
    DateTime now,
    DateTime horizon,
  ) sync* {
    final occurrences = _occurrences(event, now, horizon);

    for (final occ in occurrences) {
      for (final rule in event.notifications) {
        final fireDate = DateTime(occ.year, occ.month, occ.day - rule.offsetDays);
        final fireAt = rule.time.onDate(fireDate);
        if (fireAt.isAfter(now) && fireAt.isBefore(horizon)) {
          yield ScheduledNotification(
            id: _stableId(event.id, occ, 'r${rule.offsetDays}'),
            eventId: event.id,
            fireAt: fireAt,
            title: event.title,
            body: _reminderBody(rule.offsetDays),
          );
        }
      }
    }

    // Day-count milestones (e.g. 100 days) fire on the day itself.
    for (final m in event.milestones) {
      final date = Countdown.milestoneDate(event, m);
      final fireAt = settings.defaultNotifyTime.onDate(date);
      if (fireAt.isAfter(now) && fireAt.isBefore(horizon)) {
        yield ScheduledNotification(
          id: _stableId(event.id, date, 'm$m'),
          eventId: event.id,
          fireAt: fireAt,
          title: event.title,
          body: '$m日を迎えました 🎉',
        );
      }
    }
  }

  /// Target dates for [event] falling within `[now, horizon]`.
  static List<DateTime> _occurrences(Event event, DateTime now, DateTime horizon) {
    final today = DateTime(now.year, now.month, now.day);
    final t = DateTime(
        event.targetDate.year, event.targetDate.month, event.targetDate.day);

    switch (event.repeat) {
      case RepeatRule.none:
        return (!t.isBefore(today) && t.isBefore(horizon)) ? [t] : const [];

      case RepeatRule.yearly:
        final out = <DateTime>[];
        for (var year = today.year; year <= horizon.year + 1; year++) {
          final d = _clamped(year, t.month, t.day);
          if (!d.isBefore(today) && d.isBefore(horizon)) out.add(d);
        }
        return out;

      case RepeatRule.monthly:
        final out = <DateTime>[];
        var year = today.year;
        var month = today.month;
        for (var i = 0; i < 14; i++) {
          final d = _clamped(year, month, t.day);
          if (!d.isBefore(today) && d.isBefore(horizon)) out.add(d);
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return out;

      case RepeatRule.weekly:
        final out = <DateTime>[];
        final delta = (t.weekday - today.weekday + 7) % 7;
        var d = today.add(Duration(days: delta));
        while (d.isBefore(horizon)) {
          out.add(d);
          d = d.add(const Duration(days: 7));
        }
        return out;
    }
  }

  static DateTime _clamped(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  static String _reminderBody(int offsetDays) {
    if (offsetDays <= 0) return '今日です 🎉';
    if (offsetDays == 1) return '明日です';
    return 'あと$offsetDays日';
  }

  static int _stableId(String eventId, DateTime occ, String tag) {
    final key = '$eventId|${occ.year}-${occ.month}-${occ.day}|$tag';
    return key.hashCode & 0x7fffffff;
  }
}
