import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/utils/invoice_numbering.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class OrderCheckoutScreen extends ConsumerWidget {
  const OrderCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;

    if (cart.lines.isEmpty) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: GlassPageHeader(
          title: 'Checkout',
          subtitle: 'Review cart & continue to payment',
          height: 64,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedShoppingCart01,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cart is empty',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add products from billing to continue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/billing'),
                  child: Text(l10n.navBilling),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orderLabel = InvoiceNumbering.format(
      prefix: store?.invoicePrefix ?? 'INV',
      number: store?.nextInvoiceNumber ?? 1,
    );
    final totalQty = cart.lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final productCount = cart.lines.length;
    final taxablePaise =
        (totals.subtotalPaise - totals.billDiscountPaise).clamp(0, 1 << 62);
    final taxPercent = taxablePaise > 0
        ? (totals.taxPaise * 100 / taxablePaise)
        : 0.0;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: orderLabel,
        subtitle: 'Review cart & continue to payment',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(context, l10n),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                SoftCard(
                  child: Row(
                    children: [
                      _softHugeIcon(scheme, HugeIcons.strokeRoundedStore01),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store?.name ?? 'Your Business',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  child: Row(
                    children: [
                      _softHugeIcon(scheme, HugeIcons.strokeRoundedUser),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cart.customer?.name ?? l10n.billingWalkIn,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickCustomer(context, ref),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          size: 16,
                          color: scheme.primary,
                        ),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < cart.lines.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ItemRow(
                          line: cart.lines[i],
                          symbol: symbol,
                          onDecrement: () {
                            ref.read(cartProvider.notifier).setQty(
                                  cart.lines[i].product.id,
                                  cart.lines[i].quantity - 1,
                                );
                          },
                          onIncrement: () {
                            ref
                                .read(cartProvider.notifier)
                                .addProduct(cart.lines[i].product);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total items',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$productCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: scheme.outline.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total quantity',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalQty',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
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
                        'Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      _detailRow(
                        context,
                        l10n.billingSubtotal,
                        Money(totals.subtotalPaise).format(symbol: symbol),
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        context,
                        l10n.billingDiscount,
                        Money(totals.billDiscountPaise).format(symbol: symbol),
                        editable: true,
                        onTap: () => _editAmount(
                          context,
                          title: l10n.billingDiscount,
                          symbol: symbol,
                          currentPaise: cart.billDiscountPaise,
                          onSave: (paise) => ref
                              .read(cartProvider.notifier)
                              .setBillDiscount(paise),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        context,
                        taxPercent > 0
                            ? '${l10n.billingTax} (${_formatPercent(taxPercent)}%)'
                            : l10n.billingTax,
                        Money(totals.taxPaise).format(symbol: symbol),
                        editable: true,
                        onTap: () => _editTaxPercent(
                          context,
                          ref,
                          title: l10n.billingTax,
                          symbol: symbol,
                          taxablePaise: taxablePaise,
                          currentTaxPaise: totals.taxPaise,
                        ),
                      ),
                      if (totals.roundOffPaise != 0) ...[
                        const SizedBox(height: 8),
                        _detailRow(
                          context,
                          'Round off',
                          '${totals.roundOffPaise > 0 ? '+' : ''}${Money(totals.roundOffPaise).format(symbol: symbol)}',
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _detailRow(
                        context,
                        l10n.billingTotal,
                        Money(totals.grandTotalPaise).format(symbol: symbol),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: dismissKeyboardAnd(() => context.push('/payment')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Complete payment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: scheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPercent(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _softHugeIcon(ColorScheme scheme, List<List<dynamic>> icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: scheme.primary,
          size: 20,
          strokeWidth: 1.7,
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    bool editable = false,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            );
    final valueStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );
    final row = Row(
      children: [
        Flexible(
          child: Row(
            children: [
              Flexible(child: Text(label, style: style)),
              if (editable) ...[
                const SizedBox(width: 6),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 15,
                  color: scheme.primary,
                  strokeWidth: 1.8,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle, textAlign: TextAlign.right),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        Color.lerp(scheme.primary, scheme.secondary, 0.4)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 28,
                      color: scheme.onPrimary,
                      strokeWidth: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Invoice confirmation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review items and customer, then continue to payment.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                _InfoTip(
                  icon: HugeIcons.strokeRoundedDiscount,
                  title: 'Discount',
                  body: 'Tap Discount to enter a bill-level amount off.',
                ),
                const SizedBox(height: 10),
                _InfoTip(
                  icon: HugeIcons.strokeRoundedPercent,
                  title: 'Tax %',
                  body:
                      'Tap Tax to set a percentage. Amount is calculated from subtotal after discount.',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(l10n.commonClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editAmount(
    BuildContext context, {
    required String title,
    required String symbol,
    required int currentPaise,
    required ValueChanged<int> onSave,
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AmountEditSheet(
        title: title,
        symbol: symbol,
        currentPaise: currentPaise,
      ),
    );
    if (result != null) onSave(result);
  }

  Future<void> _editTaxPercent(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String symbol,
    required int taxablePaise,
    required int currentTaxPaise,
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TaxPercentEditSheet(
        title: title,
        symbol: symbol,
        taxablePaise: taxablePaise,
        currentTaxPaise: currentTaxPaise,
      ),
    );
    if (result != null) {
      ref.read(cartProvider.notifier).setTaxOverride(result);
    }
  }

  Future<void> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return;
    final customers =
        await ref.read(customerRepositoryProvider).search(store.id, '');
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select customer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text(l10n.billingWalkIn),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? Center(child: Text(l10n.customersEmpty))
                      : ListView.separated(
                          itemCount: customers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = customers[i];
                            return ListTile(
                              leading: InitialsAvatar(label: c.name, size: 42),
                              title: Text(c.name.displayTitle),
                              subtitle: Text(c.phone ?? ''),
                              onTap: () => Navigator.pop(context, c),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    ref.read(cartProvider.notifier).setCustomer(selected);
  }
}

class _InfoTip extends StatelessWidget {
  const _InfoTip({
    required this.icon,
    required this.title,
    required this.body,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                icon: icon,
                size: 18,
                color: scheme.primary,
                strokeWidth: 1.7,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
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

class _AmountEditSheet extends StatefulWidget {
  const _AmountEditSheet({
    required this.title,
    required this.symbol,
    required this.currentPaise,
  });

  final String title;
  final String symbol;
  final int currentPaise;

  @override
  State<_AmountEditSheet> createState() => _AmountEditSheetState();
}

class _AmountEditSheetState extends State<_AmountEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentPaise == 0
          ? ''
          : Money(widget.currentPaise).formatForField(),
    );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedDiscount,
                size: 22,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandDecimalFormatter()],
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${widget.symbol} ',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              dismissKeyboard();
              Navigator.pop(context, parseRupeesToPaise(_controller.text));
            },
            child: Text(l10n.commonSave),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TaxPercentEditSheet extends StatefulWidget {
  const _TaxPercentEditSheet({
    required this.title,
    required this.symbol,
    required this.taxablePaise,
    required this.currentTaxPaise,
  });

  final String title;
  final String symbol;
  final int taxablePaise;
  final int currentTaxPaise;

  @override
  State<_TaxPercentEditSheet> createState() => _TaxPercentEditSheetState();
}

class _TaxPercentEditSheetState extends State<_TaxPercentEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final percent = widget.taxablePaise > 0
        ? widget.currentTaxPaise * 100 / widget.taxablePaise
        : 0.0;
    _controller = TextEditingController(
      text: widget.currentTaxPaise == 0 && percent == 0
          ? ''
          : OrderCheckoutScreen._formatPercent(percent),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _percent {
    final raw = _controller.text.trim().replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  int get _taxPaise {
    if (widget.taxablePaise <= 0 || _percent <= 0) return 0;
    final rateBp = (_percent * 100).round();
    return roundHalfUp(widget.taxablePaise * rateBp / 10000);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final taxableLabel =
        Money(widget.taxablePaise).format(symbol: widget.symbol);
    final taxLabel = Money(_taxPaise).format(symbol: widget.symbol);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedPercent,
                size: 22,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tax is calculated on taxable amount after discount.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Taxable amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      taxableLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Tax amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      taxLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. 18',
              suffixText: '%',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPercentCircle,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              dismissKeyboard();
              Navigator.pop(context, _taxPaise);
            },
            child: Text(l10n.commonSave),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.line,
    required this.symbol,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartLine line;
  final String symbol;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = line.product;
    final imagePath = product.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: hasImage
                  ? AppImage(
                      path: imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: ColoredBox(
                        color: scheme.primary.withValues(alpha: 0.08),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedPackage01,
                            color: scheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: scheme.primary.withValues(alpha: 0.08),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPackage01,
                          color: scheme.primary,
                          size: 22,
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
                  product.name.displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Money(product.sellingPricePaise).format(symbol: symbol),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roundBtn(
                context,
                icon: HugeIcons.strokeRoundedMinusSign,
                onTap: onDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${line.quantity}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _roundBtn(
                context,
                icon: HugeIcons.strokeRoundedAdd01,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: CircleBorder(
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 16,
              color: scheme.onSurface,
              strokeWidth: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
