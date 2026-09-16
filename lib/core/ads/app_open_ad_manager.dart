import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pos_billing/core/ads/mobile_ads_init.dart';
import 'package:pos_billing/core/constants/ads_config.dart';
import 'package:pos_billing/core/services/app_log_service.dart';

/// Loads and shows AdMob app open ads (cold start + return to foreground).
class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  /// App open ads expire after ~4 hours.
  static const maxCacheDuration = Duration(hours: 4);

  AppOpenAd? _ad;
  DateTime? _loadTime;
  bool _isShowing = false;
  bool _isLoading = false;
  bool _resumeListening = false;
  StreamSubscription<AppState>? _appStateSub;

  bool get isAdAvailable => _ad != null;

  /// Preload an ad. Safe to call multiple times.
  Future<void> loadAd() async {
    if (_isLoading || isAdAvailable) return;
    _isLoading = true;
    try {
      await ensureMobileAdsInitialized();
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        debugPrint('App open skipped: MobileAds not initialized ($e)');
      }
      return;
    }

    try {
      await AppOpenAd.load(
        adUnitId: AdsConfig.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loadTime = DateTime.now();
            _isLoading = false;
            if (kDebugMode) {
              debugPrint('AppOpenAd loaded (${AdsConfig.appOpenAdUnitId})');
            }
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            unawaited(
              AppLogService.warn(
                'App open ad failed (${AdsConfig.appOpenAdUnitId}): '
                '${error.code} ${error.message}',
              ),
            );
            if (kDebugMode) {
              debugPrint(
                'AppOpenAd failed: ${error.code} ${error.message} '
                '(unit=${AdsConfig.appOpenAdUnitId})',
              );
            }
          },
        ),
      );
    } catch (e, st) {
      _isLoading = false;
      unawaited(AppLogService.warn('AppOpenAd.load threw: $e'));
      if (kDebugMode) {
        debugPrint('AppOpenAd.load threw: $e\n$st');
      }
    }
  }

  /// Shows a cached ad if available. Optionally waits briefly for a load.
  ///
  /// Returns once the ad is dismissed, fails to show, or [waitForLoad] elapses
  /// with no ad ready (so splash/navigation is never blocked indefinitely).
  Future<void> showAdIfAvailable({Duration? waitForLoad}) async {
    if (_isShowing) return;

    if (!isAdAvailable && waitForLoad != null) {
      await loadAd();
      final deadline = DateTime.now().add(waitForLoad);
      while (!isAdAvailable && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!isAdAvailable) {
      unawaited(loadAd());
      return;
    }

    final loadTime = _loadTime;
    if (loadTime != null &&
        DateTime.now().difference(loadTime) > maxCacheDuration) {
      _ad?.dispose();
      _ad = null;
      _loadTime = null;
      unawaited(loadAd());
      return;
    }

    final ad = _ad!;
    final dismissed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowing = true;
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        _isShowing = false;
        shown.dispose();
        if (identical(_ad, shown)) {
          _ad = null;
          _loadTime = null;
        }
        unawaited(loadAd());
        if (!dismissed.isCompleted) dismissed.complete();
        if (kDebugMode) {
          debugPrint('AppOpenAd failed to show: $error');
        }
      },
      onAdDismissedFullScreenContent: (shown) {
        _isShowing = false;
        shown.dispose();
        if (identical(_ad, shown)) {
          _ad = null;
          _loadTime = null;
        }
        unawaited(loadAd());
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show();
      await dismissed.future;
    } catch (e) {
      _isShowing = false;
      ad.dispose();
      if (identical(_ad, ad)) {
        _ad = null;
        _loadTime = null;
      }
      unawaited(loadAd());
      if (!dismissed.isCompleted) dismissed.complete();
      if (kDebugMode) {
        debugPrint('AppOpenAd.show threw: $e');
      }
    }
  }

  /// Start showing ads when the user returns from background.
  /// Call after cold-start splash so the first open is not double-shown.
  void startListeningForResume() {
    if (_resumeListening) return;
    _resumeListening = true;
    unawaited(AppStateEventNotifier.startListening());
    _appStateSub = AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) {
        unawaited(showAdIfAvailable());
      }
    });
  }

  void dispose() {
    unawaited(_appStateSub?.cancel());
    _appStateSub = null;
    _ad?.dispose();
    _ad = null;
    _loadTime = null;
    _isShowing = false;
    _isLoading = false;
    _resumeListening = false;
  }
}
