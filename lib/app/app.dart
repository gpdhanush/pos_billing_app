import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/router/app_router.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/errors/app_error_handler.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final accent = AccentOptionX.fromStorage(settings.accent);
    final themeMode = switch (settings.themeModeName) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final router = ref.watch(routerProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(accent.seed),
      darkTheme: AppTheme.dark(accent.seed),
      themeMode: themeMode,
      locale: Locale(settings.localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return ValueListenableBuilder<AppCrashInfo?>(
          valueListenable: appCrashNotifier,
          builder: (context, crash, _) {
            if (crash != null) {
              return AppErrorPage(
                title: 'Something went wrong',
                message: crash.message,
                onRetry: () => AppErrorHandler.clear(),
                onGoHome: () {
                  AppErrorHandler.clear();
                  router.go('/home');
                },
              );
            }
            return KeyboardDismissOnTap(
              child: Column(
                children: [
                  if (!online)
                    Material(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context).commonOffline} — ${AppLocalizations.of(context).commonOfflineHint}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
