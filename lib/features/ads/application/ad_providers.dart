import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/domain/event_icons.dart';
import '../../settings/application/settings_providers.dart';
import '../data/ad_service.dart';
import '../data/rewarded_ad_service.dart';

/// Bound in `main()` on mobile with [GoogleAdService].
final adServiceProvider = Provider<AdService>((ref) => const NoopAdService());

/// Bound in `main()` on mobile with [GoogleRewardedAdService].
final rewardedAdServiceProvider =
    Provider<RewardedAdService>((ref) => const NoopRewardedAdService());

/// Whether a banner should currently be shown: not purchased away.
final adsEnabledProvider = Provider<bool>((ref) {
  return !ref.watch(settingsProvider.select((s) => s.adRemoved));
});

/// Whether one specific custom icon can be applied without watching an ad —
/// either the user already unlocked that icon (watched once) or bought
/// "remove ads".
final iconUnlockedProvider = Provider.family<bool, int>((ref, codePoint) {
  final s = ref.watch(settingsProvider);
  return s.adRemoved || s.unlockedIconCodePoints.contains(codePoint);
});

/// Whether every icon in the picker's catalog has already been unlocked (so
/// the picker never needs to show a "watch an ad" prompt).
final allIconsUnlockedProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider);
  if (s.adRemoved) return true;
  return EventIcons.allCodePoints
      .every((cp) => s.unlockedIconCodePoints.contains(cp));
});
