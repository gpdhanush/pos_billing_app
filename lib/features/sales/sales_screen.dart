import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/bill_share_service.dart';
import 'package:pos_billing/features/billing/checkout_screen.dart';
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
    final scheme = Theme.of(context).colorScheme;

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
                    return SoftCard(
                      radius: AppRadii.compact,
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
                              borderRadius:
                                  BorderRadius.circular(AppRadii.compact),
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
                                    bill.customerName ?? l10n.billingWalkIn,
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
                          IconButton(
                            tooltip: 'Share',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () => _shareInvoiceImage(
                              context,
                              ref,
                              bill.id,
                            ),
                            icon: Icon(
                              Icons.share_outlined,
                              color: scheme.onSurfaceVariant,
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

Future<void> _shareInvoiceImage(
  BuildContext context,
  WidgetRef ref,
  int invoiceId,
) async {
  final store = ref.read(storeProfileProvider).valueOrNull;
  if (store == null) return;
  final invoice =
      await ref.read(salesRepositoryProvider).getInvoice(invoiceId);
  if (invoice == null) {
    if (context.mounted) showSnack(context, 'Invoice not found');
    return;
  }
  try {
    await BillShareService().shareReceiptImage(
      store: store,
      invoice: invoice,
    );
  } catch (_) {
    if (context.mounted) showSnack(context, 'Unable to share bill');
  }
}

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.salesDetails,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: FutureBuilder(
        future: ref.read(salesRepositoryProvider).getInvoice(invoiceId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoice = snap.data;
          if (invoice == null) {
            return EmptyState(title: l10n.salesEmpty);
          }
          final store = ref.watch(storeProfileProvider).valueOrNull;
          final symbol = store?.currencySymbol ?? '₹';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.summary.invoiceNumber,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        DateTime.fromMillisecondsSinceEpoch(
                          invoice.summary.createdAt,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.summary.customerName ?? l10n.billingWalkIn,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < invoice.items.length; i++) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        title: Text(invoice.items[i].name),
                        subtitle: Text(
                          '${invoice.items[i].quantity} × ${Money(invoice.items[i].unitPricePaise).format(symbol: symbol)}',
                        ),
                        trailing: Text(
                          Money(invoice.items[i].totalPaise)
                              .format(symbol: symbol),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  children: [
                    _row(
                      context,
                      l10n.billingSubtotal,
                      Money(invoice.subtotalPaise).format(symbol: symbol),
                    ),
                    _row(
                      context,
                      l10n.billingDiscount,
                      Money(invoice.discountPaise).format(symbol: symbol),
                    ),
                    _row(
                      context,
                      l10n.billingTax,
                      Money(invoice.taxPaise).format(symbol: symbol),
                    ),
                    const SizedBox(height: 8),
                    _row(
                      context,
                      l10n.billingTotal,
                      Money(invoice.summary.totalPaise)
                          .format(symbol: symbol),
                      emphasize: true,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final p in invoice.payments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.method.toUpperCase())),
                            Text(
                              Money(p.amountPaise).format(symbol: symbol),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final ok = await printInvoice(ref, invoice);
                        if (context.mounted && !ok) {
                          showSnack(context, l10n.checkoutPrinterFailed);
                        }
                      },
                      child: Text(l10n.commonReprint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final s = ref.read(storeProfileProvider).valueOrNull;
                        if (s == null) return;
                        try {
                          await BillShareService().shareReceiptImage(
                            store: s,
                            invoice: invoice,
                          );
                        } catch (_) {
                          if (context.mounted) {
                            showSnack(context, 'Unable to share bill');
                          }
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              if (invoice.summary.status == InvoiceStatus.completed) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l10n.salesRefund,
                      body: l10n.salesRefundConfirm,
                      icon: Icons.undo_rounded,
                      confirmLabel: l10n.salesRefund,
                    );
                    if (!ok) return;
                    await ref
                        .read(salesRepositoryProvider)
                        .reverseSale(invoiceId: invoiceId, asRefund: true);
                    ref.invalidate(salesListProvider);
                    if (context.mounted) context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                  ),
                  child: Text(l10n.salesRefund),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l10n.salesCancelInvoice,
                      body: l10n.salesCancelConfirm,
                      icon: Icons.cancel_outlined,
                      confirmLabel: l10n.salesCancelInvoice,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref
                        .read(salesRepositoryProvider)
                        .reverseSale(invoiceId: invoiceId, asRefund: false);
                    ref.invalidate(salesListProvider);
                    if (context.mounted) context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  child: Text(l10n.salesCancelInvoice),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: (emphasize
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
