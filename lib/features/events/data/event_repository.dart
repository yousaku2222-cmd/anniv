import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/event.dart';

/// Persistence boundary for events.
///
/// Sprint 1 ships [SharedPrefsEventRepository] (whole list as one JSON blob),
/// which is fine for hundreds of events. Swapping in an Isar/Drift-backed
/// implementation later only touches this file and its provider.
abstract class EventRepository {
  List<Event> loadAll();
  Future<void> saveAll(List<Event> events);
}

class SharedPrefsEventRepository implements EventRepository {
  SharedPrefsEventRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'anniv.events.v1';

  @override
  List<Event> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Event> events) {
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    return _prefs.setString(_key, encoded);
  }
}

/// In-memory implementation for tests and previews.
class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository([List<Event> seed = const []]) : _events = [...seed];

  List<Event> _events;

  @override
  List<Event> loadAll() => List.unmodifiable(_events);

  @override
  Future<void> saveAll(List<Event> events) async {
    _events = [...events];
  }
}
