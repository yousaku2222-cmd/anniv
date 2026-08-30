import 'package:intl/intl.dart';

import '../domain/countdown.dart';
import '../domain/event.dart';

/// The big number + its unit as shown on a card or the detail header.
class CountLabel {
  const CountLabel({
    required this.big,
    required this.unit,
    required this.caption,
    required this.kind,
  });

  /// e.g. "7", "当日", "+110"
  final String big;

  /// e.g. "日後", "日目", "" — empty when [big] is a word like "当日"
  final String unit;

  /// e.g. "12月24日(火) まで" / "2023年4月1日 から"
  final String caption;

  /// "COUNTDOWN" or "ELAPSED" — the small uppercase label under the number.
  final String kind;

  static CountLabel of(Event event, DateTime today) {
    final next = Countdown.nextOccurrence(event, today);
    switch (event.countMode) {
      case CountMode.daysLeft:
      case CountMode.repeatNext:
        final left = Countdown.daysLeft(event, today);
        if (left == 0) {
          return CountLabel(
              big: '当日', unit: '', caption: _fmt(next), kind: 'COUNTDOWN');
        }
        if (left > 0) {
          return CountLabel(
              big: '$left',
              unit: '日後',
              caption: '${_fmt(next)} まで',
              kind: 'COUNTDOWN');
        }
        return CountLabel(
            big: '${left.abs()}',
            unit: '日前',
            caption: '${_fmt(next)} に終了',
            kind: 'COUNTDOWN');
      case CountMode.daysSince:
        final since = Countdown.daysSince(event, today);
        if (since < 0) {
          return CountLabel(
              big: '${since.abs()}',
              unit: '日後',
              caption: '${_fmt(event.targetDate)} から',
              kind: 'ELAPSED');
        }
        return CountLabel(
            big: '+$since',
            unit: '日目',
            caption: '${_fmt(event.targetDate)} から',
            kind: 'ELAPSED');
    }
  }
}

String _fmt(DateTime d) => DateFormat('M月d日(E)', 'ja').format(d);

String formatFullDate(DateTime d) => DateFormat('yyyy年M月d日(E)', 'ja').format(d);

String formatDotDate(DateTime d) => DateFormat('yyyy.MM.dd', 'ja').format(d);

String formatShortDate(DateTime d) => DateFormat('M/d(E)', 'ja').format(d);

/// The red "hot" pill on a card — shown when a countdown event is within a week.
String? hotPillText(Event event, DateTime today) {
  if (event.countMode == CountMode.daysSince) return null;
  final left = Countdown.daysLeft(event, today);
  if (left < 0 || left > 7) return null;
  return left == 0 ? '当日' : 'あと$left日';
}

String repeatLabel(RepeatRule rule) {
  switch (rule) {
    case RepeatRule.none:
      return '繰り返しなし';
    case RepeatRule.yearly:
      return '毎年';
    case RepeatRule.monthly:
      return '毎月';
    case RepeatRule.weekly:
      return '毎週';
  }
}

/// Short repeat chip ("毎年" / null when non-repeating).
String? repeatChipText(RepeatRule rule) =>
    rule == RepeatRule.none ? null : repeatLabel(rule);

String repeatValueLabel(RepeatRule rule) =>
    rule == RepeatRule.none ? 'なし（単発）' : repeatLabel(rule);

String countModeLabel(CountMode mode) {
  switch (mode) {
    case CountMode.daysLeft:
      return '残り日数（カウントダウン）';
    case CountMode.daysSince:
      return '経過日数';
    case CountMode.repeatNext:
      return '次の繰り返しまで';
  }
}

String notificationOffsetLabel(int offsetDays) =>
    offsetDays == 0 ? '当日' : '$offsetDays日前';

/// "🎌 次のマイルストーン あと32日で 90日前" style text for the detail hero pill.
String milestonePillText(
    ({int days, DateTime date, int daysAway}) m, Event event) {
  final noun = Countdown.milestoneIsBefore(event) ? '${m.days}日前' : '${m.days}日目';
  return '次のマイルストーン  あと${m.daysAway}日で $noun';
}
