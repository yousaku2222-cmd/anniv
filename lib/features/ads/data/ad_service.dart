import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_ids.dart';

/// Owns one-time ad SDK setup: consent (UMP), iOS App Tracking Transparency,
/// and `MobileAds.initialize`. [init] is idempotent, so callers (e.g. the
/// banner widget) can `await` it before loading an ad.
abstract class AdService {
  Future<void> init();
  bool get isReady;
}

class NoopAdService implements AdService {
  const NoopAdService();

  @override
  Future<void> init() async {}

  @override
  bool get isReady => false;
}

class GoogleAdService implements AdService {
  bool _ready = false;
  Future<void>? _initFuture;

  @override
  bool get isReady => _ready;

  @override
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      // ATT must not be blocked on the UMP round-trip below: request it first
      // so a slow/stuck consent network call can never prevent the prompt
      // from appearing (App Store review flagged a build where it never did).
      // Both calls are also capped: the platform channel has been observed to
      // hang indefinitely on some OS versions without ever throwing, which
      // would otherwise leave ad init (and the banner) stuck forever.
      if (Platform.isIOS) {
        try {
          // Calling this before the app's window is fully active can make
          // iOS silently skip the prompt instead of showing it (observed
          // intermittently: same code, same reset device, no error either
          // way). initState() of the first banner runs right as the screen
          // is still transitioning in, so give it a beat to settle first.
          await Future<void>.delayed(const Duration(milliseconds: 500));
          final status = await AppTrackingTransparency
              .trackingAuthorizationStatus
              .timeout(const Duration(seconds: 5));
          if (status == TrackingStatus.notDetermined) {
            await AppTrackingTransparency.requestTrackingAuthorization()
                .timeout(const Duration(seconds: 60));
          }
        } on TimeoutException catch (e) {
          debugPrint('Anniv: ATT request timed out, continuing without it: $e');
        }
      }
      // Google's consent callbacks aren't guaranteed to fire promptly on a
      // slow network, so cap the wait and proceed without blocking ad init.
      await _requestConsent().timeout(const Duration(seconds: 8),
          onTimeout: () {});
      if (AdIds.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdIds.testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Anniv: ad init failed, ads disabled this session: $e');
      _initFuture = null; // allow a later retry
    }
  }

  /// Google UMP: shows the consent form only where required (EEA/UK). Elsewhere
  /// it resolves immediately.
  Future<void> _requestConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadAndShowConsentFormIfRequired((_) {
              if (!completer.isCompleted) completer.complete();
            });
          } else if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
