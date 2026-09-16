import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  Future<void> _openProductPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _ProductPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              SoftCard(
                onTap: () => _pickCustomer(),
                child: Row(
                  children: [
                    InitialsAvatar(
                      label: cart.customer?.name ?? 'W',
                      icon: Icons.person_outline_rounded,
                      size: 44,
                    ),
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
                            cart.customer?.name ?? 'Walk-in customer',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _pickCustomer(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(88, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Text(cart.customer == null ? 'Add' : 'Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openProductPicker,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Product'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/scan?purpose=addToCart'),
                    tooltip: 'Scan barcode',
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SoftCard(
                  padding: const EdgeInsets.all(8),
                  child: cart.lines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 42,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No products added',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap Add Product to select items',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(4),
                          itemCount: cart.lines.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final line = cart.lines[index];
                            final product = line.product;
                            final path = product.imagePath;
                            final hasImage =
                                path != null && path.isNotEmpty;
                            final lineTotal = Money(
                              product.sellingPricePaise * line.quantity -
                                  line.itemDiscountPaise,
                            ).format(symbol: symbol);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLowest,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                border: Border.all(
                                  color: scheme.outline
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: hasImage
                                          ? AppImage(
                                              path: path,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              placeholder: ColoredBox(
                                                color: scheme.primary
                                                    .withValues(alpha: 0.10),
                                                child: Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                            )
                                          : ColoredBox(
                                              color: scheme.primary
                                                  .withValues(alpha: 0.10),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name.displayTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${Money(product.sellingPricePaise).format(symbol: symbol)} × ${line.quantity} = $lineTotal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  QtyStepper(
                                    quantity: line.quantity,
                                    onDecrement: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .setQty(
                                            product.id,
                                            line.quantity - 1,
                                          );
                                    },
                                    onIncrement: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .addProduct(product);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryCtaBar(
                enabled: cart.lines.isNotEmpty,
                onTap: () => context.push('/checkout'),
                label: 'Proceed to checkout',
                trailing: Text(
                  '${cart.lines.length} · ${Money(totals.grandTotalPaise).format(symbol: symbol)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomer() async {
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) {
      if (!mounted) return;
      showSnack(context, 'Complete store setup first');
      return;
    }

    final customers =
        await ref.read(customerRepositoryProvider).search(store.id, '');
    if (!mounted) return;

    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.62,
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
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select customer',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, 'walkin'),
                      child: const Text('Walk-in'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, 'add'),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add new customer'),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text('No customers yet. Add a new one.'),
                      )
                    : ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = customers[i];
                          return ListTile(
                            leading: InitialsAvatar(label: c.name, size: 42),
                            title: Text(c.name.displayTitle),
                            subtitle: Text(
                              (c.phone ?? '').isEmpty ? 'No phone' : c.phone!,
                            ),
                            onTap: () => Navigator.pop(sheetContext, c),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == 'walkin') {
      ref.read(cartProvider.notifier).setCustomer(null);
      return;
    }

    if (result == 'add') {
      final createdId = await context.push<int>('/customers/edit');
      if (!mounted) return;
      if (createdId != null) {
        final created =
            await ref.read(customerRepositoryProvider).get(createdId);
        if (created != null) {
          ref.read(cartProvider.notifier).setCustomer(created);
        }
      } else {
        await _pickCustomer();
      }
      return;
    }

    if (result is Customer) {
      ref.read(cartProvider.notifier).setCustomer(result);
    }
  }
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _quantityFor(Product product, List<CartLine> lines) {
    final index = lines.indexWhere((entry) => entry.product.id == product.id);
    if (index < 0) return 0;
    return lines[index].quantity;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? products
        : products.where((product) {
            final haystack = [
              product.name,
              product.sku ?? '',
              product.primaryBarcode ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();

    final selectedCount = cart.lines.fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (selectedCount > 0)
                  SoftInfoBadge(
                    label: '$selectedCount selected',
                    background: scheme.primary.withValues(alpha: 0.12),
                    foreground: scheme.primary,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SoftSearchField(
              controller: _search,
              hintText: 'Search products',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      final quantity = _quantityFor(product, cart.lines);
                      final path = product.imagePath;
                      final hasImage = path != null && path.isNotEmpty;
                      final selected = quantity > 0;
                      final out = product.isOutOfStock;
                      final low = !out && product.isLowStock;
                      final statusLabel = !product.isActive
                          ? 'Inactive'
                          : out
                              ? 'Out of stock'
                              : low
                                  ? 'Low stock'
                                  : 'In stock';
                      final statusColor = !product.isActive
                          ? scheme.onSurfaceVariant
                          : out
                              ? AppColors.danger
                              : low
                                  ? AppColors.warning
                                  : AppColors.success;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.primary.withValues(alpha: 0.08)
                              : scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.55),
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: hasImage
                                    ? AppImage(
                                        path: path,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        placeholder: ColoredBox(
                                          color: scheme.primary
                                              .withValues(alpha: 0.10),
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: scheme.primary
                                            .withValues(alpha: 0.10),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Money(product.sellingPricePaise)
                                        .format(symbol: symbol),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${product.currentStock} ${product.unit}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            QtyStepper(
                              quantity: quantity,
                              onDecrement: () {
                                if (quantity <= 0) return;
                                ref.read(cartProvider.notifier).setQty(
                                      product.id,
                                      quantity - 1,
                                    );
                              },
                              onIncrement: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addProduct(product);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    selectedCount > 0
                        ? 'Done ($selectedCount)'
                        : 'Done',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
