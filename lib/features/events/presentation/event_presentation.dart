import 'package:intl/intl.dart';

import '../domain/countdown.dart';
import '../domain/event.dart';

/// The big number + its unit as shown on a card or the detail header.
class CountLabel {
  const CountLabel({required this.big, required this.unit, required this.caption});

  /// e.g. "12", "当日", "365"
  final String big;

  /// e.g. "日", "" — empty when [big] is a word like "当日"
  final String unit;

  /// e.g. "12月24日(火) まで" / "2023年4月1日から"
  final String caption;

  static CountLabel of(Event event, DateTime today) {
    final next = Countdown.nextOccurrence(event, today);
    switch (event.countMode) {
      case CountMode.daysLeft:
        final left = Countdown.daysLeft(event, today);
        if (left == 0) {
          return CountLabel(big: '当日', unit: '', caption: _fmt(next));
        }
        if (left > 0) {
          return CountLabel(
              big: '$left', unit: '日', caption: '${_fmt(next)} まで');
        }
        return CountLabel(
            big: '${left.abs()}', unit: '日前', caption: '${_fmt(next)} に終了');
      case CountMode.daysSince:
        final since = Countdown.daysSince(event, today);
        if (since < 0) {
          return CountLabel(
              big: '${since.abs()}', unit: '日', caption: '${_fmt(event.targetDate)} から');
        }
        return CountLabel(
            big: '$since', unit: '日', caption: '${_fmt(event.targetDate)} から');
    }
  }
}

String _fmt(DateTime d) => DateFormat('M月d日(E)', 'ja').format(d);

String formatFullDate(DateTime d) => DateFormat('yyyy年M月d日(E)', 'ja').format(d);

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

String countModeLabel(CountMode mode) {
  switch (mode) {
    case CountMode.daysLeft:
      return 'あと何日';
    case CountMode.daysSince:
      return '経過日数';
  }
}

String notificationOffsetLabel(int offsetDays) =>
    offsetDays == 0 ? '当日' : '$offsetDays日前';
