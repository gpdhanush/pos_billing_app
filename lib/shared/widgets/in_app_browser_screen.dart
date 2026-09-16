import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for Privacy Policy and similar pages.
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
      ..setBackgroundColor(Colors.transparent)
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
    final headline =
        _pageTitle?.isNotEmpty == true ? _pageTitle! : widget.title;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: headline,
        subtitle: _hostLabel,
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading && !_failed)
            LinearProgressIndicator(
              minHeight: 2,
              value: _progress > 0 ? (_progress / 100).clamp(0.02, 1.0) : null,
              backgroundColor: scheme.outline.withValues(alpha: 0.15),
              color: scheme.primary,
            ),
          Expanded(
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
                if (_loading && !_failed && _progress == 0)
                  ColoredBox(
                    color: scheme.surfaceContainerLowest.withValues(alpha: 0.85),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
        child: SoftCard(
          radius: AppRadii.lg,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ),
              TextButton(
                onPressed: onOpenExternal,
                child: const Text('Open in browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
