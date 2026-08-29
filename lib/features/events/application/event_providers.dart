import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/time/clock.dart';
import '../data/event_repository.dart';
import '../domain/countdown.dart';
import '../domain/event.dart';
import '../domain/event_templates.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => SharedPrefsEventRepository(ref.watch(sharedPreferencesProvider)),
);

/// The full list of events (including hidden ones), backed by the repository.
class EventsNotifier extends Notifier<List<Event>> {
  static const _uuid = Uuid();

  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  List<Event> build() => _repo.loadAll();

  Future<void> _commit(List<Event> next) async {
    state = List.unmodifiable(next);
    await _repo.saveAll(state);
  }

  /// An unsaved event pre-filled from its template. The edit screen mutates a
  /// local copy and calls [save] to commit.
  Event draftFromTemplate(EventType type) {
    final template = EventTemplate.forType(type);
    final now = DateTime.now();
    return Event(
      id: _uuid.v4(),
      title: '',
      type: type,
      targetDate: DateTime(now.year, now.month, now.day),
      repeat: template.defaultRepeat,
      countMode: template.defaultCountMode,
      notifications: template.buildNotifications(),
      milestones: template.buildMilestones(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> save(Event event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());
    final idx = state.indexWhere((e) => e.id == event.id);
    final next = [...state];
    if (idx == -1) {
      next.add(updated);
    } else {
      next[idx] = updated;
    }
    await _commit(next);
  }

  Future<void> setHidden(String id, {required bool hidden}) async {
    final next = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(isHidden: hidden, updatedAt: DateTime.now())
        else
          e,
    ];
    await _commit(next);
  }

  Future<void> delete(String id) =>
      _commit([for (final e in state) if (e.id != id) e]);

  /// Wholesale replace, used when restoring a backup.
  Future<void> replaceAll(List<Event> events) => _commit([...events]);

  Event? byId(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }
}

final eventsProvider =
    NotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);

/// Currently selected group filter; null means "all".
class GroupFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? groupId) => state = groupId;
}

final groupFilterProvider =
    NotifierProvider<GroupFilterNotifier, String?>(GroupFilterNotifier.new);

/// Visible events (not hidden), filtered by the active group and sorted so the
/// soonest upcoming day is first. "Days since" events sort after upcoming ones.
final visibleEventsProvider = Provider<List<Event>>((ref) {
  final today = ref.watch(todayProvider);
  final filter = ref.watch(groupFilterProvider);
  final events = ref.watch(eventsProvider).where((e) {
    if (e.isHidden) return false;
    if (filter != null && e.groupId != filter) return false;
    return true;
  }).toList();

  int sortKey(Event e) {
    final left = Countdown.daysLeft(e, today);
    if (e.countMode == CountMode.daysSince) return 1 << 20;
    return left >= 0 ? left : (1 << 19) + left.abs();
  }

  events.sort((a, b) {
    final k = sortKey(a).compareTo(sortKey(b));
    return k != 0 ? k : a.title.compareTo(b.title);
  });
  return events;
});

final eventByIdProvider = Provider.family<Event?, String>(
  (ref, id) => ref.watch(eventsProvider.select((list) {
    for (final e in list) {
      if (e.id == id) return e;
    }
    return null;
  })),
);
