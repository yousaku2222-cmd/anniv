import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Whether custom icons can be applied without watching an ad — either the user
/// already unlocked it (watched once) or bought "remove ads".
final iconChangeUnlockedProvider = Provider<bool>((ref) {
  final s = ref.watch(settingsProvider);
  return s.iconChangeUnlocked || s.adRemoved;
});
