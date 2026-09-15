import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google AdMob IDs. Defaults are Google's public sample/test units.
/// Replace with your own IDs in `.env` (see `.env.example`).
class AdsConfig {
  static const googleSampleAndroidAppId =
      'ca-app-pub-9764087765210503~7220892692';
  static const googleSampleBannerAdUnit =
      'ca-app-pub-9764087765210503/9852951589';

  static String get androidAppId {
    final v = dotenv.maybeGet('ADMOB_ANDROID_APP_ID')?.trim();
    if (v == null || v.isEmpty) return googleSampleAndroidAppId;
    return v;
  }

  static String get bannerAdUnitId {
    final v = dotenv.maybeGet('ADMOB_BANNER_AD_UNIT_ID')?.trim();
    if (v == null || v.isEmpty) return googleSampleBannerAdUnit;
    return v;
  }
}
