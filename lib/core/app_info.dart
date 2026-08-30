/// App-wide constants surfaced in the UI (About / legal).
class AppInfo {
  const AppInfo._();

  static const String appName = 'Anniv';
  static const String version = '1.0.0';
  static const String legalese = '© 2026';
  static const String contactEmail = 'yousaku2222@gmail.com';

  /// Hosted copy of docs/privacy-policy.html. Update this once the page is
  /// published (GitHub Pages, the developer's blog, etc.) and use the same URL
  /// in the App Store / Google Play listings.
  static const String privacyPolicyUrl =
      'https://yousaku2222-cmd.github.io/anniv/privacy-policy.html';
}
