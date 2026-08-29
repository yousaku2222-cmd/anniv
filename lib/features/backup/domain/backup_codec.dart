import 'dart:convert';

import '../../events/domain/event.dart';
import '../../groups/domain/event_group.dart';
import '../../settings/domain/app_settings.dart';

/// A full snapshot of the user's data.
class BackupData {
  const BackupData({
    required this.events,
    required this.groups,
    required this.settings,
    required this.exportedAt,
  });

  final List<Event> events;
  final List<EventGroup> groups;
  final AppSettings settings;
  final DateTime exportedAt;
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Serialises [BackupData] to/from a versioned JSON string. Pure — no IO.
class BackupCodec {
  const BackupCodec._();

  static const String appId = 'anniv';
  static const int currentVersion = 1;

  static String encode(BackupData data) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'version': currentVersion,
      'exportedAt': data.exportedAt.toIso8601String(),
      'events': data.events.map((e) => e.toJson()).toList(),
      'groups': data.groups.map((g) => g.toJson()).toList(),
      'settings': data.settings.toJson(),
    });
  }

  static BackupData decode(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('JSON として読み取れませんでした');
    }
    if (parsed is! Map<String, dynamic>) {
      throw const BackupFormatException('バックアップの形式が正しくありません');
    }
    if (parsed['app'] != appId) {
      throw const BackupFormatException('Anniv のバックアップファイルではありません');
    }
    final version = (parsed['version'] as num?)?.toInt() ?? 0;
    if (version > currentVersion) {
      throw const BackupFormatException(
          'このバックアップは新しいバージョンのアプリで作成されています');
    }

    try {
      return BackupData(
        events: [
          for (final e in (parsed['events'] as List? ?? const []))
            Event.fromJson(e as Map<String, dynamic>),
        ],
        groups: [
          for (final g in (parsed['groups'] as List? ?? const []))
            EventGroup.fromJson(g as Map<String, dynamic>),
        ],
        settings: parsed['settings'] is Map<String, dynamic>
            ? AppSettings.fromJson(parsed['settings'] as Map<String, dynamic>)
            : AppSettings.defaults,
        exportedAt: DateTime.tryParse(parsed['exportedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      throw BackupFormatException('データを復元できませんでした（$e）');
    }
  }
}
