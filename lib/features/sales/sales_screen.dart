import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final salesSearchProvider = StateProvider<String>((ref) => '');

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  ({Color color, List<List<dynamic>> icon, String label}) _statusStyle(
    String status,
    ColorScheme scheme,
  ) {
    switch (status) {
      case InvoiceStatus.cancelled:
        return (
          color: AppColors.danger,
          icon: HugeIcons.strokeRoundedCancel01,
          label: 'Cancelled',
        );
      case InvoiceStatus.refunded:
        return (
          color: AppColors.warning,
          icon: HugeIcons.strokeRoundedReload,
          label: 'Refunded',
        );
      case InvoiceStatus.completed:
      default:
        return (
          color: scheme.primary,
          icon: HugeIcons.strokeRoundedInvoice01,
          label: 'Completed',
        );
    }
  }

  List<InvoiceSummary> _filter(List<InvoiceSummary> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((bill) {
      final hay = [
        bill.invoiceNumber,
        bill.customerName ?? '',
        ...bill.paymentMethods,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sales = ref.watch(salesListProvider);
    final range = ref.watch(salesRangeProvider);
    final search = ref.watch(salesSearchProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final canPop = context.canPop();

    bool isRange(SalesDateRange a, SalesDateRange b) =>
        a.startMs == b.startMs && a.endMs == b.endMs;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.salesTitle,
        subtitle: 'Invoices & payment history',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: 'Search invoice or customer',
              onChanged: (v) => ref.read(salesSearchProvider.notifier).state = v,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SoftPeriodBadge(
                  label: l10n.salesToday,
                  selected: isRange(range, SalesDateRange.today()),
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.today(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesYesterday,
                  selected: isRange(range, SalesDateRange.yesterday()),
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.yesterday(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesThisWeek,
                  selected: isRange(range, SalesDateRange.thisWeek()),
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.thisWeek(),
                ),
                SoftPeriodBadge(
                  label: l10n.salesThisMonth,
                  selected: isRange(range, SalesDateRange.thisMonth()),
                  onTap: () => ref.read(salesRangeProvider.notifier).state =
                      SalesDateRange.thisMonth(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: sales.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  ErrorState(onRetry: () => ref.invalidate(salesListProvider)),
              data: (items) {
                final visible = _filter(items, search);
                if (visible.isEmpty) {
                  return EmptyState(
                    title: l10n.salesEmpty,
                    subtitle: l10n.salesEmptyHint,
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final bill = visible[i];
                    final style = _statusStyle(bill.status, scheme);
                    final when = dateFmt.format(
                      DateTime.fromMillisecondsSinceEpoch(bill.createdAt),
                    );
                    final pay = bill.paymentMethods.isEmpty
                        ? null
                        : bill.paymentMethods.join(', ').toUpperCase();
                    final meta = [
                      when,
                      style.label,
                      ?pay,
                      if (bill.customerName?.trim().isNotEmpty ?? false)
                        bill.customerName!.trim(),
                    ].join(' • ');

                    return SoftCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      onTap: () => context.push('/invoice/${bill.id}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: ColoredBox(
                                color: style.color.withValues(alpha: 0.12),
                                child: Center(
                                  child: HugeIcon(
                                    icon: style.icon,
                                    size: 22,
                                    color: style.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.invoiceNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Money(bill.totalPaise).format(symbol: symbol),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
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
