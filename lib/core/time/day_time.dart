import 'package:flutter/foundation.dart';

/// A wall-clock time of day (no date, no timezone), used for notification times.
///
/// Kept independent of Flutter's `TimeOfDay` so the domain layer stays free of
/// widget dependencies and serialises to a plain `"HH:mm"` string.
@immutable
class DayTime implements Comparable<DayTime> {
  const DayTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  static const DayTime nineAm = DayTime(9, 0);

  /// Parses `"HH:mm"` (e.g. `"09:05"`). Throws [FormatException] on bad input.
  factory DayTime.parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Expected "HH:mm"', value);
    }
    return DayTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// `"HH:mm"`, zero-padded.
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Combines this time with [date]'s year/month/day.
  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(DayTime other) => onDate(DateTime(2000)).compareTo(
        other.onDate(DateTime(2000)),
      );

  @override
  bool operator ==(Object other) =>
      other is DayTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'DayTime(${format()})';
}
