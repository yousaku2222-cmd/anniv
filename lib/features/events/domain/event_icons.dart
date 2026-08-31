import 'package:flutter/material.dart';

/// Which visual style the icon picker is showing.
enum IconStyle { filled, outline }

/// A named set of icons for one section of the picker.
@immutable
class EventIconGroup {
  const EventIconGroup(this.label, this.icons);
  final String label;
  final List<IconData> icons;
}

/// Curated icons a user can pick to override an event's template icon
/// ([Event.iconCodePoint]). Every entry is a real `Icons.*` const, so the
/// release build's icon tree-shaker keeps these glyphs.
///
/// [filled] ("シンプル") and [outline] ("ライン") are independent sets.
class EventIcons {
  const EventIcons._();

  static const List<EventIconGroup> filled = [
    EventIconGroup('記念日・お祝い', [
      Icons.favorite,
      Icons.cake,
      Icons.celebration,
      Icons.card_giftcard,
      Icons.redeem,
      Icons.local_florist,
      Icons.emoji_events,
      Icons.diamond,
      Icons.auto_awesome,
      Icons.star,
    ]),
    EventIconGroup('人・くらし', [
      Icons.favorite_border,
      Icons.person,
      Icons.family_restroom,
      Icons.child_friendly,
      Icons.pregnant_woman,
      Icons.pets,
      Icons.home,
      Icons.school,
      Icons.work,
      Icons.savings,
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
    ]),
    EventIconGroup('しるし', [
      Icons.check_circle,
      Icons.flag,
      Icons.push_pin,
      Icons.bookmark,
      Icons.alarm,
      Icons.event,
      Icons.priority_high,
      Icons.warning_amber,
      Icons.info,
      Icons.timer,
    ]),
  ];

  static const List<EventIconGroup> outline = [
    EventIconGroup('記念日・お祝い', [
      Icons.favorite_border,
      Icons.cake_outlined,
      Icons.celebration_outlined,
      Icons.local_florist_outlined,
      Icons.emoji_events_outlined,
      Icons.diamond_outlined,
      Icons.auto_awesome_outlined,
      Icons.star_border,
      Icons.stars_outlined,
      Icons.workspace_premium_outlined,
    ]),
    EventIconGroup('人・くらし', [
      Icons.person_outline,
      Icons.groups_outlined,
      Icons.child_friendly_outlined,
      Icons.pets_outlined,
      Icons.home_outlined,
      Icons.school_outlined,
      Icons.work_outline,
      Icons.savings_outlined,
      Icons.volunteer_activism_outlined,
      Icons.handshake_outlined,
    ]),
    EventIconGroup('おでかけ', [
      Icons.flight,
      Icons.train_outlined,
      Icons.directions_car_outlined,
      Icons.directions_bus_outlined,
      Icons.directions_boat_outlined,
      Icons.beach_access_outlined,
      Icons.hotel_outlined,
      Icons.restaurant_outlined,
      Icons.local_cafe_outlined,
      Icons.map_outlined,
    ]),
    EventIconGroup('趣味・推し活', [
      Icons.music_note_outlined,
      Icons.mic_none,
      Icons.headphones_outlined,
      Icons.sports_esports_outlined,
      Icons.movie_outlined,
      Icons.camera_alt_outlined,
      Icons.palette_outlined,
      Icons.sports_soccer_outlined,
      Icons.menu_book_outlined,
      Icons.brush_outlined,
    ]),
    EventIconGroup('季節・自然', [
      Icons.wb_sunny_outlined,
      Icons.nightlight_outlined,
      Icons.local_fire_department_outlined,
      Icons.park_outlined,
      Icons.water_drop_outlined,
      Icons.umbrella_outlined,
      Icons.cloud_outlined,
      Icons.thunderstorm_outlined,
      Icons.spa_outlined,
      Icons.eco_outlined,
    ]),
    EventIconGroup('しるし', [
      Icons.check_circle_outline,
      Icons.flag_outlined,
      Icons.push_pin_outlined,
      Icons.bookmark_border,
      Icons.access_alarm,
      Icons.event_outlined,
      Icons.error_outline,
      Icons.info_outline,
      Icons.hourglass_empty,
      Icons.timer_outlined,
    ]),
  ];

  static List<EventIconGroup> groupsFor(IconStyle style) =>
      style == IconStyle.filled ? filled : outline;

  static final Map<int, IconData> _byCode = {
    for (final list in [filled, outline])
      for (final g in list)
        for (final i in g.icons) i.codePoint: i,
  };

  /// The kept `Icons.*` const for a stored codepoint, or null if it isn't one
  /// of the curated icons (e.g. an old backup) — callers fall back to the
  /// template icon.
  static IconData? byCodePoint(int codePoint) => _byCode[codePoint];
}
