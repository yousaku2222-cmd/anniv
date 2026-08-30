import 'dart:io';

/// AdMob unit IDs. Ships with Google's public **test** units so development and
/// CI never touch real inventory. Before a store release:
///   1. create the app + banner unit in the AdMob console,
///   2. paste the real IDs into `_androidBanner` / `_iosBanner`,
///   3. set [useTestAds] to `false`,
///   4. set the real App IDs in AndroidManifest.xml and ios/Runner/Info.plist.
/// See docs/STORE_SETUP.md.
class AdIds {
  const AdIds._();

  static const bool useTestAds = true;

  // Google's always-available test banner units.
  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner =
      'ca-app-pub-3940256099942544/2934735716';

  // Real AdMob banner units — fill before release.
  static const String _androidBanner = 'ca-app-pub-0000000000000000/0000000000';
  static const String _iosBanner = 'ca-app-pub-0000000000000000/0000000000';

  static String get bannerUnitId {
    if (Platform.isIOS) return useTestAds ? _iosTestBanner : _iosBanner;
    return useTestAds ? _androidTestBanner : _androidBanner;
  }
}
