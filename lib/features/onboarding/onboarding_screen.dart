import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/features/onboarding/onboarding_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/setup/language');
  }

  void _next(int pageCount) {
    if (_page < pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pages = <_OnboardPageData>[
      _OnboardPageData(
        icon: HugeIcons.strokeRoundedQrCodeScan,
        title: l10n.onboardingFastTitle,
        body: l10n.onboardingFastBody,
      ),
      _OnboardPageData(
        icon: HugeIcons.strokeRoundedPackageDelivered,
        title: l10n.onboardingStockTitle,
        body: l10n.onboardingStockBody,
      ),
      _OnboardPageData(
        icon: HugeIcons.strokeRoundedCloudSavingDone02,
        title: l10n.onboardingBackupTitle,
        body: l10n.onboardingBackupBody,
      ),
    ];

    return Scaffold(
      body: OnboardBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _page > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: _page > 0
                            ? () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                )
                            : null,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          size: 22,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.commonSkip,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    return _OnboardPage(data: pages[i], active: i == _page);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: i == _page ? 28 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    OnboardPrimaryButton(
                      label: _page == pages.length - 1
                          ? l10n.commonGetStarted
                          : l10n.commonNext,
                      icon: _page == pages.length - 1
                          ? HugeIcons.strokeRoundedTick02
                          : HugeIcons.strokeRoundedArrowRight01,
                      onPressed: () => _next(pages.length),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  const _OnboardPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String body;
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data, required this.active});

  final _OnboardPageData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: active ? 1 : 0.55,
      duration: const Duration(milliseconds: 280),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            TweenAnimationBuilder<double>(
              key: ValueKey(data.title),
              tween: Tween(begin: 0.86, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: OnboardHeroIcon(icon: data.icon),
            ),
            const SizedBox(height: 36),
            TweenAnimationBuilder<double>(
              key: ValueKey('t-${data.title}'),
              tween: Tween(begin: 18, end: 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              builder: (context, dy, child) => Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: (1 - (dy / 18)).clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
