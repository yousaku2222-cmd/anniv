import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../data/group_repository.dart';
import '../domain/event_group.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => SharedPrefsGroupRepository(ref.watch(sharedPreferencesProvider)),
);

class GroupsNotifier extends Notifier<List<EventGroup>> {
  static const _uuid = Uuid();
  static const _seededKey = 'anniv.groups.seeded.v1';

  GroupRepository get _repo => ref.read(groupRepositoryProvider);

  @override
  List<EventGroup> build() {
    final loaded = _repo.loadAll();
    if (loaded.isNotEmpty) return loaded;

    // First run (and only the first): seed the mock's default groups so the
    // home filter bar has 家族 / カップル / 推し活 / 大事な日 out of the box.
    // A user who deletes them all won't get them back.
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_seededKey) ?? false) return const [];
    final seeded = EventGroup.defaults;
    Future.microtask(() async {
      await _repo.saveAll(seeded);
      await prefs.setBool(_seededKey, true);
    });
    return seeded;
  }

  Future<void> _commit(List<EventGroup> next) async {
    next.sort((a, b) => a.order.compareTo(b.order));
    state = List.unmodifiable(next);
    await _repo.saveAll(state);
  }

  Future<EventGroup> add(String name) async {
    final group = EventGroup(
      id: _uuid.v4(),
      name: name.trim(),
      order: state.length,
    );
    await _commit([...state, group]);
    return group;
  }

  Future<void> rename(String id, String name) => _commit([
        for (final g in state)
          if (g.id == id) g.copyWith(name: name.trim()) else g,
      ]);

  Future<void> delete(String id) =>
      _commit([for (final g in state) if (g.id != id) g]);

  Future<void> reorder(List<String> orderedIds) => _commit([
        for (final g in state)
          g.copyWith(order: orderedIds.indexOf(g.id)),
      ]);

  /// Wholesale replace, used when restoring a backup.
  Future<void> replaceAll(List<EventGroup> groups) => _commit([...groups]);
}

final groupsProvider =
    NotifierProvider<GroupsNotifier, List<EventGroup>>(GroupsNotifier.new);

/// The display name for a group id, or null when the id is null / unknown.
final groupNameProvider = Provider.family<String?, String?>((ref, id) {
  if (id == null) return null;
  for (final g in ref.watch(groupsProvider)) {
    if (g.id == id) return g.name;
  }
  return null;
});
