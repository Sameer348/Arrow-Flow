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
    try {
      // 1. Ask Google whether a form is needed. Only this network step has a
      //    short timeout, so a slow connection can't hold up the game.
      final info = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!info.isCompleted) info.complete(true);
        },
        (FormError e) {
          debugPrint('Consent update failed: ${e.message}');
          if (!info.isCompleted) info.complete(false);
        },
      );
      final updated = await info.future.timeout(const Duration(seconds: 10), onTimeout: () => false);

      // 2. Show the form (GDPR / US states / Apple tracking explainer) and
      //    wait for the player to finish it. No short timeout here: reading
      //    the form takes as long as it takes.
      if (updated) {
        final form = Completer<void>();
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
          if (e != null) debugPrint('Consent form: ${e.message}');
          if (!form.isCompleted) form.complete();
        });
        await form.future.timeout(const Duration(minutes: 10), onTimeout: () {});
      }
      // Previously stored consent still counts if the update timed out.
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
