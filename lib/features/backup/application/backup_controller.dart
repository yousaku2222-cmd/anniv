import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../events/application/event_providers.dart';
import '../../groups/application/group_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/backup_codec.dart';

final backupControllerProvider =
    Provider<BackupController>(BackupController.new);

class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  BackupData _snapshot() => BackupData(
        events: _ref.read(eventsProvider),
        groups: _ref.read(groupsProvider),
        settings: _ref.read(settingsProvider),
        exportedAt: DateTime.now(),
      );

  String exportJson() => BackupCodec.encode(_snapshot());

  /// Writes the backup to a temp file and opens the share sheet.
  Future<void> shareBackup() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File('${dir.path}/anniv-backup-$stamp.json');
    await file.writeAsString(exportJson());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Anniv バックアップ',
      ),
    );
  }

  /// Replaces all local data with the contents of [source].
  /// Throws [BackupFormatException] if [source] can't be parsed.
  /// Returns the number of restored events.
  Future<int> restoreFromJson(String source) async {
    final data = BackupCodec.decode(source);
    await _ref.read(groupsProvider.notifier).replaceAll(data.groups);
    await _ref.read(eventsProvider.notifier).replaceAll(data.events);
    await _ref.read(settingsProvider.notifier).replace(data.settings);
    return data.events.length;
  }
}
