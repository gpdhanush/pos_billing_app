import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/bill_share_service.dart';
import 'package:pos_billing/features/billing/checkout_screen.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

export 'sales_screen.dart' show SalesScreen;

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  ({Color color, IconData icon, String label}) _statusStyle(String status) {
    switch (status) {
      case InvoiceStatus.cancelled:
        return (
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
        );
      case InvoiceStatus.refunded:
        return (
          color: AppColors.warning,
          icon: Icons.replay_circle_filled_outlined,
          label: 'Refunded',
        );
      case InvoiceStatus.completed:
      default:
        return (
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.26, 1],
          ),
        ),
        child: FutureBuilder<InvoiceDetail?>(
          future: ref.read(salesRepositoryProvider).getInvoice(invoiceId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoice = snap.data;
            if (invoice == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      title: l10n.salesDetails,
                      onBack: () => context.pop(),
                    ),
                    Expanded(child: EmptyState(title: l10n.salesEmpty)),
                  ],
                ),
              );
            }

            final store = ref.watch(storeProfileProvider).valueOrNull;
            final symbol = store?.currencySymbol ?? '₹';
            final style = _statusStyle(invoice.summary.status);
            final customer =
                (invoice.summary.customerName ?? l10n.billingWalkIn)
                    .displayTitle;
            final when = DateFormat.yMMMd().add_jm().format(
                  DateTime.fromMillisecondsSinceEpoch(
                    invoice.summary.createdAt,
                  ),
                );
            final total = Money(invoice.summary.totalPaise)
                .format(symbol: symbol);
            final canReverse =
                invoice.summary.status == InvoiceStatus.completed;

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    title: l10n.salesDetails,
                    onBack: () => context.pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        _HeroPanel(
                          invoiceNumber: invoice.summary.invoiceNumber,
                          when: when,
                          customer: customer,
                          total: total,
                          statusColor: style.color,
                          statusIcon: style.icon,
                          statusLabel: style.label,
                        ),
                        const SizedBox(height: 16),
                        _SectionPanel(
                          title: 'Items',
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < invoice.items.length;
                                  i++) ...[
                                if (i > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: scheme.outline
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                _ItemRow(
                                  name: invoice.items[i].name.displayTitle,
                                  meta:
                                      '${invoice.items[i].quantity} × ${Money(invoice.items[i].unitPricePaise).format(symbol: symbol)}',
                                  amount: Money(invoice.items[i].totalPaise)
                                      .format(symbol: symbol),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionPanel(
                          title: 'Summary',
                          child: Column(
                            children: [
                              _MoneyRow(
                                label: l10n.billingSubtotal,
                                value: Money(invoice.subtotalPaise)
                                    .format(symbol: symbol),
                              ),
                              _MoneyRow(
                                label: l10n.billingDiscount,
                                value: Money(invoice.discountPaise)
                                    .format(symbol: symbol),
                              ),
                              _MoneyRow(
                                label: l10n.billingTax,
                                value: Money(invoice.taxPaise)
                                    .format(symbol: symbol),
                              ),
                              const SizedBox(height: 8),
                              _MoneyRow(
                                label: l10n.billingTotal,
                                value: total,
                                emphasize: true,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionPanel(
                          title: 'Payments',
                          child: Column(
                            children: [
                              for (final p in invoice.payments)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: scheme.primary
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                          color: scheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          p.method.displayTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        Money(p.amountPaise)
                                            .format(symbol: symbol),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
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
                                  final ok =
                                      await printInvoice(ref, invoice);
                                  if (context.mounted && !ok) {
                                    showSnack(
                                      context,
                                      l10n.checkoutPrinterFailed,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionTile(
                                label: 'Share PDF',
                                icon: Icons.picture_as_pdf_outlined,
                                onTap: () async {
                                  final s = ref
                                      .read(storeProfileProvider)
                                      .valueOrNull;
                                  if (s == null) return;
                                  try {
                                    await BillShareService().sharePdf(
                                      store: s,
                                      invoice: invoice,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      showSnack(
                                        context,
                                        'Unable to share PDF',
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (canReverse) ...[
                          const SizedBox(height: 10),
                          _ActionTile(
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
                              await ref
                                  .read(salesRepositoryProvider)
                                  .reverseSale(
                                    invoiceId: invoiceId,
                                    asRefund: true,
                                  );
                              ref.invalidate(salesListProvider);
                              if (context.mounted) context.pop();
                            },
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
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
                              await ref
                                  .read(salesRepositoryProvider)
                                  .reverseSale(
                                    invoiceId: invoiceId,
                                    asRefund: false,
                                  );
                              ref.invalidate(salesListProvider);
                              if (context.mounted) context.pop();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.55),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: scheme.onSurface,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.invoiceNumber,
    required this.when,
    required this.customer,
    required this.total,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  final String invoiceNumber;
  final String when;
  final String customer;
  final String total;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.06),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoiceNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            when,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            customer,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            total,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  letterSpacing: -0.6,
                ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
      ),
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.meta,
    required this.amount,
  });

  final String name;
  final String meta;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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
