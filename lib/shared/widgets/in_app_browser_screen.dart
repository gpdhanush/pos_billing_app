import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Modern in-app browser used for Privacy Policy and similar pages.
class InAppBrowserScreen extends StatefulWidget {
  const InAppBrowserScreen({
    super.key,
    required this.url,
    this.title = 'Privacy Policy',
  });

  final String url;
  final String title;

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  late final Uri _uri;

  var _loading = true;
  var _progress = 0;
  var _failed = false;
  String? _pageTitle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uri = Uri.parse(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.panel)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() {
              _progress = value;
              _loading = value < 100;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _failed = false;
              _errorMessage = null;
              _progress = 0;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            final title = await _controller.getTitle();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _progress = 100;
              if (title != null && title.trim().isNotEmpty) {
                _pageTitle = title.trim();
              }
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // Ignore subframe / image errors; only fail the main document.
            if (error.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _failed = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(_uri);
  }

  Future<void> _reload() async {
    setState(() {
      _failed = false;
      _errorMessage = null;
      _loading = true;
      _progress = 0;
    });
    await _controller.reload();
  }

  Future<void> _openExternal() async {
    try {
      final ok = await launchUrl(_uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) showSnack(context, 'Unable to open in browser');
    } catch (_) {
      if (mounted) showSnack(context, 'Unable to open in browser');
    }
  }

  String get _hostLabel {
    final host = _uri.host;
    if (host.isEmpty) return widget.url;
    return host.replaceFirst(RegExp(r'^www\.'), '');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headline = _pageTitle?.isNotEmpty == true
        ? _pageTitle!
        : widget.title;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _BrowserHeader(
            title: headline,
            subtitle: _hostLabel,
            loading: _loading,
            progress: _progress,
            onBack: () => context.pop(),
            onRefresh: _reload,
            onOpenExternal: _openExternal,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.onSurface.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_failed)
                        WebViewWidget(controller: _controller)
                      else
                        _BrowserError(
                          message: _errorMessage,
                          onRetry: _reload,
                          onOpenExternal: _openExternal,
                        ),
                      if (_loading && !_failed)
                        ColoredBox(
                          color: scheme.surface.withValues(alpha: 0.72),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Loading… $_progress%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserHeader extends StatelessWidget {
  const _BrowserHeader({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.progress,
    required this.onBack,
    required this.onRefresh,
    required this.onOpenExternal,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final int progress;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, const Color(0xFF0B1220), 0.28)!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 6, 8, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _HeaderIconButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSecurityLock,
                            size: 12,
                            color: scheme.onPrimary.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: scheme.onPrimary
                                        .withValues(alpha: 0.82),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _HeaderIconButton(
                  icon: HugeIcons.strokeRoundedRefresh,
                  onPressed: onRefresh,
                ),
                _HeaderIconButton(
                  icon: HugeIcons.strokeRoundedLinkSquare02,
                  onPressed: onOpenExternal,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 3,
                value: loading ? (progress / 100).clamp(0.05, 1.0) : 1,
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(
                  scheme.onPrimary.withValues(alpha: loading ? 1 : 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onPrimary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _BrowserError extends StatelessWidget {
  const _BrowserError({
    required this.message,
    required this.onRetry,
    required this.onOpenExternal,
  });

  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCloudOff,
                  size: 32,
                  color: scheme.error,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load page',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message?.trim().isNotEmpty == true
                  ? message!
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpenExternal,
              child: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
