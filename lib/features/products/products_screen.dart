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

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  Future<void> _showProductActions(
    BuildContext context,
    WidgetRef ref, {
    required Product product,
    required bool inactiveMode,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.visibility_rounded, color: scheme.primary),
                  title: const Text('View details'),
                  subtitle: const Text('Pricing, stock & movements'),
                  onTap: () => Navigator.pop(ctx, 'view'),
                ),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: scheme.primary),
                  title: const Text('Update'),
                  subtitle: const Text('Edit product details'),
                  onTap: () => Navigator.pop(ctx, 'update'),
                ),
                ListTile(
                  leading: Icon(
                    inactiveMode
                        ? Icons.restart_alt_rounded
                        : Icons.visibility_off_outlined,
                    color: inactiveMode ? AppColors.success : scheme.error,
                  ),
                  title: Text(inactiveMode ? 'Activate' : 'Deactivate'),
                  subtitle: Text(
                    inactiveMode
                        ? 'Show this product in billing again'
                        : 'Hide this product from billing',
                  ),
                  onTap: () => Navigator.pop(ctx, 'toggle'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;

    if (action == 'view') {
      context.push('/products/view?id=${product.id}');
      return;
    }

    if (action == 'update') {
      context.push('/products/edit?id=${product.id}');
      return;
    }

    if (inactiveMode) {
      final ok = await confirmDialog(
        context,
        title: 'Activate product',
        body: 'Show "${product.name}" in billing and catalogs again?',
        icon: Icons.restart_alt_rounded,
        confirmLabel: 'Activate',
      );
      if (!ok) return;
      await ref.read(productRepositoryProvider).activateProduct(product.id);
    } else {
      final ok = await confirmDialog(
        context,
        title: 'Deactivate product',
        body:
            'Hide "${product.name}" from billing and catalogs? This is not a permanent delete — you can activate it again from the Inactive filter.',
        icon: Icons.visibility_off_outlined,
        confirmLabel: 'Deactivate',
        destructive: true,
      );
      if (!ok) return;
      await ref.read(productRepositoryProvider).deactivateProduct(product.id);
    }
    ref.invalidate(productsProvider);
    ref.invalidate(productFilterCountsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(productsProvider);
    final query = ref.watch(catalogQueryProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;
    final counts = ref.watch(productFilterCountsProvider).valueOrNull;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.productsTitle,
        subtitle: 'Catalog, prices & stock',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Scan',
            onPressed: () => context.push('/scan?purpose=lookup'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/edit'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.productsAddProduct),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: l10n.commonSearch,
              onChanged: (v) => ref.read(catalogQueryProvider.notifier).state =
                  query.copyWith(search: v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SoftPeriodBadge(
                  label: 'All (${counts?.all ?? 0})',
                  selected: !query.lowStock &&
                      !query.outOfStock &&
                      !query.inactiveOnly,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        lowStock: false,
                        outOfStock: false,
                        inactiveOnly: false,
                      ),
                ),
                SoftPeriodBadge(
                  label:
                      '${l10n.productsLowStockFilter} (${counts?.lowStock ?? 0})',
                  selected: query.lowStock,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        lowStock: !query.lowStock,
                        outOfStock: false,
                        inactiveOnly: false,
                      ),
                ),
                SoftPeriodBadge(
                  label:
                      '${l10n.productsOutOfStockFilter} (${counts?.outOfStock ?? 0})',
                  selected: query.outOfStock,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        outOfStock: !query.outOfStock,
                        lowStock: false,
                        inactiveOnly: false,
                      ),
                ),
                SoftPeriodBadge(
                  label: 'Inactive (${counts?.inactive ?? 0})',
                  selected: query.inactiveOnly,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        inactiveOnly: !query.inactiveOnly,
                        lowStock: false,
                        outOfStock: false,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  ErrorState(onRetry: () => ref.invalidate(productsProvider)),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No products found',
                    subtitle:
                        'Add products to start selling and tracking stock.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return _ProductListCard(
                      product: p,
                      symbol: symbol,
                      stockLabel: l10n.productsStock,
                      onTap: () => context.push('/products/view?id=${p.id}'),
                      onLongPress: () => _showProductActions(
                        context,
                        ref,
                        product: p,
                        inactiveMode: query.inactiveOnly,
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

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({
    required this.product,
    required this.symbol,
    required this.stockLabel,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;
  final String symbol;
  final String stockLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = product;
    final path = p.imagePath;
    final hasImage = path != null && path.isNotEmpty;
    final out = p.currentStock <= 0;
    final low = !out && p.isLowStock;
    final statusLabel = !p.isActive
        ? 'Inactive'
        : out
            ? 'Out of stock'
            : low
                ? 'Low stock'
                : 'In stock';
    final meta = [
      p.primaryBarcode ?? p.sku ?? '—',
      '$stockLabel: ${p.currentStock}',
      statusLabel,
    ].join(' • ');

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: onTap,
      onLongPress: onLongPress,
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
                      placeholder: _thumbPlaceholder(scheme),
                    )
                  : _thumbPlaceholder(scheme),
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
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _thumbPlaceholder(ColorScheme scheme) {
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
