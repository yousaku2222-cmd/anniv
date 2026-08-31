import 'package:flutter/material.dart';

/// A named set of icons for the picker in the "見た目" step.
@immutable
class EventIconGroup {
  const EventIconGroup(this.label, this.icons);
  final String label;
  final List<IconData> icons;
}

/// Curated icons a user can pick to override an event's template icon
/// ([Event.iconCodePoint]). Every entry is a real `Icons.*` const, so the
/// release build's icon tree-shaker keeps these glyphs.
class EventIcons {
  const EventIcons._();

  static const List<EventIconGroup> groups = [
    EventIconGroup('記念日・お祝い', [
      Icons.favorite,
      Icons.favorite_border,
      Icons.cake,
      Icons.celebration,
      Icons.card_giftcard,
      Icons.redeem,
      Icons.local_florist,
      Icons.emoji_events,
      Icons.diamond,
      Icons.auto_awesome,
      Icons.star,
      Icons.star_border,
    ]),
    EventIconGroup('人・くらし', [
      Icons.person,
      Icons.family_restroom,
      Icons.child_friendly,
      Icons.pregnant_woman,
      Icons.pets,
      Icons.home,
      Icons.school,
      Icons.work,
      Icons.savings,
      Icons.elderly,
      Icons.groups,
      Icons.volunteer_activism,
    ]),
    EventIconGroup('おでかけ', [
      Icons.flight_takeoff,
      Icons.train,
      Icons.directions_car,
      Icons.directions_bus,
      Icons.directions_boat,
      Icons.beach_access,
      Icons.hiking,
      Icons.hotel,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.map,
      Icons.festival,
    ]),
    EventIconGroup('趣味・推し活', [
      Icons.music_note,
      Icons.mic,
      Icons.headphones,
      Icons.sports_esports,
      Icons.movie,
      Icons.theaters,
      Icons.camera_alt,
      Icons.palette,
      Icons.sports_soccer,
      Icons.sports_baseball,
      Icons.fitness_center,
      Icons.menu_book,
    ]),
    EventIconGroup('季節・自然', [
      Icons.wb_sunny,
      Icons.nightlight_round,
      Icons.ac_unit,
      Icons.local_fire_department,
      Icons.park,
      Icons.water_drop,
      Icons.umbrella,
      Icons.cloud,
      Icons.thunderstorm,
      Icons.spa,
      Icons.forest,
      Icons.filter_vintage,
    ]),
    EventIconGroup('しるし', [
      Icons.check_circle,
      Icons.flag,
      Icons.push_pin,
      Icons.bookmark,
      Icons.alarm,
      Icons.event,
      Icons.schedule,
      Icons.priority_high,
      Icons.warning_amber,
      Icons.info,
      Icons.hourglass_bottom,
      Icons.timer,
    ]),
  ];

  static final Map<int, IconData> _byCode = {
    for (final g in groups)
      for (final i in g.icons) i.codePoint: i,
  };

  /// The kept `Icons.*` const for a stored codepoint, or null if it isn't one
  /// of the curated icons (e.g. an old backup) — callers fall back to the
  /// template icon.
  static IconData? byCodePoint(int codePoint) => _byCode[codePoint];
}
