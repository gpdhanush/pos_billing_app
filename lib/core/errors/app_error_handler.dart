import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/core/services/app_log_service.dart';

/// Holds the latest fatal/uncaught app error for a full-screen recovery UI.
final ValueNotifier<AppCrashInfo?> appCrashNotifier = ValueNotifier(null);

class AppCrashInfo {
  const AppCrashInfo({required this.message, this.details});

  final String message;
  final String? details;

  factory AppCrashInfo.fromObject(Object error, [StackTrace? stack]) {
    final raw = error.toString().trim();
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '');
    return AppCrashInfo(
      message: cleaned.isEmpty ? 'Unexpected error' : cleaned,
      details: stack?.toString(),
    );
  }

  factory AppCrashInfo.fromFlutter(FlutterErrorDetails details) {
    return AppCrashInfo.fromObject(
      details.exceptionAsString(),
      details.stack,
    );
  }
}

class AppErrorHandler {
  AppErrorHandler._();

  static void install() {
    FlutterError.onError = (details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
      }
      // Log all Flutter framework errors for later email diagnostics.
      AppLogService.crash(
        details.exceptionAsString(),
        details.stack,
        'FlutterError.onError',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught error: $error\n$stack');
      }
      AppLogService.crash(error, stack, 'PlatformDispatcher.onError');
      if (!kDebugMode) {
        appCrashNotifier.value = AppCrashInfo.fromObject(error, stack);
      }
      return true;
    };

    ErrorWidget.builder = (details) {
      AppLogService.crash(
        details.exceptionAsString(),
        details.stack,
        'ErrorWidget',
      );
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      final info = AppCrashInfo.fromFlutter(details);
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1F6B5C),
              surface: const Color(0xFFF7F5F2),
            ),
            useMaterial3: true,
          ),
          child: Material(
            color: const Color(0xFFF7F5F2),
            child: Localizations(
              locale: WidgetsBinding.instance.platformDispatcher.locale,
              delegates: AppLocalizations.localizationsDelegates,
              child: AppErrorPage(
                message: info.message,
              ),
            ),
          ),
        ),
      );
    };
  }

  static void clear() => appCrashNotifier.value = null;
}

/// Modern recovery UI used for production widget/zone failures.
class AppErrorPage extends StatefulWidget {
  const AppErrorPage({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoHome,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  @override
  State<AppErrorPage> createState() => _AppErrorPageState();
}

class _AppErrorPageState extends State<AppErrorPage> {
  bool _sending = false;

  Future<void> _sendLogs() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final ok = await AppLogService.sendLogsToSupport(
        userNote: widget.message,
      );
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Share pos_billing_crash.log — choose WhatsApp'
                : 'Unable to open log share',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final friendly = _friendlyMessage(l10n, widget.message);
    final pageTitle = widget.title ?? l10n.commonError;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.18),
                          scheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 42,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    pageTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    friendly,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.message != null &&
                      widget.message!.trim().isNotEmpty &&
                      widget.message!.trim() != friendly) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        widget.message!,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (widget.onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onRetry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.commonTryAgain),
                      ),
                    ),
                  if (widget.onGoHome != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onGoHome,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.commonGoHome),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sending ? null : _sendLogs,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bug_report_outlined),
                      label: Text(
                        _sending ? l10n.commonLoading : l10n.moreSendLogs,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.moreSendLogsSubtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyMessage(AppLocalizations l10n, String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return l10n.commonError;
    }
    final lower = raw.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup')) {
      return l10n.connectivityOfflineBody;
    }
    if (lower.contains('database') ||
        lower.contains('sqlite') ||
        lower.contains('sql')) {
      return l10n.errorsDatabase;
    }
    if (lower.contains('permission')) {
      return l10n.commonPermissionNeeded;
    }
    return l10n.commonError;
  }
}
