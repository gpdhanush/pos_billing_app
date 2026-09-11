import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      details: kDebugMode && stack != null ? stack.toString() : null,
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
      // Widget-tree failures are rendered by [ErrorWidget.builder].
      // Uncaught async/zone failures use [appCrashNotifier].
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught error: $error\n$stack');
        return false;
      }
      appCrashNotifier.value = AppCrashInfo.fromObject(error, stack);
      return true;
    };

    ErrorWidget.builder = (details) {
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
            child: AppErrorPage(
              title: 'Something went wrong',
              message: info.message,
            ),
          ),
        ),
      );
    };
  }

  static void clear() => appCrashNotifier.value = null;
}

/// Modern recovery UI used for production widget/zone failures.
class AppErrorPage extends StatelessWidget {
  const AppErrorPage({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.onGoHome,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final friendly = _friendlyMessage(message);

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
                    title,
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
                  if (message != null &&
                      message!.trim().isNotEmpty &&
                      message!.trim() != friendly) ...[
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
                        message!,
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
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                  if (onGoHome != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onGoHome,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Go to home'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'The app hit an unexpected problem. You can try again or return home.';
    }
    final lower = raw.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup')) {
      return 'Network issue detected. Check your connection and try again.';
    }
    if (lower.contains('database') ||
        lower.contains('sqlite') ||
        lower.contains('sql')) {
      return 'Something went wrong while reading local data. Try again.';
    }
    if (lower.contains('permission')) {
      return 'A required permission is missing. Update permissions and retry.';
    }
    return 'The app hit an unexpected problem. You can try again or return home.';
  }
}
