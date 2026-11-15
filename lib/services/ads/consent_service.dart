import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Privacy / consent abstraction, separate from game logic.
abstract class ConsentService {
  /// Gathers consent if required (e.g. GDPR). Resolves to whether ads may
  /// be requested. Never throws.
  Future<bool> gatherConsent();

  /// Whether the user must be offered a privacy options entry point.
  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

/// Google User Messaging Platform implementation.
class UmpConsentService implements ConsentService {
  @override
  Future<bool> gatherConsent() async {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
            if (e != null) debugPrint('Consent form: ${e.message}');
            if (!done.isCompleted) done.complete();
          });
        },
        (FormError e) {
          debugPrint('Consent update failed: ${e.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
      return await ConsentInformation.instance.canRequestAds();
    } on Object catch (e) {
      debugPrint('Consent unavailable: $e');
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {
        if (e != null) debugPrint('Privacy form: ${e.message}');
      });
    } on Object catch (e) {
      debugPrint('Privacy options unavailable: $e');
    }
  }
}

/// No-op consent for tests / unsupported platforms.
class NoConsentService implements ConsentService {
  @override
  Future<bool> gatherConsent() async => false;
  @override
  Future<bool> privacyOptionsRequired() async => false;
  @override
  Future<void> showPrivacyOptions() async {}
}
