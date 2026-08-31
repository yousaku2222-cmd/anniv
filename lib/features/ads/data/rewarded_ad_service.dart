import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_ids.dart';
import 'ad_service.dart';

/// Shows a single rewarded ad and reports whether the user earned the reward.
/// Used to unlock the custom-icon picker (`AppSettings.iconChangeUnlocked`).
abstract class RewardedAdService {
  /// True once an ad is preloaded and ready to show instantly.
  bool get isReady;

  /// Start loading an ad for the next [showForReward] call. Safe to call often.
  void preload();

  /// Loads (if needed) and shows a rewarded ad. Completes with `true` only when
  /// the user watched enough to earn the reward; `false` on failure, no fill,
  /// or an early dismissal.
  Future<bool> showForReward();
}

class NoopRewardedAdService implements RewardedAdService {
  const NoopRewardedAdService();

  @override
  bool get isReady => false;

  @override
  void preload() {}

  @override
  Future<bool> showForReward() async => false;
}

class GoogleRewardedAdService implements RewardedAdService {
  GoogleRewardedAdService(this._ads);

  final AdService _ads;

  RewardedAd? _ad;
  bool _loading = false;

  @override
  bool get isReady => _ad != null;

  @override
  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    unawaited(_ads.init().then((_) {
      RewardedAd.load(
        adUnitId: AdIds.rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
          },
          onAdFailedToLoad: (err) {
            _ad = null;
            _loading = false;
            debugPrint('Anniv: rewarded ad failed to load: $err');
          },
        ),
      );
    }));
  }

  Future<void> _loadBlocking() {
    final done = Completer<void>();
    _loading = true;
    _ads.init().then((_) {
      RewardedAd.load(
        adUnitId: AdIds.rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (err) {
            _ad = null;
            _loading = false;
            debugPrint('Anniv: rewarded ad failed to load: $err');
            if (!done.isCompleted) done.complete();
          },
        ),
      );
    });
    return done.future;
  }

  @override
  Future<bool> showForReward() async {
    if (_ad == null) await _loadBlocking();
    final ad = _ad;
    if (ad == null) return false;
    _ad = null; // consumed either way

    final result = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
        preload(); // ready for next time
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        debugPrint('Anniv: rewarded ad failed to show: $err');
        if (!result.isCompleted) result.complete(false);
        preload();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) => earned = true,
    );
    return result.future;
  }
}
