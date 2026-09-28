import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Let flutter_local_notifications present alerts while the app is foregrounded.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    BuildChannel.register(with: engineBridge.pluginRegistry)
  }
}

/// Tells Dart whether this build came from TestFlight, so ads can switch to
/// Google's test units there (self-clicks got AdMob suspended on 2026-09-27).
/// The receipt name is instant and reliable on TestFlight; StoreKit 2 is the
/// non-deprecated check but can fail there, so it only runs as a second opinion.
enum BuildChannel {
  static var channel: FlutterMethodChannel?

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "BuildChannel") else { return }
    let channel = FlutterMethodChannel(
      name: "app/build_channel", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "isTestFlight" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        result(true)
        return
      }
      guard #available(iOS 16.0, *) else {
        result(false)
        return
      }
      Task {
        let sandbox: Bool
        switch try? await AppTransaction.shared {
        case .verified(let transaction)?, .unverified(let transaction, _)?:
          sandbox = transaction.environment == .sandbox
        case nil:
          sandbox = false
        }
        await MainActor.run { result(sandbox) }
      }
    }
    self.channel = channel
  }
}
