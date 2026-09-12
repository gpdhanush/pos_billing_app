import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/premium_config.dart';
import 'package:pos_billing/core/services/premium_purchase_service.dart';
import 'package:pos_billing/features/premium/premium_sheets.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

const _star = Color(0xFFFF9800);

enum _PayMethod { phonepe, gpay, upi, card }

/// Full-screen Premium purchase UI — follows app light/dark theme.
class PremiumPurchaseScreen extends ConsumerStatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  ConsumerState<PremiumPurchaseScreen> createState() =>
      _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends ConsumerState<PremiumPurchaseScreen> {
  final _offer = PremiumPlanOffer.local();
  _PayMethod _method = _PayMethod.phonepe;
  bool _busy = false;
  String? _error;

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
        preferredMethod: _method.name,
        contact: store?.phone,
        email: store?.email,
      );
      if (!mounted) return;
      showSnack(context, 'Premium unlocked');
      context.pop(true);
    } on PremiumPurchaseException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Plan is unavailable right now. Please check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickMethod() async {
    final scheme = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<_PayMethod>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pay using',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              for (final m in _PayMethod.values)
                ListTile(
                  leading: _methodIcon(m, scheme),
                  title: Text(_methodLabel(m)),
                  trailing: m == _method
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, m),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (selected != null) setState(() => _method = selected);
  }

  String _methodLabel(_PayMethod m) {
    switch (m) {
      case _PayMethod.phonepe:
        return 'PhonePe';
      case _PayMethod.gpay:
        return 'Google Pay';
      case _PayMethod.upi:
        return 'UPI';
      case _PayMethod.card:
        return 'Card';
    }
  }

  Widget _methodIcon(_PayMethod m, ColorScheme scheme) {
    switch (m) {
      case _PayMethod.phonepe:
        return const _PhonePeMark(size: 28);
      case _PayMethod.gpay:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF4285F4),
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      case _PayMethod.upi:
        return Icon(
          Icons.account_balance_rounded,
          color: scheme.onSurfaceVariant,
        );
      case _PayMethod.card:
        return Icon(Icons.credit_card_rounded, color: scheme.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final unlocked =
        ref.watch(appSettingsProvider).valueOrNull?.premiumUnlocked ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? AppColors.canvas : AppColors.canvasDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => showPremiumFaqSheet(context),
                    child: Text(
                      'FAQ',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                  ),
                  IconButton(
                    onPressed: () => showPremiumFaqSheet(context),
                    icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface),
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
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                      child: Column(
                        children: [
                          Text(
                            _offer.title,
                            style: text.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${(_offer.compareAtPaise / 100).round()}',
                            style: text.titleLarge?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              decoration: TextDecoration.lineThrough,
                              decorationColor:
                                  scheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${(_offer.amountPaise / 100).round()}',
                            style: text.displayMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 64,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _offer.badge,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _offer.subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(
                                5,
                                (_) => const Icon(
                                  Icons.star_rounded,
                                  color: _star,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '4.6 • Shop owners',
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _FeatureBubble(
                                icon: Icons.all_inclusive_rounded,
                                label: 'Unlimited\nProducts',
                              ),
                              _FeatureBubble(
                                icon: Icons.receipt_long_rounded,
                                label: 'Unlimited\nStocks',
                              ),
                              _FeatureBubble(
                                icon: Icons.bar_chart_rounded,
                                label: 'Reports\n& PDF',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Cancel anytime. No hidden charges.',
                            textAlign: TextAlign.center,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottom),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pay using',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _busy ? null : _pickMethod,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _methodIcon(_method, scheme),
                                const SizedBox(width: 8),
                                Text(
                                  _methodLabel(_method),
                                  style: text.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: scheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                                    : 'UNLOCK PREMIUM',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Internet required to verify payment on our server',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _FeatureBubble extends StatelessWidget {
  const _FeatureBubble({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: scheme.primary, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
        ),
      ],
    );
  }
}

class _PhonePeMark extends StatelessWidget {
  const _PhonePeMark({this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF5F259F),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'P',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}
