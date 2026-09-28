import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_ids.dart';
import 'ad_service.dart';

/// Result of [RewardedAdService.showForReward].
enum RewardOutcome {
  /// The user watched enough to earn the reward.
  earned,

  /// The ad was shown but closed early, or failed to show.
  dismissed,

  /// No ad could be loaded (no fill, account paused). Core features let the
  /// user through anyway; cosmetic unlocks don't.
  unavailable,

  /// The load failed with a network error (airplane mode, no signal). Never
  /// let the user through, or going offline would become a free bypass.
  offline,
}

/// Shown when [RewardOutcome.offline] is returned.
const kAdOfflineMessage = '通信できません。インターネットに接続してからもう一度お試しください。';

/// `LoadAdError.code` for a network failure (same value on Android and iOS).
const _networkErrorCode = 2;

/// Shows a single rewarded ad and reports the outcome.
/// Used to unlock one custom icon at a time in the icon picker
/// (`AppSettings.unlockedIconCodePoints`), and one extra background colour at
/// a time in the event editor (`AppSettings.unlockedColorValues`).
abstract class RewardedAdService {
  /// True once an ad is preloaded and ready to show instantly.
  bool get isReady;

  /// Start loading an ad for the next [showForReward] call. Safe to call often.
  void preload();

  /// Loads (if needed) and shows a rewarded ad.
  Future<RewardOutcome> showForReward();
}

class NoopRewardedAdService implements RewardedAdService {
  const NoopRewardedAdService();

  @override
  bool get isReady => false;

  @override
  void preload() {}

  @override
  Future<RewardOutcome> showForReward() async => RewardOutcome.unavailable;
}

class GoogleRewardedAdService implements RewardedAdService {
  GoogleRewardedAdService(this._ads);

  final AdService _ads;

  RewardedAd? _ad;
  bool _loading = false;
  int? _loadErrorCode;

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
            _loadErrorCode = null;
          },
          onAdFailedToLoad: (err) {
            _ad = null;
            _loading = false;
            _loadErrorCode = err.code;
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
            _loadErrorCode = null;
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (err) {
            _ad = null;
            _loading = false;
            _loadErrorCode = err.code;
            debugPrint('Anniv: rewarded ad failed to load: $err');
            if (!done.isCompleted) done.complete();
          },
        ),
      );
    });
    return done.future;
  }

  @override
  Future<RewardOutcome> showForReward() async {
    if (_ad == null) await _loadBlocking();
    final ad = _ad;
    if (ad == null) {
      return _loadErrorCode == _networkErrorCode
          ? RewardOutcome.offline
          : RewardOutcome.unavailable;
    }
    _ad = null; // consumed either way

    final result = Completer<RewardOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(
              earned ? RewardOutcome.earned : RewardOutcome.dismissed);
        }
        preload(); // ready for next time
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        debugPrint('Anniv: rewarded ad failed to show: $err');
        if (!result.isCompleted) result.complete(RewardOutcome.dismissed);
        preload();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) => earned = true,
    );
    return result.future;
  }
}
