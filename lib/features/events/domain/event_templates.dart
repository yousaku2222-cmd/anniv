import 'package:flutter/material.dart';

import 'event.dart';

/// A starting point for a new event: picking one pre-fills the icon, colour,
/// count mode, repeat rule and notification set so creation is a few taps.
///
/// Colours / icons / presets follow the Genspark mock spec (§3-2).
@immutable
class EventTemplate {
  const EventTemplate({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.defaultRepeat,
    required this.defaultCountMode,
    required this.defaultNotificationOffsets,
    this.milestonePreset = const [],
  });

  final EventType type;
  final String label;

  /// One-line helper shown under the label in the create grid.
  final String description;

  final IconData icon;
  final Color color;
  final RepeatRule defaultRepeat;
  final CountMode defaultCountMode;
  final List<int> defaultNotificationOffsets;

  /// Day-count milestones seeded on creation. For countdown events these read
  /// as "N日前"; for elapsed events as "N日目".
  final List<int> milestonePreset;

  List<NotificationRule> buildNotifications() => defaultNotificationOffsets
      .map((o) => NotificationRule(offsetDays: o))
      .toList();

  List<int> buildMilestones() => [...milestonePreset];

  static const List<EventTemplate> all = [
    EventTemplate(
      type: EventType.birthday,
      label: '誕生日',
      description: '毎年繰り返し。当日・3日前に通知',
      icon: Icons.cake_outlined,
      color: AnnivEventColors.birthday,
      defaultRepeat: RepeatRule.yearly,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 3],
    ),
    EventTemplate(
      type: EventType.anniversary,
      label: '記念日',
      description: '毎年繰り返し。当日・7日前に通知',
      icon: Icons.favorite_border,
      color: AnnivEventColors.anniversary,
      defaultRepeat: RepeatRule.yearly,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 7],
      milestonePreset: [7, 100],
    ),
    EventTemplate(
      type: EventType.exam,
      label: '試験・イベント',
      description: '単発。7・3・1日前に通知',
      icon: Icons.menu_book_outlined,
      color: AnnivEventColors.exam,
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [1, 3, 7],
      milestonePreset: [30, 7],
    ),
    EventTemplate(
      type: EventType.trip,
      label: '旅行・外出',
      description: '単発。当日に通知',
      icon: Icons.flight_takeoff,
      color: AnnivEventColors.trip,
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0],
      milestonePreset: [90, 30, 7],
    ),
    EventTemplate(
      type: EventType.oshi,
      label: '推し活',
      description: '単発・公開日など。自由に通知',
      icon: Icons.star_border_rounded,
      color: AnnivEventColors.oshi,
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 1, 3, 7],
    ),
    EventTemplate(
      type: EventType.custom,
      label: 'カスタム',
      description: 'すべて自由に設定できます',
      icon: Icons.auto_awesome_outlined,
      color: AnnivEventColors.custom,
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 1, 3, 7],
    ),
  ];

  static EventTemplate forType(EventType type) =>
      all.firstWhere((t) => t.type == type, orElse: () => all.last);
}

/// Per-type accent colours (mock §3-2). Same in light and dark.
class AnnivEventColors {
  const AnnivEventColors._();

  static const Color birthday = Color(0xFFF08FA8);
  static const Color anniversary = Color(0xFFE85D43);
  static const Color exam = Color(0xFF6E8BEF);
  static const Color trip = Color(0xFF43B582);
  static const Color oshi = Color(0xFF9B7BE8);
  static const Color custom = Color(0xFFF0B84C);

  static Color of(EventType type) => switch (type) {
        EventType.birthday => birthday,
        EventType.anniversary => anniversary,
        EventType.exam => exam,
        EventType.trip => trip,
        EventType.oshi => oshi,
        EventType.custom => custom,
      };
}

extension EventVisuals on Event {
  EventTemplate get template => EventTemplate.forType(type);

  // Custom per-event icons (iconCodePoint) aren't selectable in the UI yet;
  // until then the template icon is authoritative.
  IconData get displayIcon => template.icon;

  Color get displayColor =>
      colorValue != null ? Color(colorValue!) : template.color;
}
