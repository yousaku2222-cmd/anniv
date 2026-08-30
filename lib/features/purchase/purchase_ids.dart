/// In-app purchase product identifiers.
///
/// This exact id must be created as a **non-consumable managed product** in both
/// Google Play Console and App Store Connect. See docs/STORE_SETUP.md.
class PurchaseIds {
  const PurchaseIds._();

  static const String removeAds = 'anniv_remove_ads';

  static const Set<String> all = {removeAds};
}
