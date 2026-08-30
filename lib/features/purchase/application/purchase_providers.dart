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
    this.error,
  });

  /// The billing service is reachable.
  final bool storeAvailable;

  /// Loaded product (carries the localised price string), or null if not yet
  /// loaded / not found in the store.
  final ProductDetails? removeAdsProduct;

  /// A purchase or restore is in flight.
  final bool pending;
  final String? error;

  String get priceLabel => removeAdsProduct?.price ?? '';

  PurchaseState copyWith({
    bool? storeAvailable,
    ProductDetails? removeAdsProduct,
    bool? pending,
    String? Function()? error,
  }) {
    return PurchaseState(
      storeAvailable: storeAvailable ?? this.storeAvailable,
      removeAdsProduct: removeAdsProduct ?? this.removeAdsProduct,
      pending: pending ?? this.pending,
      error: error != null ? error() : this.error,
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

  Future<void> buyRemoveAds() async {
    final product = state.removeAdsProduct;
    if (product == null) return;
    state = state.copyWith(pending: true, error: () => null);
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      state = state.copyWith(pending: false, error: () => '$e');
    }
  }

  Future<void> restore() async {
    state = state.copyWith(pending: true, error: () => null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(pending: false, error: () => '$e');
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
          state = state.copyWith(pending: false, error: () => null);
        case PurchaseStatus.error:
          state = state.copyWith(
              pending: false, error: () => pd.error?.message ?? '購入に失敗しました');
        case PurchaseStatus.canceled:
          state = state.copyWith(pending: false);
      }
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }
}

final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);
