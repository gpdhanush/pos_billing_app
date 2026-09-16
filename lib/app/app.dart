import 'dart:async';

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
                title: AppLocalizations.of(context).commonError,
                message: crash.message,
                onRetry: () => AppErrorHandler.clear(),
                onGoHome: () {
                  AppErrorHandler.clear();
                  router.go('/home');
                },
              );
            }

            final content = child ?? const SizedBox.shrink();

            return KeyboardDismissOnTap(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: content),
                  if (!online)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 6,
                      right: 8,
                      child: const _OfflineBadge(),
                    ),
                  const Positioned.fill(
                    child: _ConnectivityToastHost(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Listens for online/offline changes and shows a floating toast alert.
class _ConnectivityToastHost extends ConsumerStatefulWidget {
  const _ConnectivityToastHost();

  @override
  ConsumerState<_ConnectivityToastHost> createState() =>
      _ConnectivityToastHostState();
}

class _ConnectivityToastHostState
    extends ConsumerState<_ConnectivityToastHost> {
  bool? _lastOnline;
  bool? _toastOnline;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showToast(bool online) {
    _hideTimer?.cancel();
    setState(() {
      _toastOnline = online;
      _visible = true;
    });
    _hideTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (prev, next) {
      final online = next.valueOrNull;
      if (online == null) return;

      // Skip the first emission so we don't toast on cold start.
      if (_lastOnline == null) {
        _lastOnline = online;
        return;
      }
      if (_lastOnline == online) return;
      _lastOnline = online;
      _showToast(online);
    });

    final online = _toastOnline;
    if (online == null) return const SizedBox.shrink();

    final top = MediaQuery.paddingOf(context).top;
    final color = online ? AppColors.success : AppColors.danger;
    final icon = online ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final l10n = AppLocalizations.of(context);
    final title =
        online ? l10n.connectivityBackOnline : l10n.connectivityOfflineTitle;
    final body = online
        ? l10n.connectivityBackOnlineBody
        : l10n.connectivityOfflineBody;

    return IgnorePointer(
      ignoring: !_visible,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, -1.2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: _visible ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, top + 10, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact red ribbon (debug-banner style) — does not push page headers down.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              l10n.commonOffline.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
