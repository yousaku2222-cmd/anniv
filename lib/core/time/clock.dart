import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now", injectable so date math can be tested deterministically.
abstract class Clock {
  const Clock();

  DateTime now();

  /// Today with the time-of-day stripped (local midnight).
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Fixed clock for tests and previews.
class FixedClock extends Clock {
  const FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Recomputed by [homeRefreshProvider] callers; exposes today's date so widgets
/// that show "days left" rebuild when the calendar day rolls over.
final todayProvider = Provider<DateTime>((ref) => ref.watch(clockProvider).today());
