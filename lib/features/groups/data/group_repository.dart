import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/event_group.dart';

abstract class GroupRepository {
  List<EventGroup> loadAll();
  Future<void> saveAll(List<EventGroup> groups);
}

class SharedPrefsGroupRepository implements GroupRepository {
  SharedPrefsGroupRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'anniv.groups.v1';

  @override
  List<EventGroup> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return (decoded
        .map((e) => EventGroup.fromJson(e as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order)));
  }

  @override
  Future<void> saveAll(List<EventGroup> groups) {
    final encoded = jsonEncode(groups.map((g) => g.toJson()).toList());
    return _prefs.setString(_key, encoded);
  }
}

class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository([List<EventGroup> seed = const []])
      : _groups = [...seed];

  List<EventGroup> _groups;

  @override
  List<EventGroup> loadAll() =>
      List.unmodifiable(_groups..sort((a, b) => a.order.compareTo(b.order)));

  @override
  Future<void> saveAll(List<EventGroup> groups) async {
    _groups = [...groups];
  }
}
