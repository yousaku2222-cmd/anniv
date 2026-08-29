import 'package:anniv/features/events/domain/event.dart';
import 'package:anniv/features/widget/domain/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 8, 29);

Event _event(String id, DateTime target,
    {RepeatRule repeat = RepeatRule.none, bool hidden = false}) {
  final ts = DateTime(2020);
  return Event(
    id: id,
    title: id,
    type: EventType.custom,
    targetDate: target,
    repeat: repeat,
    isHidden: hidden,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  test('empty list yields the placeholder snapshot', () {
    final s = WidgetSnapshotBuilder.of(const [], _today);
    expect(s.empty, isTrue);
    expect(s, WidgetSnapshot.none);
  });

  test('features the soonest upcoming event, ignoring past and hidden', () {
    final s = WidgetSnapshotBuilder.of([
      _event('far', DateTime(2026, 12, 24)),
      _event('past', DateTime(2026, 1, 1)),
      _event('soon', DateTime(2026, 9, 3)),
      _event('hidden-soonest', DateTime(2026, 8, 30), hidden: true),
    ], _today);

    expect(s.empty, isFalse);
    expect(s.title, 'soon');
    expect(s.count, '5');
    expect(s.unit, '日');
    expect(s.caption, '9月3日 まで');
  });

  test('on the day itself shows 当日 with no unit', () {
    final s = WidgetSnapshotBuilder.of([
      _event('today', DateTime(2026, 8, 29)),
    ], _today);
    expect(s.count, '当日');
    expect(s.unit, '');
    expect(s.caption, '8月29日');
  });

  test('uses the next occurrence for a yearly event', () {
    final s = WidgetSnapshotBuilder.of([
      _event('bday', DateTime(1990, 9, 1), repeat: RepeatRule.yearly),
    ], _today);
    expect(s.count, '3');
    expect(s.caption, '9月1日 まで');
  });
}
