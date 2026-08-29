import '../../events/domain/countdown.dart';
import '../../events/domain/event.dart';

/// The small bundle of strings the home-screen widget renders. Kept flat and
/// pre-formatted so the native side needs no logic.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.empty,
    required this.title,
    required this.count,
    required this.unit,
    required this.caption,
  });

  final bool empty;
  final String title;
  final String count;
  final String unit;
  final String caption;

  static const WidgetSnapshot none = WidgetSnapshot(
    empty: true,
    title: '記念日を追加',
    count: '—',
    unit: '',
    caption: 'Anniv を開いて登録',
  );

  Map<String, Object> toData() => {
        'anniv_empty': empty,
        'anniv_title': title,
        'anniv_count': count,
        'anniv_unit': unit,
        'anniv_caption': caption,
      };
}

class WidgetSnapshotBuilder {
  const WidgetSnapshotBuilder._();

  /// Features the soonest upcoming event (smallest non-negative "days left").
  /// Falls back to [WidgetSnapshot.none] when nothing qualifies.
  static WidgetSnapshot of(List<Event> events, DateTime today) {
    Event? best;
    var bestLeft = 1 << 30;
    for (final e in events) {
      if (e.isHidden) continue;
      final left = Countdown.daysLeft(e, today);
      if (left < 0) continue;
      if (left < bestLeft) {
        bestLeft = left;
        best = e;
      }
    }
    if (best == null) return WidgetSnapshot.none;

    final date = Countdown.nextOccurrence(best, today);
    final caption = '${date.month}月${date.day}日';
    if (bestLeft == 0) {
      return WidgetSnapshot(
        empty: false,
        title: best.title,
        count: '当日',
        unit: '',
        caption: caption,
      );
    }
    return WidgetSnapshot(
      empty: false,
      title: best.title,
      count: '$bestLeft',
      unit: '日',
      caption: '$caption まで',
    );
  }
}
