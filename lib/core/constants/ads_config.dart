import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google AdMob IDs. Defaults are Google's official demo/test units.
/// Replace with your own IDs in `.env` (see `.env.example`).
///
/// The Android **App ID** must match [android/local.properties] `admobAppId`
/// (manifest meta-data). The app-open unit ID here must belong to that same
/// AdMob app.
class AdsConfig {
  /// https://developers.google.com/admob/android/test-ads
  static const googleSampleAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const googleSampleAppOpenAdUnit =
      'ca-app-pub-3940256099942544/9257395921';

  static String get androidAppId {
    if (kDebugMode) return googleSampleAndroidAppId;
    final v = dotenv.maybeGet('ADMOB_ANDROID_APP_ID')?.trim();
    if (v == null || v.isEmpty) return googleSampleAndroidAppId;
    return v;
  }

  static String get appOpenAdUnitId {
    // Debug: always Google's demo units so unapproved AdMob accounts still work.
    if (kDebugMode) return googleSampleAppOpenAdUnit;
    final v = dotenv.maybeGet('ADMOB_APP_OPEN_AD_UNIT_ID')?.trim();
    if (v == null || v.isEmpty) return googleSampleAppOpenAdUnit;
    return v;
  }
}
