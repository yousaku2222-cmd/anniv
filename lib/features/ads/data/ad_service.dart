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
      await _requestConsent();
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
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
