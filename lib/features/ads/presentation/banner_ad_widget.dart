import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_ids.dart';
import '../application/ad_providers.dart';

/// An anchored adaptive banner shown at the bottom of a screen. Renders nothing
/// until an ad has loaded, and nothing at all once ads are purchased away.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(adsEnabledProvider)) {
      _load();
    }
  }

  Future<void> _load() async {
    final service = ref.read(adServiceProvider);
    await service.init();
    if (!mounted || !service.isReady) return;

    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdIds.bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reactively drop the banner the moment ads are purchased away.
    final enabled = ref.watch(adsEnabledProvider);
    if (!enabled) {
      _ad?.dispose();
      _ad = null;
      return const SizedBox.shrink();
    }
    if (_ad == null || !_loaded) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
