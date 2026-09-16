import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pos_billing/core/constants/ads_config.dart';
import 'package:pos_billing/core/services/app_log_service.dart';

Completer<void>? _initCompleter;

/// Ensures [MobileAds.instance.initialize] finished before loading any ad.
Future<void> ensureMobileAdsInitialized() async {
  if (_initCompleter != null) {
    return _initCompleter!.future;
  }
  _initCompleter = Completer<void>();

  try {
    final status = await MobileAds.instance.initialize();
    if (kDebugMode) {
      debugPrint(
        'MobileAds initialized (banner=${AdsConfig.bannerAdUnitId}, '
        'adapters=${status.adapterStatuses.keys.join(', ')})',
      );
    }
    _initCompleter!.complete();
  } catch (e, st) {
    unawaited(AppLogService.warn('MobileAds init failed: $e'));
    if (kDebugMode) {
      debugPrint('MobileAds init failed: $e\n$st');
    }
    _initCompleter!.completeError(e, st);
    _initCompleter = null;
    rethrow;
  }
}
