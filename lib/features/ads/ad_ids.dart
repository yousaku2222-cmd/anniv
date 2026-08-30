import 'dart:io';

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
  static const bool useTestAds = false;

  /// Devices that should always receive test ads. The per-install hash changes
  /// on every reinstall, so prefer registering your daily phone in the AdMob
  /// console (Settings > Test devices). Add an id here only for a stable build.
  static const List<String> testDeviceIds = [];

  // Google's always-available test banner units.
  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner =
      'ca-app-pub-3940256099942544/2934735716';

  // Real AdMob banner units (app: Anniv).
  static const String _androidBanner =
      'ca-app-pub-3818461038959537/3625912019';
  static const String _iosBanner = 'ca-app-pub-3818461038959537/8690913737';

  static String get bannerUnitId {
    if (Platform.isIOS) return useTestAds ? _iosTestBanner : _iosBanner;
    return useTestAds ? _androidTestBanner : _androidBanner;
  }
}
