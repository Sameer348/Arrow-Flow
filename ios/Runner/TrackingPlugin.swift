import AppTrackingTransparency
import Flutter
import UIKit

/// Minimal App Tracking Transparency bridge (channel `arrow_flow/tracking`).
///
/// `request` shows Apple's "Allow tracking?" prompt once and returns the
/// status: authorized, denied, restricted or notDetermined. iOS ignores the
/// request unless the app is active, so it waits for that first.
final class TrackingPlugin: NSObject {
  private static var observer: NSObjectProtocol?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "arrow_flow/tracking", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        result(name(ATTrackingManager.trackingAuthorizationStatus))
      case "request":
        whenActive { request(result) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func request(_ result: @escaping FlutterResult) {
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
      result(name(ATTrackingManager.trackingAuthorizationStatus))
      return
    }
    ATTrackingManager.requestTrackingAuthorization { status in
      DispatchQueue.main.async { result(name(status)) }
    }
  }

  /// Runs `action` now if the app is active, otherwise once it becomes active.
  private static func whenActive(_ action: @escaping () -> Void) {
    DispatchQueue.main.async {
      if UIApplication.shared.applicationState == .active {
        // Small delay so the prompt doesn't collide with a dismissing form.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: action)
        return
      }
      observer = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
      ) { _ in
        if let o = observer { NotificationCenter.default.removeObserver(o) }
        observer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: action)
      }
    }
  }

  private static func name(_ s: ATTrackingManager.AuthorizationStatus) -> String {
    switch s {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "notDetermined"
    }
  }
}
