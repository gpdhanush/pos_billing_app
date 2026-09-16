import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/bill_share_service.dart';
import 'package:pos_billing/core/services/printer_service.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/payment_method_icon.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _method = PaymentMethods.cash;
  final _received = TextEditingController();
  final _cash = TextEditingController();
  final _upi = TextEditingController();
  final _card = TextEditingController();
  final _credit = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _received.dispose();
    _cash.dispose();
    _upi.dispose();
    _card.dispose();
    _credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totals = ref.watch(cartTotalsProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final total = totals.grandTotalPaise;
    final received = parseRupeesToPaise(_received.text);
    final change = ref
        .read(billingCalcProvider)
        .calculateChange(grandTotalPaise: total, receivedPaise: received);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: 'Complete payment',
        subtitle: 'Choose method & collect amount',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Text(
                  l10n.checkoutTotalAmount,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Money(total).format(symbol: symbol),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Payment method'),
          const SizedBox(height: 10),
          SoftCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _methodChip(l10n.checkoutCash, PaymentMethods.cash),
                _methodChip(l10n.checkoutUpi, PaymentMethods.upi),
                _methodChip(l10n.checkoutCard, PaymentMethods.card),
                _methodChip(l10n.checkoutCredit, PaymentMethods.credit),
                _methodChip(l10n.checkoutMixed, 'mixed'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_method == PaymentMethods.cash) ...[
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _received,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [ThousandDecimalFormatter()],
                    decoration: InputDecoration(
                      hintText: l10n.checkoutReceived,
                      prefixText: '$symbol ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      '${l10n.checkoutChange}: ${Money(change).format(symbol: symbol)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_method == 'mixed') ...[
            SoftCard(
              child: Column(
                children: [
                  MoneyField(controller: _cash, label: l10n.checkoutCash),
                  const SizedBox(height: 10),
                  MoneyField(controller: _upi, label: l10n.checkoutUpi),
                  const SizedBox(height: 10),
                  MoneyField(controller: _card, label: l10n.checkoutCard),
                  const SizedBox(height: 10),
                  MoneyField(controller: _credit, label: l10n.checkoutCredit),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _pay(total),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.checkoutComplete),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String label, String value) {
    final selected = _method == value;
    final asset = PaymentMethodIcon.assetFor(value);
    return ChoiceChip(
      avatar: asset == null
          ? null
          : PaymentMethodIcon(method: value, size: 22, radius: 6),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _method = value),
    );
  }

  Future<void> _pay(int total) async {
    dismissKeyboard();
    final l10n = AppLocalizations.of(context);
    final cart = ref.read(cartProvider);
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return;
    if (_method == PaymentMethods.credit && cart.customer == null) {
      showSnack(context, l10n.checkoutCreditNeedsCustomer);
      return;
    }

    final payments = <PaymentDraft>[];
    if (_method == 'mixed') {
      void add(String method, TextEditingController c) {
        final amount = parseRupeesToPaise(c.text);
        if (amount > 0) {
          payments.add(PaymentDraft(method: method, amountPaise: amount));
        }
      }

      add(PaymentMethods.cash, _cash);
      add(PaymentMethods.upi, _upi);
      add(PaymentMethods.card, _card);
      add(PaymentMethods.credit, _credit);
      if (payments.any((p) => p.method == PaymentMethods.credit) &&
          cart.customer == null) {
        showSnack(context, l10n.checkoutCreditNeedsCustomer);
        return;
      }
    } else if (_method == PaymentMethods.cash) {
      final received = parseRupeesToPaise(_received.text);
      if (received < total) {
        showSnack(context, l10n.errorsPaymentShort);
        return;
      }
      payments.add(
        PaymentDraft(
          method: PaymentMethods.cash,
          amountPaise: total,
          receivedPaise: received,
          changePaise: received - total,
        ),
      );
    } else {
      payments.add(PaymentDraft(method: _method, amountPaise: total));
    }

    setState(() => _busy = true);
    try {
      final settings = ref.read(appSettingsProvider).valueOrNull;
      final invoice = await ref
          .read(salesRepositoryProvider)
          .checkout(
            CheckoutCommand(
              storeId: store.id,
              lines: cart.lines,
              payments: payments,
              customerId: cart.customer?.id,
              billDiscountPaise: cart.billDiscountPaise,
              taxOverridePaise: cart.taxOverridePaise,
              allowNegativeStock: settings?.allowNegativeStock ?? false,
            ),
          );
      await ref.read(backupDirtyTrackerProvider).markDirty();
      await ref.read(analyticsServiceProvider).logEvent('invoice_created');
      await ref.read(storeProfileProvider.notifier).reload();
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(salesListProvider);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      await _success(invoice);
    } on InsufficientStockException catch (e) {
      if (mounted) {
        showSnack(context, l10n.errorsInsufficientStock(e.productName));
      }
    } on AppException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _success(InvoiceDetail invoice) async {
    final l10n = AppLocalizations.of(context);
    final store = ref.read(storeProfileProvider).valueOrNull!;
    final scheme = Theme.of(context).colorScheme;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () {
                        ref.read(cartProvider.notifier).clear();
                        Navigator.pop(sheetContext);
                        context.go('/billing');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.checkoutSuccessTitle,
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  invoice.summary.invoiceNumber,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  Money(invoice.summary.totalPaise)
                      .format(symbol: store.currencySymbol),
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final printed = await printInvoice(ref, invoice);
                          if (sheetContext.mounted && !printed) {
                            showSnack(
                              sheetContext,
                              l10n.checkoutPrinterFailed,
                            );
                          }
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: Text(l10n.checkoutPrintBill),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await BillShareService().sharePdf(
                              store: store,
                              invoice: invoice,
                            );
                          } catch (_) {
                            if (sheetContext.mounted) {
                              showSnack(sheetContext, 'Unable to share PDF');
                            }
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Share PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clear();
                      Navigator.pop(sheetContext);
                      context.go('/billing');
                    },
                    child: Text(l10n.checkoutNewBill),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<bool> printInvoice(WidgetRef ref, InvoiceDetail invoice) async {
  try {
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return false;
    final paper =
        ref.read(appSettingsProvider).valueOrNull?.paperSize ?? '58mm';
    final bytes = await ref
        .read(receiptBuilderProvider)
        .build(store: store, invoice: invoice, paperSize: paper);
    final printer = ref.read(printerServiceProvider);
    if (printer is CompositePrinterService) {
      printer.use('bluetooth');
    }
    await printer.printBytes(bytes);
    return true;
  } catch (_) {
    return false;
  }
}
