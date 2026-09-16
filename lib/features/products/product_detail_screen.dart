import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final productDetailProvider = FutureProvider.autoDispose.family<Product?, int>((
  ref,
  id,
) async {
  return ref.watch(productRepositoryProvider).getProduct(id);
});

final productRecentStockProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, int>((ref, id) {
      return ref
          .watch(stockRepositoryProvider)
          .history(productId: id, limit: 3);
    });

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: GlassPageHeader(
            title: 'Product Details',
            subtitle: 'View and manage product information',
            height: 64,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: ErrorState(
            onRetry: () => ref.invalidate(productDetailProvider(productId)),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Scaffold(
              backgroundColor: scheme.surfaceContainerLowest,
              appBar: GlassPageHeader(
                title: 'Product Details',
                subtitle: 'View and manage product information',
                height: 64,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              body: const EmptyState(
                title: 'Product not found',
                subtitle: 'It may have been removed.',
                showIcon: false,
              ),
            );
          }
          return _ProductDetailBody(product: product, symbol: symbol);
        },
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  const _ProductDetailBody({required this.product, required this.symbol});

  final Product product;
  final String symbol;

  double _stockHealth(Product p) {
    if (p.currentStock <= 0) return 0;
    if (p.minimumStock <= 0) return 100;
    final target = p.minimumStock * 2;
    return ((p.currentStock / target) * 100).clamp(0, 100);
  }

  String _movementLabel(StockMovement m) {
    if (m.isIn) {
      if (m.type == StockTxn.purchase) return 'Purchase';
      if (m.type == StockTxn.opening) return 'Opening';
      if (m.type == StockTxn.refund) return 'Return';
      return 'Stock in';
    }
    if (m.type == StockTxn.sale) {
      final inv = m.referenceLabel;
      if (inv != null && inv.isNotEmpty) return 'Sale - Order #$inv';
      return 'Sale';
    }
    return m.note?.trim().isNotEmpty == true ? m.note!.trim() : 'Stock out';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final p = product;
    final dateFmt = DateFormat('dd/MM/yyyy hh:mm a');
    final created = dateFmt.format(
      DateTime.fromMillisecondsSinceEpoch(p.createdAt),
    );
    final updated = dateFmt.format(
      DateTime.fromMillisecondsSinceEpoch(p.updatedAt),
    );
    final profitPaise = p.sellingPricePaise - p.purchasePricePaise;
    final profitPct = p.purchasePricePaise > 0
        ? (profitPaise * 100 / p.purchasePricePaise)
        : (profitPaise > 0 ? 100.0 : 0.0);
    final profitPositive = profitPaise >= 0;
    final profitColor = profitPositive ? AppColors.success : AppColors.danger;
    final health = _stockHealth(p);
    final healthColor = p.isOutOfStock
        ? AppColors.danger
        : p.isLowStock
        ? AppColors.warning
        : AppColors.success;
    final movements = ref.watch(productRecentStockProvider(p.id));
    final path = p.imagePath;
    final hasImage = path != null && path.isNotEmpty;
    final category = p.categoryName?.displayTitle;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: 'Product Details',
        subtitle: 'View and manage product information',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: hasImage
                            ? AppImage(
                                path: path,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                placeholder: _thumb(scheme),
                              )
                            : _thumb(scheme),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category != null && category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                category,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            p.name.displayTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.isActive ? 'Active product' : 'Inactive product',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          _metaRow(
                            context,
                            Icons.grid_view_rounded,
                            'SKU',
                            p.sku?.isNotEmpty == true ? p.sku! : '—',
                          ),
                          _metaRow(
                            context,
                            Icons.qr_code_2_rounded,
                            'Barcode',
                            p.primaryBarcode ?? '—',
                          ),
                          _metaRow(
                            context,
                            Icons.sell_outlined,
                            'Category',
                            category ?? '—',
                          ),
                          _metaRow(
                            context,
                            Icons.calendar_today_outlined,
                            'Created',
                            created,
                          ),
                          _metaRow(
                            context,
                            Icons.update_rounded,
                            'Updated',
                            updated,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      context,
                      icon: HugeIcons.strokeRoundedWallet01,
                      color: AppColors.success,
                      title: 'Pricing',
                      subtitle: 'Cost and selling price details.',
                    ),
                    const SizedBox(height: 14),
                    _priceRow(
                      context,
                      'Cost Price',
                      Money(p.purchasePricePaise).format(symbol: symbol),
                    ),
                    const SizedBox(height: 8),
                    _priceRow(
                      context,
                      'Selling Price',
                      Money(p.sellingPricePaise).format(symbol: symbol),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: profitColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: profitColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: profitPositive
                                    ? HugeIcons.strokeRoundedAnalyticsUp
                                    : HugeIcons.strokeRoundedAnalyticsDown,
                                size: 18,
                                color: profitColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profit Margin',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  '${profitPositive ? '+' : ''}${Money(profitPaise).format(symbol: symbol)}',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: profitColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Profit %',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                '${profitPositive ? '+' : ''}${profitPct.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: profitColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      context,
                      icon: HugeIcons.strokeRoundedPackage,
                      color: scheme.primary,
                      title: 'Stock Information',
                      subtitle: 'Current stock and alert settings.',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Stock',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${p.currentStock} ${p.unit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _stockStat(
                                context,
                                icon: Icons.notifications_active_outlined,
                                iconColor: AppColors.danger,
                                label: 'Min Stock Alert',
                                value: '${p.minimumStock} ${p.unit}',
                              ),
                              const SizedBox(height: 10),
                              _stockStat(
                                context,
                                icon: Icons.monitor_heart_outlined,
                                iconColor: AppColors.success,
                                label: 'Stock Health',
                                value: '${health.toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: health / 100,
                        minHeight: 8,
                        backgroundColor: scheme.outline.withValues(alpha: 0.35),
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _sectionHeader(
                            context,
                            icon: HugeIcons.strokeRoundedClock01,
                            color: const Color(0xFF7C3AED),
                            title: 'Recent Stock Movements',
                            subtitle: 'Latest in and out transactions.',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                    .read(stockHistorySearchProvider.notifier)
                                    .state =
                                p.name;
                            context.push('/stock/history');
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View All'),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    movements.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Unable to load movements'),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                            child: Text(
                              'No stock movements yet.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final m in items) ...[
                              _movementRow(
                                context,
                                movement: m,
                                label: _movementLabel(m),
                                when: dateFmt.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    m.createdAt,
                                  ),
                                ),
                              ),
                              if (m != items.last)
                                Divider(
                                  height: 1,
                                  color: scheme.outline.withValues(alpha: 0.4),
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
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
          size: 32,
          color: scheme.primary,
        ),
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(icon: icon, size: 20, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _stockStat(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _movementRow(
    BuildContext context, {
    required StockMovement movement,
    required String label,
    required String when,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final inMove = movement.isIn;
    final color = inMove ? AppColors.success : AppColors.danger;
    final qty = movement.quantity.abs();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              inMove ? 'IN' : 'OUT',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inMove ? '+' : '-'}$qty ${movement.productUnit}',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            when,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
