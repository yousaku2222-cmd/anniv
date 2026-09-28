import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Where this build was installed from, as reported by the iOS host
/// (AppDelegate.swift). Only TestFlight is detected; Android and App Store
/// installs leave [isTestFlight] false.
///
/// TestFlight builds are release builds, so without this they would request
/// real ads on our own devices -- self-clicks got the AdMob account suspended
/// on 2026-09-27.
class BuildChannel {
  const BuildChannel._();

  static const _channel = MethodChannel('app/build_channel');

  static bool isTestFlight = false;
  static Future<void>? _initFuture;

  /// Call once before the first ad request. Never throws; a slow or failed
  /// lookup leaves [isTestFlight] false.
  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    if (!Platform.isIOS) return;
    try {
      isTestFlight = await _channel
              .invokeMethod<bool>('isTestFlight')
              .timeout(const Duration(seconds: 3)) ??
          false;
    } catch (_) {}
  }
}
