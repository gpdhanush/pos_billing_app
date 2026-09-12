import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/services/premium_access.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

Future<void> showPremiumFaqSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PremiumFaqSheet(),
  );
}

Future<bool> showPremiumPaywallSheet(BuildContext context, WidgetRef ref) async {
  final result = await context.push<bool>('/premium');
  return result ?? false;
}

String _quotaLabel(PremiumQuotaKind kind) {
  switch (kind) {
    case PremiumQuotaKind.products:
      return 'products';
    case PremiumQuotaKind.stocks:
      return 'stock movements';
    case PremiumQuotaKind.expenses:
      return 'expenses';
  }
}

Future<bool> ensurePremiumQuota({
  required BuildContext context,
  required WidgetRef ref,
  required PremiumQuotaKind kind,
}) async {
  final unlocked =
      ref.read(appSettingsProvider).valueOrNull?.premiumUnlocked ?? false;
  if (unlocked) return true;

  final store = ref.read(storeProfileProvider).valueOrNull;
  if (store == null) return false;

  final underLimit =
      await ref.read(premiumAccessProvider).underFreeLimit(kind, store.id);
  if (underLimit) return true;
  if (!context.mounted) return false;

  final unlock = await confirmDialog(
    context,
    title: 'Free limit reached',
    body:
        'You can keep up to ${PremiumLimits.freeItemLimit} ${_quotaLabel(kind)} on the free plan.\n\nUnlock Premium for ₹99 once to remove all limits.',
    icon: Icons.lock_rounded,
    confirmLabel: 'Unlock ₹99',
  );
  if (!unlock || !context.mounted) return false;
  return showPremiumPaywallSheet(context, ref);
}

Future<void> showPremiumLockedAlert({
  required BuildContext context,
  required WidgetRef ref,
  String feature = 'This feature',
}) async {
  final unlock = await confirmDialog(
    context,
    title: 'Premium required',
    body:
        '$feature is available with Premium.\n\nUnlock once for ₹99 to access all features.',
    icon: Icons.lock_rounded,
    confirmLabel: 'Unlock ₹99',
  );
  if (!unlock || !context.mounted) return;
  await showPremiumPaywallSheet(context, ref);
}

class _PremiumFaqSheet extends StatelessWidget {
  const _PremiumFaqSheet();

  static const _items = <(String, String)>[
    (
      'Why unlock for ₹99?',
      'Free plan allows 10 products, 10 stock movements and 10 expenses. Premium removes those limits and unlocks Reports and Export.',
    ),
    (
      'Is this a subscription?',
      'No. ₹99 is a one-time unlock. You keep Premium forever on this device — no yearly renewal.',
    ),
    (
      'Do I need internet?',
      'Yes. Purchase and unlock must be verified on our server. Keep mobile data or Wi‑Fi on until payment completes.',
    ),
    (
      'Will I lose my shop data if I cancel?',
      'No. Your products, orders and customers stay on your device, and any backup you have made stays in your own cloud storage.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.panel : AppColors.panelDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outline.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Frequently asked questions',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(24, 18, 24, 28 + bottom),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 26),
              itemBuilder: (context, i) {
                final (q, a) = _items[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      a,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
