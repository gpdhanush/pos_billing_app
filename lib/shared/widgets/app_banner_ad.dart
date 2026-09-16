import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pos_billing/core/ads/mobile_ads_init.dart';
import 'package:pos_billing/core/constants/ads_config.dart';
import 'package:pos_billing/core/services/app_log_service.dart';

/// Adaptive banner. Hidden until an ad loads so layout does not jump empty.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _loadedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _loadedWidth) return;
    _loadedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load(width);
    });
  }

  Future<void> _load(int width) async {
    if (!mounted) return;
    final orientation = MediaQuery.orientationOf(context);

    _ad?.dispose();
    _ad = null;
    if (_loaded) {
      setState(() => _loaded = false);
    }

    try {
      await ensureMobileAdsInitialized();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Banner skipped: MobileAds not initialized ($e)');
      }
      return;
    }
    if (!mounted) return;

    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      orientation,
      width,
    );
    if (!mounted || size == null) return;

    final ad = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          unawaited(
            AppLogService.warn(
              'Banner ad failed (${AdsConfig.bannerAdUnitId}): '
              '${error.code} ${error.message}',
            ),
          );
          if (kDebugMode) {
            debugPrint(
              'Banner ad failed: ${error.code} ${error.message} '
              '(domain=${error.domain}, unit=${AdsConfig.bannerAdUnitId}). '
              'Ensure android/local.properties admobAppId matches '
              'ADMOB_ANDROID_APP_ID in .env.',
            );
          }
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    final h = ad.size.height.toDouble();
    return SizedBox(
      width: double.infinity,
      height: h,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: h,
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
