import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/ads/app_open_ad_manager.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/sample_data.dart';
import 'package:pos_billing/core/services/app_log_service.dart';
import 'package:pos_billing/core/services/app_permission_service.dart';
import 'package:pos_billing/shared/widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    try {
      // Non-blocking: silent Google restore + analytics + backup coordinator.
      unawaited(ref.read(googleAuthServiceProvider).restoreSilently());
      unawaited(() async {
        try {
          final analytics = ref.read(analyticsServiceProvider);
          await analytics.logAppOpen();
          await analytics.flushQueuedTelemetry();
          await ref.read(notificationServiceProvider).refreshFcm();
        } catch (_) {}
      }());
      try {
        ref.read(backupCoordinatorProvider).start();
      } catch (_) {}

      final settings = await ref.read(appSettingsProvider.future);
      final store = await ref.read(storeProfileProvider.future);
      if (store != null) {
        await SampleDataSeeder(ref.read(databaseProvider)).seedIfNeeded(store.id);
      }
      // PIN lock removed — keep users unlocked unless biometric lock is on.
      if (settings.pinEnabled && !settings.biometricEnabled) {
        await ref.read(pinServiceProvider).clearPin();
        await ref.read(appSettingsProvider.notifier).setPinEnabled(false);
        ref.read(unlockedProvider.notifier).state = true;
      } else if (!settings.biometricEnabled) {
        ref.read(unlockedProvider.notifier).state = true;
      }
    } catch (e, st) {
      // Still leave splash so the user is not stuck on a blank/progress screen.
      unawaited(AppLogService.error(e, st, 'splash_bootstrap'));
      ref.read(unlockedProvider.notifier).state = true;
    }

    if (!mounted) return;
    if (_progress.status != AnimationStatus.completed) {
      await _progress.forward();
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    // Cold-start app open ad overlays the splash while assets finish loading.
    await AppOpenAdManager.instance.showAdIfAvailable(
      waitForLoad: const Duration(seconds: 2),
    );
    if (!mounted) return;

    // After first open, show again when returning from background.
    AppOpenAdManager.instance.startListeningForResume();

    var needsPermissions = false;
    try {
      needsPermissions =
          !await const AppPermissionService().hasAllStartupPermissions();
    } catch (_) {
      needsPermissions = false;
    }
    if (!mounted) return;
    context.go(needsPermissions ? '/permissions' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const AppLogo(size: 106, radius: 24),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final pct = (_progress.value.clamp(0.0, 1.0) * 100).round();
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress.value.clamp(0.08, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              scheme.onPrimary.withValues(alpha: 0.22),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$pct%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'v${DbConstants.appVersion}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
