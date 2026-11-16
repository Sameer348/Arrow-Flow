import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App Tracking Transparency (iOS 14.5+). Asks once whether ads may use the
/// device's advertising ID. Android and other platforms: no-op.
class TrackingService {
  static const _channel = MethodChannel('arrow_flow/tracking');

  /// Shows Apple's tracking prompt if the user hasn't answered yet.
  /// Returns the resulting status; never throws.
  Future<String> requestIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return 'unsupported';
    try {
      return await _channel.invokeMethod<String>('request') ?? 'notDetermined';
    } on Object catch (e) {
      debugPrint('Tracking prompt unavailable: $e');
      return 'notDetermined';
    }
  }
}
