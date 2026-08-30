import 'package:anniv/features/events/domain/event.dart';
import 'package:anniv/features/notifications/domain/notification_plan.dart';
import 'package:anniv/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = AppSettings();
final _now = DateTime(2026, 8, 29, 8, 0);

Event _event({
  required DateTime target,
  RepeatRule repeat = RepeatRule.none,
  CountMode countMode = CountMode.daysLeft,
  List<NotificationRule> notifications = const [],
  List<int> milestones = const [],
  bool hidden = false,
  String id = 'e1',
}) {
  final ts = DateTime(2020);
  return Event(
    id: id,
    title: 'テスト',
    type: EventType.custom,
    targetDate: target,
    repeat: repeat,
    countMode: countMode,
    notifications: notifications,
    milestones: milestones,
    isHidden: hidden,
    createdAt: ts,
    updatedAt: ts,
  );
}

List<ScheduledNotification> _plan(List<Event> events) =>
    NotificationPlanner.plan(events: events, settings: _settings, now: _now);

void main() {
  test('one notification per rule for an upcoming non-repeating event', () {
    final plan = _plan([
      _event(
        target: DateTime(2026, 9, 8),
        notifications: const [
          NotificationRule(offsetDays: 0),
          NotificationRule(offsetDays: 1),
          NotificationRule(offsetDays: 7),
        ],
      ),
    ]);

    expect(plan.map((n) => n.fireAt), [
      DateTime(2026, 9, 1, 9),
      DateTime(2026, 9, 7, 9),
      DateTime(2026, 9, 8, 9),
    ]);
    expect(plan.last.body, '今日です 🎉');
    expect(plan[1].body, '明日です');
    expect(plan.first.body, 'あと7日');
  });

  test('past non-repeating events produce nothing', () {
    final plan = _plan([
      _event(
        target: DateTime(2026, 8, 1),
        notifications: const [NotificationRule(offsetDays: 0)],
      ),
    ]);
    expect(plan, isEmpty);
  });

  test('elapsed milestones fire on the day at the default notify time', () {
    final plan = _plan([
      _event(
        target: DateTime(2026, 6, 1),
        countMode: CountMode.daysSince,
        milestones: const [100],
      ),
    ]);
    expect(plan, hasLength(1));
    expect(plan.single.fireAt, DateTime(2026, 9, 9, 9));
    expect(plan.single.body, '100日目を迎えました 🎉');
  });

  test('countdown milestones fire N days before the occurrence', () {
    final plan = _plan([
      _event(
        target: DateTime(2026, 12, 30),
        milestones: const [90],
      ),
    ]);
    expect(plan, hasLength(1));
    // 2026-12-30 minus 90 days = 2026-10-01.
    expect(plan.single.fireAt, DateTime(2026, 10, 1, 9));
    expect(plan.single.body, 'あと90日です');
  });

  test('hidden events are skipped', () {
    final plan = _plan([
      _event(
        target: DateTime(2026, 6, 1),
        countMode: CountMode.daysSince,
        milestones: const [100],
        hidden: true,
      ),
    ]);
    expect(plan, isEmpty);
  });

  test('yearly event schedules its next occurrence', () {
    final plan = _plan([
      _event(
        target: DateTime(2000, 12, 24),
        repeat: RepeatRule.yearly,
        notifications: const [NotificationRule(offsetDays: 3)],
      ),
    ]);
    expect(plan, hasLength(1));
    expect(plan.single.fireAt, DateTime(2026, 12, 21, 9));
  });

  test('result is capped and time-ordered', () {
    final events = [
      for (var i = 0; i < 30; i++)
        _event(
          id: 'e$i',
          target: DateTime(2026, 8, 31),
          repeat: RepeatRule.weekly,
          notifications: const [NotificationRule(offsetDays: 0)],
        ),
    ];
    final plan = _plan(events);
    expect(plan, hasLength(NotificationPlanner.maxScheduled));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
    }
  });

  test('ids are stable across re-planning', () {
    final event = _event(
      target: DateTime(2026, 9, 8),
      notifications: const [NotificationRule(offsetDays: 1)],
    );
    expect(_plan([event]).single.id, _plan([event]).single.id);
  });
}
