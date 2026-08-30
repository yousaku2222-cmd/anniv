import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../data/ad_service.dart';

/// Bound in `main()` on mobile with [GoogleAdService].
final adServiceProvider = Provider<AdService>((ref) => const NoopAdService());

/// Whether a banner should currently be shown: not purchased away.
final adsEnabledProvider = Provider<bool>((ref) {
  return !ref.watch(settingsProvider.select((s) => s.adRemoved));
});
