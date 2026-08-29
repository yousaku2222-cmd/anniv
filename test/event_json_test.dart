import 'package:anniv/core/time/day_time.dart';
import 'package:anniv/features/events/domain/event.dart';
import 'package:anniv/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Event survives a JSON round-trip', () {
    final now = DateTime(2026, 8, 29, 12, 30);
    final event = Event(
      id: 'abc',
      title: '母の誕生日',
      type: EventType.birthday,
      targetDate: DateTime(1960, 4, 1),
      repeat: RepeatRule.yearly,
      countMode: CountMode.daysLeft,
      groupId: 'family',
      colorValue: 0xFF8A3D63,
      iconCodePoint: 0xe1e1,
      notifications: const [
        NotificationRule(offsetDays: 0, time: DayTime(9, 0)),
        NotificationRule(offsetDays: 7, time: DayTime(20, 30)),
      ],
      milestones: const [100, 365],
      createdAt: now,
      updatedAt: now,
    );

    final restored = Event.fromJson(event.toJson());

    expect(restored.id, event.id);
    expect(restored.title, event.title);
    expect(restored.type, EventType.birthday);
    expect(restored.targetDate, event.targetDate);
    expect(restored.repeat, RepeatRule.yearly);
    expect(restored.groupId, 'family');
    expect(restored.colorValue, 0xFF8A3D63);
    expect(restored.notifications, event.notifications);
    expect(restored.milestones, event.milestones);
  });

  test('unknown enum names fall back instead of throwing', () {
    final json = {
      'id': 'x',
      'title': 't',
      'type': 'bogus',
      'targetDate': DateTime(2026, 1, 1).toIso8601String(),
      'repeat': 'fortnightly',
      'countMode': 'sideways',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    };
    final e = Event.fromJson(json);
    expect(e.type, EventType.custom);
    expect(e.repeat, RepeatRule.none);
    expect(e.countMode, CountMode.daysLeft);
  });

  test('AppSettings round-trips', () {
    const settings = AppSettings(
      defaultNotifyTime: DayTime(8, 15),
      weekStart: WeekStart.monday,
      displayFormat: DisplayFormat.date,
      themeMode: AppThemeMode.dark,
      adRemoved: true,
      onboardingDone: true,
    );
    expect(AppSettings.fromJson(settings.toJson()), settings);
  });

  test('DayTime parses and formats "HH:mm"', () {
    expect(DayTime.parse('09:05').format(), '09:05');
    expect(const DayTime(23, 0).format(), '23:00');
  });
}
