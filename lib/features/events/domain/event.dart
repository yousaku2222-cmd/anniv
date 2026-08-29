import 'package:flutter/foundation.dart';

import '../../../core/time/day_time.dart';

/// What kind of day this is. Chosen from a template; drives the default icon,
/// colour and notification preset.
enum EventType { birthday, anniversary, exam, trip, custom }

/// How the date recurs.
enum RepeatRule { none, yearly, monthly, weekly }

/// How the big number on the card reads.
enum CountMode {
  /// Days remaining until the next occurrence — "あと12日".
  daysLeft,

  /// Days elapsed since the target date — "365日".
  daysSince,
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// A single reminder: fired [offsetDays] before the occurrence, at [time].
/// `offsetDays == 0` means "on the day".
@immutable
class NotificationRule {
  const NotificationRule({required this.offsetDays, this.time = DayTime.nineAm});

  final int offsetDays;
  final DayTime time;

  static const List<int> presetOffsets = [0, 1, 3, 7];

  NotificationRule copyWith({int? offsetDays, DayTime? time}) => NotificationRule(
        offsetDays: offsetDays ?? this.offsetDays,
        time: time ?? this.time,
      );

  Map<String, dynamic> toJson() => {
        'offsetDays': offsetDays,
        'time': time.format(),
      };

  factory NotificationRule.fromJson(Map<String, dynamic> json) => NotificationRule(
        offsetDays: (json['offsetDays'] as num).toInt(),
        time: DayTime.parse(json['time'] as String? ?? '09:00'),
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationRule &&
      other.offsetDays == offsetDays &&
      other.time == time;

  @override
  int get hashCode => Object.hash(offsetDays, time);
}

/// A day the user is counting toward or from.
@immutable
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.type,
    required this.targetDate,
    this.isLunar = false,
    this.repeat = RepeatRule.none,
    this.countMode = CountMode.daysLeft,
    this.groupId,
    this.colorValue,
    this.iconCodePoint,
    this.backgroundImagePath,
    this.notifications = const [],
    this.milestones = const [],
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final EventType type;

  /// The anchor date. For repeating events this is the first occurrence; the
  /// next occurrence is derived (see `countdown.dart`).
  final DateTime targetDate;

  /// Target date is a lunar-calendar date (birthdays, memorial services).
  /// Conversion is not implemented yet — Sprint 2+.
  final bool isLunar;

  final RepeatRule repeat;
  final CountMode countMode;

  final String? groupId;

  /// ARGB colour override; null means "use the template colour".
  final int? colorValue;
  final int? iconCodePoint;
  final String? backgroundImagePath;

  final List<NotificationRule> notifications;

  /// Day-count milestones to celebrate, e.g. `[100, 200, 365]`.
  final List<int> milestones;

  /// Soft-deleted: hidden from the list but recoverable.
  final bool isHidden;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get repeats => repeat != RepeatRule.none;

  Event copyWith({
    String? title,
    EventType? type,
    DateTime? targetDate,
    bool? isLunar,
    RepeatRule? repeat,
    CountMode? countMode,
    String? Function()? groupId,
    int? Function()? colorValue,
    int? Function()? iconCodePoint,
    String? Function()? backgroundImagePath,
    List<NotificationRule>? notifications,
    List<int>? milestones,
    bool? isHidden,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetDate: targetDate ?? this.targetDate,
      isLunar: isLunar ?? this.isLunar,
      repeat: repeat ?? this.repeat,
      countMode: countMode ?? this.countMode,
      groupId: groupId != null ? groupId() : this.groupId,
      colorValue: colorValue != null ? colorValue() : this.colorValue,
      iconCodePoint: iconCodePoint != null ? iconCodePoint() : this.iconCodePoint,
      backgroundImagePath: backgroundImagePath != null
          ? backgroundImagePath()
          : this.backgroundImagePath,
      notifications: notifications ?? this.notifications,
      milestones: milestones ?? this.milestones,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'targetDate': targetDate.toIso8601String(),
        'isLunar': isLunar,
        'repeat': repeat.name,
        'countMode': countMode.name,
        'groupId': groupId,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'backgroundImagePath': backgroundImagePath,
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'milestones': milestones,
        'isHidden': isHidden,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        title: json['title'] as String,
        type: _enumByName(EventType.values, json['type'] as String?, EventType.custom),
        targetDate: DateTime.parse(json['targetDate'] as String),
        isLunar: json['isLunar'] as bool? ?? false,
        repeat: _enumByName(
            RepeatRule.values, json['repeat'] as String?, RepeatRule.none),
        countMode: _enumByName(
            CountMode.values, json['countMode'] as String?, CountMode.daysLeft),
        groupId: json['groupId'] as String?,
        colorValue: (json['colorValue'] as num?)?.toInt(),
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt(),
        backgroundImagePath: json['backgroundImagePath'] as String?,
        notifications: (json['notifications'] as List<dynamic>? ?? [])
            .map((e) => NotificationRule.fromJson(e as Map<String, dynamic>))
            .toList(),
        milestones: (json['milestones'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        isHidden: json['isHidden'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  bool operator ==(Object other) => other is Event && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}
