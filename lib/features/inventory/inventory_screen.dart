import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  bool _lowStockOnly = false;
  int? _categoryId;

  Future<void> _scanLookup() async {
    final product = await context.push<Product>('/scan?purpose=lookup');
    if (product == null || !mounted) return;
    setState(() => _search = product.name);
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Categories'),
                trailing: _categoryId == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              for (final c in categories)
                ListTile(
                  title: Text(c.name.displayTitle),
                  trailing: _categoryId == c.id
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(ctx, c.id),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _categoryId = selected < 0 ? null : selected);
  }

  Future<void> _onProductTap(Product product) async {
    await context.push('/products/view?id=${product.id}');
    if (!mounted) return;
    ref.invalidate(inventoryProductsProvider);
    ref.invalidate(productsProvider);
  }

  List<Product> _filter(List<Product> items) {
    final q = _search.trim().toLowerCase();
    return items.where((p) {
      if (!p.isActive) return false;
      if (_lowStockOnly && !p.isLowStock) return false;
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (q.isEmpty) return true;
      final hay = [
        p.name,
        p.sku ?? '',
        p.primaryBarcode ?? '',
        ...p.barcodes,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(inventoryProductsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;
    final categoryName = _categoryId == null
        ? 'All Categories'
        : (categories
                .where((c) => c.id == _categoryId)
                .map((c) => c.name.displayTitle)
                .firstOrNull ??
            'All Categories');

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.inventoryTitle,
        subtitle: 'Products, availability & stock',
        height: 64,
        actions: [
          // IconButton(
          //   tooltip: 'Filter',
          //   onPressed: () => setState(() => _lowStockOnly = !_lowStockOnly),
          //   icon: Icon(
          //     Icons.filter_list_rounded,
          //     color: _lowStockOnly ? scheme.primary : null,
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/products/edit'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.productsAddProduct),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/stock/history'),
                  icon: const Icon(Icons.history_rounded),
                  label: Text(l10n.inventoryHistory),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: 'Search products by name, SKU, or barcode',
              onChanged: (v) => setState(() => _search = v),
              trailing: IconButton(
                tooltip: 'Scan',
                visualDensity: VisualDensity.compact,
                onPressed: _scanLookup,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SoftPeriodBadge(
                  label: categoryName,
                  selected: _categoryId != null,
                  onTap: () => _pickCategory(categories),
                ),
                SoftPeriodBadge(
                  label: l10n.productsLowStockFilter,
                  selected: _lowStockOnly,
                  onTap: () => setState(() => _lowStockOnly = !_lowStockOnly),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(inventoryProductsProvider),
              ),
              data: (items) {
                final visible = _filter(items);
                if (visible.isEmpty) {
                  return const EmptyState(
                    title: 'No inventory items',
                    subtitle:
                        'Add products to track available stock and status here.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = visible[i];
                    return _InventoryProductCard(
                      product: p,
                      symbol: symbol,
                      onTap: () => _onProductTap(p),
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

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.product,
    required this.symbol,
    required this.onTap,
  });

  final Product product;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = product;
    final path = p.imagePath;
    final hasImage = path != null && path.isNotEmpty;
    final out = p.isOutOfStock;
    final low = !out && p.isLowStock;
    final statusLabel = out
        ? 'Out of stock'
        : low
            ? 'Low stock'
            : 'In stock';
    final statusColor = out
        ? AppColors.danger
        : low
            ? AppColors.warning
            : AppColors.success;

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: hasImage
                  ? AppImage(
                      path: path,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: _thumb(scheme),
                    )
                  : _thumb(scheme),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name.displayTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${p.currentStock} ${p.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          const SizedBox(width: 10),
          Text(
            Money(p.sellingPricePaise).format(symbol: symbol),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedPackage,
          size: 22,
          color: scheme.primary,
        ),
      ),
    );
  }
}

Future<bool?> showAdjustStockSheet(
  BuildContext context, {
  required Product product,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AdjustStockSheet(product: product),
  );
}

class _AdjustStockSheet extends ConsumerStatefulWidget {
  const _AdjustStockSheet({required this.product});

  final Product product;

  @override
  ConsumerState<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<_AdjustStockSheet> {
  late final TextEditingController _qty;
  late final TextEditingController _reason;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: '${widget.product.currentStock}');
    _reason = TextEditingController(text: 'Manual stock update');
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    dismissKeyboard();
    final l10n = AppLocalizations.of(context);
    final newStock = int.tryParse(_qty.text.trim());
    final reason = _reason.text.trim();
    if (newStock == null || newStock < 0) {
      showSnack(context, l10n.errorsValidation);
      return;
    }
    if (reason.isEmpty) {
      showSnack(context, l10n.inventoryReasonRequired);
      return;
    }

    final delta = newStock - widget.product.currentStock;
    if (delta == 0) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(stockRepositoryProvider).adjustStock(
            productId: widget.product.id,
            delta: delta,
            reason: reason,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.inventoryAdjust,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.name.displayTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.inventoryCurrentStock,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qty,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.inventoryAdjustment,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reason,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Reason',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.inventorySaveAdjustment),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            final id = widget.product.id;
                            final router = GoRouter.of(context);
                            Navigator.pop(context, false);
                            router.push('/products/edit?id=$id');
                          },
                    child: const Text('Edit product'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
