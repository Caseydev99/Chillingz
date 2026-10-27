import 'package:flutter/foundation.dart';

/// OAuth client IDs for "Continue with Google".
///
/// These come from the Firebase console once Google is enabled under
/// Authentication > Sign-in method, and stay `null` until then. While a
/// platform's ID is missing the Google button is hidden on that platform, so
/// users never see a sign-in option that can't work.
///
/// * [webClientId]: the "Web client ID" shown on the Google provider page
///   (also the `client_type: 3` entry in a re-downloaded
///   `android/app/google-services.json`). Android needs it as the server
///   client ID.
/// * [iosClientId]: `CLIENT_ID` from a re-downloaded `GoogleService-Info.plist`.
///   Its `REVERSED_CLIENT_ID` must also replace the placeholder URL scheme in
///   `ios/Runner/Info.plist`.
class GoogleSignInConfig {
  const GoogleSignInConfig._();

  static const String? webClientId = null;
  static const String? iosClientId = null;

  /// Whether Google sign-in can work on the current platform.
  static bool get isAvailable {
    // The web build signs in through a Firebase pop-up, which needs no IDs.
    if (kIsWeb) {
      return true;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return webClientId != null;
      case TargetPlatform.iOS:
        return iosClientId != null;
      default:
        return false;
    }
  }
}
