import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/premium_config.dart';
import 'package:pos_billing/core/services/premium_purchase_service.dart';
import 'package:pos_billing/features/premium/premium_sheets.dart';
import 'package:pos_billing/features/premium/premium_unlocked_celebration.dart';
import 'package:pos_billing/shared/widgets/app_logo.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

/// Full-screen Premium purchase — modern light/dark business offer.
class PremiumPurchaseScreen extends ConsumerStatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  ConsumerState<PremiumPurchaseScreen> createState() =>
      _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends ConsumerState<PremiumPurchaseScreen> {
  final _offer = PremiumPlanOffer.local();
  bool _busy = false;
  String? _error;

  int get _discountPercent {
    if (_offer.compareAtPaise <= 0) return 0;
    return (((_offer.compareAtPaise - _offer.amountPaise) /
                _offer.compareAtPaise) *
            100)
        .round();
  }

  Future<void> _buy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = ref.read(storeProfileProvider).valueOrNull;
    final purchase = ref.read(premiumPurchaseServiceProvider);

    try {
      await purchase.purchasePremium(
        storeName: store?.businessName ?? 'POS Shop',
        contact: store?.phone,
        email: store?.email,
      );
      if (!mounted) return;
      await showPremiumUnlockedCelebration(context);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/more');
      }
    } on PremiumPurchaseException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showSnack(
        context,
        'Unable to unlock right now. Check your internet and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await confirmDialog(
      context,
      title: 'Cancel unlock?',
      body: 'Leave without unlocking Premium? You can come back anytime.',
      icon: Icons.close_rounded,
      confirmLabel: 'Cancel unlock',
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final unlocked =
        ref.watch(appSettingsProvider).valueOrNull?.premiumUnlocked ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: isLight ? AppColors.canvas : AppColors.canvasDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: 'FAQ',
                    onPressed: () => showPremiumFaqSheet(context),
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _error != null
                  ? _UnavailableState(
                      message: _error!,
                      onRetry: () {
                        setState(() => _error = null);
                        _buy();
                      },
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        children: [
                          SoftCard(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                            child: Column(
                              children: [
                                const AppLogo(size: 72, radius: 18, showShadow: true),
                                const SizedBox(height: 16),
                                Text(
                                  'Grow your shop faster',
                                  textAlign: TextAlign.center,
                                  style: text.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unlock unlimited catalog, stock control, expenses, reports and export — one payment, lifetime access.',
                                  textAlign: TextAlign.center,
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: isLight ? 0.12 : 0.22,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                  ),
                                  child: Text(
                                    'LIMITED OFFER · $_discountPercent% OFF',
                                    style: text.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '₹${(_offer.compareAtPaise / 100).round()}',
                                  style: text.titleMedium?.copyWith(
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.75),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${(_offer.amountPaise / 100).round()}',
                                  style: text.displayMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 56,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'One-time · Lifetime Premium',
                                  style: text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No subscription · No renewals',
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SoftCard(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(
                              children: const [
                                _BenefitRow(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Unlimited products',
                                  subtitle: 'Scale your catalog without limits',
                                ),
                                _BenefitRow(
                                  icon: Icons.warehouse_outlined,
                                  title: 'Unlimited stock movements',
                                  subtitle: 'Track every in and out accurately',
                                ),
                                _BenefitRow(
                                  icon: Icons.payments_outlined,
                                  title: 'Unlimited expenses',
                                  subtitle: 'Keep shop spending under control',
                                ),
                                _BenefitRow(
                                  icon: Icons.insights_outlined,
                                  title: 'Reports, PDF & export',
                                  subtitle: 'Decisions backed by clear numbers',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10 + bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: unlocked || _busy ? null : _buy,
                      child: _busy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(
                              unlocked
                                  ? 'ALREADY UNLOCKED'
                                  : 'UNLOCK FOR ₹${(_offer.amountPaise / 100).round()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : _confirmCancel,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LineIcons.alternateShield,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Secure payment',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '·',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        LineIcons.wifi,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Internet required',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, isLast ? 10 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.priority_high_rounded,
              color: scheme.onError,
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
