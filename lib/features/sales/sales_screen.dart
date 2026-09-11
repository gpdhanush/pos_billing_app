import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  ({Color color, IconData icon, String label}) _statusStyle(String status) {
    switch (status) {
      case InvoiceStatus.cancelled:
        return (
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
          label: 'CANCELLED',
        );
      case InvoiceStatus.refunded:
        return (
          color: AppColors.warning,
          icon: Icons.replay_circle_filled_outlined,
          label: 'REFUNDED',
        );
      case InvoiceStatus.completed:
      default:
        return (
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          label: 'COMPLETED',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sales = ref.watch(salesListProvider);
    final range = ref.watch(salesRangeProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;

    return Scaffold(
      appBar: GlassPageHeader(title: l10n.salesTitle),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                SoftPeriodBadge(
                  label: l10n.salesToday,
                  selected: range.startMs == SalesDateRange.today().startMs &&
                      range.endMs == SalesDateRange.today().endMs,
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.today(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesYesterday,
                  selected:
                      range.startMs == SalesDateRange.yesterday().startMs &&
                          range.endMs == SalesDateRange.yesterday().endMs,
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.yesterday(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesThisWeek,
                  selected:
                      range.startMs == SalesDateRange.thisWeek().startMs &&
                          range.endMs == SalesDateRange.thisWeek().endMs,
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.thisWeek(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesThisMonth,
                  selected:
                      range.startMs == SalesDateRange.thisMonth().startMs &&
                          range.endMs == SalesDateRange.thisMonth().endMs,
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.thisMonth(),
                ),
              ],
            ),
          ),
          Expanded(
            child: sales.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  ErrorState(onRetry: () => ref.invalidate(salesListProvider)),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: l10n.salesEmpty,
                    subtitle: l10n.salesEmptyHint,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final bill = items[i];
                    final style = _statusStyle(bill.status);
                    final customer =
                        (bill.customerName ?? l10n.billingWalkIn).displayTitle;
                    return SoftCard(
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onTap: () => context.push('/sales/${bill.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: style.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              style.icon,
                              color: style.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.invoiceNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  [
                                    customer,
                                    if (bill.paymentMethods.isNotEmpty)
                                      bill.paymentMethods
                                          .map((e) => e.toUpperCase())
                                          .join(', '),
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  style.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: style.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Money(bill.totalPaise).format(
                              symbol: store?.currencySymbol ?? '₹',
                            ),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: style.color,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
