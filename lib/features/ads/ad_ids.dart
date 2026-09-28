import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'build_channel.dart';

/// AdMob unit IDs.
///
/// [useTestAds] swaps in Google's public test units for development. Even with
/// real IDs, the devices in [testDeviceIds] always get test ads.
///
/// App IDs (needed too) live in AndroidManifest.xml and ios/Runner/Info.plist.
/// See docs/STORE_SETUP.md.
class AdIds {
  const AdIds._();

  /// AdMob publisher: pub-3818461038959537
  ///
  /// While true, every install requests Google's official public test ad
  /// unit instead of the real one, so testers on unregistered devices see
  /// clearly-labeled test creatives instead of real (possibly no-fill) ads.
  ///
  /// Debug/profile runs always use test ads so our own development sessions
  /// never touch real inventory (self-clicks got the account suspended on
  /// 2026-09-27). Pass --dart-define=TEST_ADS=true to force them in release.
  static bool get useTestAds => _forceTestAds || BuildChannel.isTestFlight;
  static const bool _forceTestAds =
      !kReleaseMode || bool.fromEnvironment('TEST_ADS', defaultValue: false);

  /// Devices that should always receive test ads. The per-install hash changes
  /// on every reinstall, so prefer registering your daily phone in the AdMob
  /// console (Settings > Test devices). Add an id here only for a stable build.
  ///
  /// Release builds use real ids, so register your own daily-driver device(s)
  /// here (or in the AdMob console) before opening real ads yourself, or the
  /// impressions/clicks risk being flagged as invalid traffic.
  static const List<String> testDeviceIds = [
    '20535872D7F1C1AD800B618520C0A4F2', // Hi10_XPro tablet (Play release build)
  ];

  // Google's always-available test units.
  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidTestRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewarded =
      'ca-app-pub-3940256099942544/1712485313';

  // Real AdMob banner units (app: Anniv).
  static const String _androidBanner =
      'ca-app-pub-3818461038959537/3625912019';
  static const String _iosBanner = 'ca-app-pub-3818461038959537/8690913737';

  // Real AdMob rewarded units (app: Anniv). Create them in the AdMob console
  // (アプリ ▸ 広告ユニット ▸ リワード) and paste the ids here. While empty the
  // Google test rewarded unit is used even in release.
  static const String _androidRewarded =
      'ca-app-pub-3818461038959537/4309894560';
  static const String _iosRewarded = 'ca-app-pub-3818461038959537/5674841920';

  static String get bannerUnitId {
    if (Platform.isIOS) return useTestAds ? _iosTestBanner : _iosBanner;
    return useTestAds ? _androidTestBanner : _androidBanner;
  }

  static String get rewardedUnitId {
    if (Platform.isIOS) {
      return (useTestAds || _iosRewarded.isEmpty)
          ? _iosTestRewarded
          : _iosRewarded;
    }
    return (useTestAds || _androidRewarded.isEmpty)
        ? _androidTestRewarded
        : _androidRewarded;
  }
}
