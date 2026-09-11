import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
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
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Checkout'),
        ),
        body: EmptyState(
          title: 'Cart is empty',
          subtitle: 'Add products from billing to continue.',
          actionLabel: l10n.navBilling,
          onAction: () => context.go('/billing'),
          icon: Icons.shopping_cart_outlined,
        ),
      );
    }

    final orderLabel = InvoiceNumbering.format(
      prefix: store?.invoicePrefix ?? 'INV',
      number: store?.nextInvoiceNumber ?? 1,
    );
    final totalQty = cart.lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final productCount = cart.lines.length;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        centerTitle: true,
        title: Text(
          orderLabel,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Order'),
                  content: const Text(
                    'Review items and customer, then continue to payment. '
                    'Tap Discount or Tax to adjust amounts.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.commonClose),
                    ),
                  ],
                ),
              );
            },
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
                  onTap: () {},
                  child: Row(
                    children: [
                      _softIcon(scheme, Icons.storefront_rounded),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  child: Row(
                    children: [
                      _softIcon(scheme, Icons.person_rounded),
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
                              style: Theme.of(context).textTheme.titleMedium
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
                        icon: const Icon(Icons.edit_outlined, size: 16),
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
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$productCount',
                              style: Theme.of(context).textTheme.titleLarge
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
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalQty',
                                style: Theme.of(context).textTheme.titleLarge
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
                          ref,
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
                        l10n.billingTax,
                        Money(totals.taxPaise).format(symbol: symbol),
                        editable: true,
                        onTap: () => _editAmount(
                          context,
                          ref,
                          title: l10n.billingTax,
                          symbol: symbol,
                          currentPaise: totals.taxPaise,
                          onSave: (paise) => ref
                              .read(cartProvider.notifier)
                              .setTaxOverride(paise),
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
                  child: Text(
                    'Complete payment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softIcon(ColorScheme scheme, IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: scheme.primary, size: 20),
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
                Icon(Icons.edit_outlined, size: 16, color: scheme.primary),
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

  Future<void> _editAmount(
    BuildContext context,
    WidgetRef ref, {
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
                    color: Theme.of(context).colorScheme.outline,
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
                      ? EmptyState(title: l10n.customersEmpty)
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
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
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
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: scheme.primary,
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: scheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: scheme.primary,
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
                icon: Icons.remove_rounded,
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
                icon: Icons.add_rounded,
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
    required IconData icon,
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
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
