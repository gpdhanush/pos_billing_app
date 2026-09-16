import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/bill_share_service.dart';
import 'package:pos_billing/features/billing/checkout_screen.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/payment_method_icon.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

export 'sales_screen.dart' show SalesScreen;

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  ({Color color, IconData icon, String label}) _statusStyle(
    String status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case InvoiceStatus.cancelled:
        return (
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
          label: l10n.salesStatusCancelled,
        );
      case InvoiceStatus.refunded:
        return (
          color: AppColors.warning,
          icon: Icons.replay_circle_filled_outlined,
          label: l10n.salesStatusRefunded,
        );
      case InvoiceStatus.completed:
      default:
        return (
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: l10n.salesStatusCompleted,
        );
    }
  }

  bool _isPaid(InvoiceDetail invoice) {
    if (invoice.summary.status != InvoiceStatus.completed) return false;
    final paid = invoice.payments.fold<int>(0, (s, p) => s + p.amountPaise);
    return paid >= invoice.summary.totalPaise.abs();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<InvoiceDetail?>(
      future: ref.read(salesRepositoryProvider).getInvoice(invoiceId),
      builder: (context, snap) {
        final style = snap.data == null
            ? null
            : _statusStyle(snap.data!.summary.status, l10n);

        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: GlassPageHeader(
            title: l10n.salesDetails,
            subtitle: l10n.invoiceDetailSubtitle,
            height: 64,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: style == null
                ? null
                : [
                    _StatusChip(
                      label: style.label,
                      color: style.color,
                      icon: style.icon,
                    ),
                  ],
          ),
          body: !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : snap.data == null
                  ? EmptyState(title: l10n.salesEmpty)
                  : _InvoiceBody(
                      invoiceId: invoiceId,
                      invoice: snap.data!,
                      statusColor: style!.color,
                      paid: _isPaid(snap.data!),
                    ),
        );
      },
    );
  }
}

class _InvoiceBody extends ConsumerWidget {
  const _InvoiceBody({
    required this.invoiceId,
    required this.invoice,
    required this.statusColor,
    required this.paid,
  });

  final int invoiceId;
  final InvoiceDetail invoice;
  final Color statusColor;
  final bool paid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final customer =
        (invoice.summary.customerName ?? l10n.billingWalkIn).displayTitle;
    final when = DateFormat.yMMMd().add_jm().format(
          DateTime.fromMillisecondsSinceEpoch(invoice.summary.createdAt),
        );
    final total = Money(invoice.summary.totalPaise).format(symbol: symbol);
    final canReverse = invoice.summary.status == InvoiceStatus.completed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _InvoiceHeroCard(
          invoiceNumber: invoice.summary.invoiceNumber,
          when: when,
          customer: customer,
          total: total,
          accent: statusColor,
          paid: paid,
        ),
        const SizedBox(height: 14),
        _ItemsCard(items: invoice.items, symbol: symbol),
        const SizedBox(height: 12),
        _BillingDetailsCard(
          symbol: symbol,
          subtotalPaise: invoice.subtotalPaise,
          discountPaise: invoice.billDiscountPaise,
          taxPaise: invoice.taxPaise,
          roundOffPaise: invoice.roundOffPaise,
          totalPaise: invoice.summary.totalPaise,
          subtotalLabel: l10n.billingSubtotal,
          discountLabel: l10n.billingDiscount,
          taxLabel: l10n.billingTax,
          totalLabel: l10n.billingTotal,
        ),
        const SizedBox(height: 12),
        _SectionPanel(
          title: l10n.customersPayments,
          child: Column(
            children: [
              for (final p in invoice.payments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      PaymentMethodIcon(method: p.method, size: 40, radius: 11),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.method.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        Money(p.amountPaise).format(symbol: symbol),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                label: l10n.commonReprint,
                icon: Icons.print_outlined,
                filled: true,
                onTap: () async {
                  final ok = await printInvoice(ref, invoice);
                  if (context.mounted && !ok) {
                    showSnack(context, l10n.checkoutPrinterFailed);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                label: l10n.commonSharePdf,
                icon: Icons.picture_as_pdf_outlined,
                onTap: () async {
                  final s = ref.read(storeProfileProvider).valueOrNull;
                  if (s == null) return;
                  try {
                    await BillShareService().sharePdf(
                      l10n: l10n,
                      store: s,
                      invoice: invoice,
                    );
                  } catch (_) {
                    if (context.mounted) {
                      showSnack(context, l10n.errorsSharePdf);
                    }
                  }
                },
              ),
            ),
          ],
        ),
        if (canReverse) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: l10n.salesRefund,
                  icon: Icons.undo_rounded,
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l10n.salesRefund,
                      body: l10n.salesRefundConfirm,
                      icon: Icons.undo_rounded,
                      confirmLabel: l10n.salesRefund,
                    );
                    if (!ok) return;
                    await ref.read(salesRepositoryProvider).reverseSale(
                          invoiceId: invoiceId,
                          asRefund: true,
                        );
                    ref.invalidate(salesListProvider);
                    if (context.mounted) context.pop();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  label: l10n.salesCancelInvoice,
                  icon: Icons.cancel_outlined,
                  filled: true,
                  danger: true,
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l10n.salesCancelInvoice,
                      body: l10n.salesCancelConfirm,
                      icon: Icons.cancel_outlined,
                      confirmLabel: l10n.salesCancelInvoice,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(salesRepositoryProvider).reverseSale(
                          invoiceId: invoiceId,
                          asRefund: false,
                        );
                    ref.invalidate(salesListProvider);
                    if (context.mounted) context.pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceHeroCard extends StatelessWidget {
  const _InvoiceHeroCard({
    required this.invoiceNumber,
    required this.when,
    required this.customer,
    required this.total,
    required this.accent,
    required this.paid,
  });

  final String invoiceNumber;
  final String when;
  final String customer;
  final String total;
  final Color accent;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.05),
            scheme.surface,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedInvoice01,
                            size: 22,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.invoiceNumberLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoiceNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    when,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: VerticalDivider(
                width: 1,
                color: accent.withValues(alpha: 0.25),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.checkoutTotalAmount,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      total,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: -0.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paid
                          ? AppColors.success.withValues(alpha: 0.12)
                          : scheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 13,
                          color: paid
                              ? AppColors.success
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paid ? l10n.checkoutPaid : l10n.checkoutUnpaid,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: paid
                                        ? AppColors.success
                                        : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.items,
    required this.symbol,
  });

  final List<InvoiceLine> items;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final countLabel = l10n.invoiceItemCount(items.length);

    return SoftCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedShoppingCart01,
                    size: 18,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.invoiceItemsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  countLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('#', style: _headerStyle(context)),
                ),
                Expanded(
                  flex: 5,
                  child: Text(l10n.invoiceItemColumn, style: _headerStyle(context)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.invoiceQtyPriceColumn,
                    textAlign: TextAlign.center,
                    style: _headerStyle(context),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.commonAmount,
                    textAlign: TextAlign.right,
                    style: _headerStyle(context),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outline.withValues(alpha: 0.35),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      items[i].name.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${items[i].quantity} × ${Money(items[i].unitPricePaise).format(symbol: symbol)}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      Money(items[i].totalPaise).format(symbol: symbol),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        );
  }
}

class _BillingDetailsCard extends StatelessWidget {
  const _BillingDetailsCard({
    required this.symbol,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.taxPaise,
    required this.roundOffPaise,
    required this.totalPaise,
    required this.subtotalLabel,
    required this.discountLabel,
    required this.taxLabel,
    required this.totalLabel,
  });

  final String symbol;
  final int subtotalPaise;
  final int discountPaise;
  final int taxPaise;
  final int roundOffPaise;
  final int totalPaise;
  final String subtotalLabel;
  final String discountLabel;
  final String taxLabel;
  final String totalLabel;

  String _signedMoney(int paise) {
    final formatted = Money(paise).format(symbol: symbol);
    if (paise > 0) return '+$formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SoftCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedInvoice03,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.invoiceBillingDetails,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoneyRow(
            label: subtotalLabel,
            value: Money(subtotalPaise).format(symbol: symbol),
          ),
          _MoneyRow(
            label: discountLabel,
            value: Money(discountPaise).format(symbol: symbol),
          ),
          _MoneyRow(
            label: taxLabel,
            value: Money(taxPaise).format(symbol: symbol),
          ),
          _MoneyRow(
            label: l10n.billingRoundOff,
            value: _signedMoney(roundOffPaise),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.4),
            ),
          ),
          _MoneyRow(
            label: totalLabel,
            value: Money(totalPaise).format(symbol: symbol),
            emphasize: true,
            color: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: base?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                color: emphasize
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: base?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = danger
        ? AppColors.danger
        : filled
            ? scheme.primary
            : scheme.surface;
    final fg = (filled || danger) ? Colors.white : scheme.onSurface;
    final border = danger
        ? AppColors.danger
        : filled
            ? scheme.primary
            : scheme.outline.withValues(alpha: 0.65);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: filled || danger
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
