import 'package:flutter/foundation.dart';

import '../../../core/time/day_time.dart';

enum AppThemeMode { system, light, dark }

/// Which day a week starts on, for weekly-repeat pickers and any calendar UI.
enum WeekStart { sunday, monday }

/// How the card shows its number by default (per-event overrides still win).
enum DisplayFormat { daysLeft, date }

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// App-wide preferences. Stored as a single record.
@immutable
class AppSettings {
  const AppSettings({
    this.defaultNotifyTime = DayTime.nineAm,
    this.weekStart = WeekStart.sunday,
    this.displayFormat = DisplayFormat.daysLeft,
    this.themeMode = AppThemeMode.system,
    this.adRemoved = false,
    this.unlockedIconCodePoints = const {},
    this.onboardingDone = false,
  });

  final DayTime defaultNotifyTime;
  final WeekStart weekStart;
  final DisplayFormat displayFormat;
  final AppThemeMode themeMode;

  /// True once the "remove ads" purchase is verified.
  final bool adRemoved;

  /// Custom event icon codepoints the user has individually unlocked by
  /// watching a rewarded ad for that icon.
  final Set<int> unlockedIconCodePoints;

  final bool onboardingDone;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    DayTime? defaultNotifyTime,
    WeekStart? weekStart,
    DisplayFormat? displayFormat,
    AppThemeMode? themeMode,
    bool? adRemoved,
    Set<int>? unlockedIconCodePoints,
    bool? onboardingDone,
  }) {
    return AppSettings(
      defaultNotifyTime: defaultNotifyTime ?? this.defaultNotifyTime,
      weekStart: weekStart ?? this.weekStart,
      displayFormat: displayFormat ?? this.displayFormat,
      themeMode: themeMode ?? this.themeMode,
      adRemoved: adRemoved ?? this.adRemoved,
      unlockedIconCodePoints:
          unlockedIconCodePoints ?? this.unlockedIconCodePoints,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultNotifyTime': defaultNotifyTime.format(),
        'weekStart': weekStart.name,
        'displayFormat': displayFormat.name,
        'themeMode': themeMode.name,
        'adRemoved': adRemoved,
        'unlockedIconCodePoints': unlockedIconCodePoints.toList(),
        'onboardingDone': onboardingDone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultNotifyTime:
            DayTime.parse(json['defaultNotifyTime'] as String? ?? '09:00'),
        weekStart: _enumByName(
            WeekStart.values, json['weekStart'] as String?, WeekStart.sunday),
        displayFormat: _enumByName(DisplayFormat.values,
            json['displayFormat'] as String?, DisplayFormat.daysLeft),
        themeMode: _enumByName(AppThemeMode.values,
            json['themeMode'] as String?, AppThemeMode.system),
        adRemoved: json['adRemoved'] as bool? ?? false,
        unlockedIconCodePoints: (json['unlockedIconCodePoints'] as List?)
                ?.map((e) => e as int)
                .toSet() ??
            const {},
        onboardingDone: json['onboardingDone'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.defaultNotifyTime == defaultNotifyTime &&
      other.weekStart == weekStart &&
      other.displayFormat == displayFormat &&
      other.themeMode == themeMode &&
      other.adRemoved == adRemoved &&
      setEquals(other.unlockedIconCodePoints, unlockedIconCodePoints) &&
      other.onboardingDone == onboardingDone;

  @override
  int get hashCode => Object.hash(
      defaultNotifyTime,
      weekStart,
      displayFormat,
      themeMode,
      adRemoved,
      Object.hashAllUnordered(unlockedIconCodePoints),
      onboardingDone);
}
