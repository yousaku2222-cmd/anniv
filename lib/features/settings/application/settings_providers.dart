import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SharedPrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsNotifier extends Notifier<AppSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() => _repo.load();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await _repo.save(state);
  }

  Future<void> completeOnboarding() =>
      update((s) => s.copyWith(onboardingDone: true));

  /// Replace all settings, used when restoring a backup. Onboarding stays done
  /// so the user isn't sent back to the intro.
  Future<void> replace(AppSettings settings) =>
      update((_) => settings.copyWith(onboardingDone: true));
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
