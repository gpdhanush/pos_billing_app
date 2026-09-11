import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/sample_data.dart';
import 'package:pos_billing/core/services/app_permission_service.dart';

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
    if (_progress.status != AnimationStatus.completed) {
      await _progress.forward();
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final needsPermissions =
        !await const AppPermissionService().hasAllStartupPermissions();
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
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        size: 54,
                        color: scheme.onPrimary,
                      ),
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
                      const SizedBox(height: 14),
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
