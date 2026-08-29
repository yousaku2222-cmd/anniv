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

  GroupRepository get _repo => ref.read(groupRepositoryProvider);

  @override
  List<EventGroup> build() => _repo.loadAll();

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
}

final groupsProvider =
    NotifierProvider<GroupsNotifier, List<EventGroup>>(GroupsNotifier.new);
