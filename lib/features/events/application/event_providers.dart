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

  /// Inserts the six demo events from the mock spec, dated relative to today so
  /// the countdowns stay meaningful. Used by the "サンプルイベントを見る"
  /// onboarding action. Skips any whose title already exists.
  Future<void> seedSamples() async {
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day);

    Event mk(
      String title,
      EventType type,
      int offsetDays, {
      RepeatRule repeat = RepeatRule.none,
      CountMode mode = CountMode.daysLeft,
      String? group,
      List<int> notif = const [],
      List<int> ms = const [],
    }) {
      return Event(
        id: _uuid.v4(),
        title: title,
        type: type,
        targetDate: t.add(Duration(days: offsetDays)),
        repeat: repeat,
        countMode: mode,
        groupId: group,
        notifications:
            notif.map((o) => NotificationRule(offsetDays: o)).toList(),
        milestones: ms,
        createdAt: now,
        updatedAt: now,
      );
    }

    final samples = <Event>[
      mk('推しのライブ', EventType.oshi, 7, group: 'oshi', notif: [0, 1, 3, 7]),
      mk('付き合った記念日', EventType.anniversary, 19,
          repeat: RepeatRule.yearly,
          group: 'couple',
          notif: [0, 7],
          ms: [7, 100]),
      mk('英検準2級 1次試験', EventType.exam, 35,
          group: 'dai', notif: [1, 3, 7], ms: [30, 7]),
      mk('年末年始 沖縄旅行', EventType.trip, 122,
          group: 'family', notif: [0], ms: [90, 30, 7]),
      mk('ママの誕生日', EventType.birthday, 157,
          repeat: RepeatRule.yearly, group: 'family', notif: [0, 3]),
      mk('赤ちゃん 100日記念', EventType.custom, -110,
          mode: CountMode.daysSince, group: 'family', ms: [100, 176, 365]),
    ];

    final existingTitles = state.map((e) => e.title).toSet();
    final fresh =
        samples.where((e) => !existingTitles.contains(e.title)).toList();
    if (fresh.isEmpty) return;
    await _commit([...state, ...fresh]);
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
