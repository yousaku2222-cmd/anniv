import 'package:flutter/material.dart';

import 'countdown.dart';
import 'event.dart';

/// A starting point for a new event: picking one pre-fills the icon, colour,
/// count mode, repeat rule and notification set so creation is a few taps.
@immutable
class EventTemplate {
  const EventTemplate({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.defaultRepeat,
    required this.defaultCountMode,
    required this.defaultNotificationOffsets,
    this.seedsMilestones = false,
  });

  final EventType type;
  final String label;
  final IconData icon;
  final Color color;
  final RepeatRule defaultRepeat;
  final CountMode defaultCountMode;
  final List<int> defaultNotificationOffsets;

  /// Whether to pre-populate [Countdown.defaultMilestones].
  final bool seedsMilestones;

  List<NotificationRule> buildNotifications() => defaultNotificationOffsets
      .map((o) => NotificationRule(offsetDays: o))
      .toList();

  List<int> buildMilestones() =>
      seedsMilestones ? const [...Countdown.defaultMilestones] : const [];

  static const List<EventTemplate> all = [
    EventTemplate(
      type: EventType.birthday,
      label: '誕生日',
      icon: Icons.cake_outlined,
      color: Color(0xFF8A3D63),
      defaultRepeat: RepeatRule.yearly,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 1, 7],
    ),
    EventTemplate(
      type: EventType.anniversary,
      label: '記念日',
      icon: Icons.favorite_border,
      color: Color(0xFFC0504D),
      defaultRepeat: RepeatRule.yearly,
      defaultCountMode: CountMode.daysSince,
      defaultNotificationOffsets: [0, 3],
      seedsMilestones: true,
    ),
    EventTemplate(
      type: EventType.exam,
      label: '試験',
      icon: Icons.school_outlined,
      color: Color(0xFF3F6F8F),
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0, 1, 3, 7],
    ),
    EventTemplate(
      type: EventType.trip,
      label: '旅行',
      icon: Icons.flight_takeoff,
      color: Color(0xFF3F7D54),
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [1, 7],
    ),
    EventTemplate(
      type: EventType.custom,
      label: 'カスタム',
      icon: Icons.event_note_outlined,
      color: Color(0xFFC07D24),
      defaultRepeat: RepeatRule.none,
      defaultCountMode: CountMode.daysLeft,
      defaultNotificationOffsets: [0],
    ),
  ];

  static EventTemplate forType(EventType type) =>
      all.firstWhere((t) => t.type == type, orElse: () => all.last);
}

extension EventVisuals on Event {
  EventTemplate get template => EventTemplate.forType(type);

  // Custom per-event icons (iconCodePoint) aren't selectable in the UI yet;
  // until then the template icon is authoritative.
  IconData get displayIcon => template.icon;

  Color get displayColor =>
      colorValue != null ? Color(colorValue!) : template.color;
}
