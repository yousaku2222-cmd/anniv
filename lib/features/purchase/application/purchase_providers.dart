import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../settings/application/settings_providers.dart';
import '../purchase_ids.dart';

@immutable
class PurchaseState {
  const PurchaseState({
    this.storeAvailable = false,
    this.removeAdsProduct,
    this.pending = false,
    this.message,
  });

  /// The billing service is reachable.
  final bool storeAvailable;

  /// Loaded product (carries the localised price string), or null if not yet
  /// loaded / not found in the store.
  final ProductDetails? removeAdsProduct;

  /// A purchase or restore is in flight.
  final bool pending;

  /// One-shot text to surface to the user: a failure, or a plain notice such
  /// as a cancelled purchase. The UI shows it once and then clears it.
  final String? message;

  String get priceLabel => removeAdsProduct?.price ?? '';

  PurchaseState copyWith({
    bool? storeAvailable,
    ProductDetails? removeAdsProduct,
    bool? pending,
    String? Function()? message,
  }) {
    return PurchaseState(
      storeAvailable: storeAvailable ?? this.storeAvailable,
      removeAdsProduct: removeAdsProduct ?? this.removeAdsProduct,
      pending: pending ?? this.pending,
      message: message != null ? message() : this.message,
    );
  }
}

/// Whether ads have been purchased away (persisted in settings).
final adsRemovedProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.adRemoved)),
);

class PurchaseController extends Notifier<PurchaseState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  PurchaseState build() {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => debugPrint('Anniv: purchase stream error: $e'),
    );
    ref.onDispose(() => _sub?.cancel());
    unawaited(_bootstrap());
    return const PurchaseState();
  }

  Future<void> _bootstrap() async {
    try {
      final available = await _iap.isAvailable();
      state = state.copyWith(storeAvailable: available);
      if (!available) return;

      final resp = await _iap.queryProductDetails(PurchaseIds.all);
      for (final p in resp.productDetails) {
        if (p.id == PurchaseIds.removeAds) {
          state = state.copyWith(removeAdsProduct: p);
        }
      }
    } catch (e) {
      debugPrint('Anniv: IAP bootstrap failed: $e');
    }
  }

  /// Clears the one-shot [PurchaseState.message] after the UI has shown it.
  void clearMessage() {
    if (state.message != null) state = state.copyWith(message: () => null);
  }

  Future<void> buyRemoveAds() async {
    final product = state.removeAdsProduct;
    if (product == null) return;
    state = state.copyWith(pending: true, message: () => null);
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      state = state.copyWith(pending: false, message: () => '$e');
    }
    // Deliberately no timeout here. buyNonConsumable() only kicks the platform
    // purchase sheet off, and everything after that is the person's own pace:
    // on a device that is not signed in to an App Store account yet, iOS puts a
    // sign-in prompt in front of the sheet, which easily takes longer than any
    // timeout we could pick. A timeout fired mid-sheet used to drop `pending`
    // and show a bogus "timed out" error while the real sheet was still open —
    // App Review read that as the purchase never starting (Guideline 2.1(b),
    // 2026-10-02). StoreKit always reports back through purchaseStream
    // (purchased / restored / canceled / error), so `pending` is cleared there.
  }

  Future<void> restore() async {
    state = state.copyWith(pending: true, message: () => null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(pending: false, message: () => '$e');
      return;
    }
    // restorePurchases() only kicks the platform restore off — when there's
    // nothing to restore, purchaseStream never emits and _onPurchases never
    // runs, so nothing would ever clear `pending`. Give any restored purchases
    // a window to arrive, then stop waiting and say so. Unlike a purchase this
    // waits on the store rather than on the person, so a timeout is safe here.
    await Future<void>.delayed(const Duration(seconds: 12));
    if (state.pending) {
      state = state.copyWith(
          pending: false, message: () => '復元できる購入はありませんでした');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      if (pd.productID != PurchaseIds.removeAds) {
        if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
        continue;
      }
      switch (pd.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(pending: true);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await ref
              .read(settingsProvider.notifier)
              .update((s) => s.copyWith(adRemoved: true));
          state = state.copyWith(pending: false, message: () => null);
        case PurchaseStatus.error:
          state = state.copyWith(
              pending: false, message: () => pd.error?.message ?? '購入に失敗しました');
        case PurchaseStatus.canceled:
          state = state.copyWith(
              pending: false, message: () => '購入はキャンセルされました');
      }
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }
}

final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);
