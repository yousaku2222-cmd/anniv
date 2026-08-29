import 'package:anniv/features/backup/domain/backup_codec.dart';
import 'package:anniv/features/events/domain/event.dart';
import 'package:anniv/features/groups/domain/event_group.dart';
import 'package:anniv/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event(String id) {
  final ts = DateTime(2026, 1, 1);
  return Event(
    id: id,
    title: 'イベント $id',
    type: EventType.anniversary,
    targetDate: DateTime(2020, 6, 15),
    repeat: RepeatRule.yearly,
    notifications: const [NotificationRule(offsetDays: 1)],
    milestones: const [100],
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  test('round-trips events, groups and settings', () {
    final data = BackupData(
      events: [_event('a'), _event('b')],
      groups: const [EventGroup(id: 'g1', name: '家族', order: 0)],
      settings: const AppSettings(adRemoved: true, onboardingDone: true),
      exportedAt: DateTime(2026, 8, 29, 10),
    );

    final restored = BackupCodec.decode(BackupCodec.encode(data));

    expect(restored.events.map((e) => e.id), ['a', 'b']);
    expect(restored.events.first.milestones, [100]);
    expect(restored.groups.single.name, '家族');
    expect(restored.settings.adRemoved, isTrue);
    expect(restored.exportedAt, DateTime(2026, 8, 29, 10));
  });

  test('rejects a file that is not an Anniv backup', () {
    expect(
      () => BackupCodec.decode('{"app":"someotherapp","version":1}'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects non-JSON input', () {
    expect(
      () => BackupCodec.decode('totally not json'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects a newer backup version', () {
    expect(
      () => BackupCodec.decode('{"app":"anniv","version":999}'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('tolerates a backup with no groups or settings', () {
    final restored =
        BackupCodec.decode('{"app":"anniv","version":1,"events":[]}');
    expect(restored.events, isEmpty);
    expect(restored.groups, isEmpty);
    expect(restored.settings, AppSettings.defaults);
  });
}
