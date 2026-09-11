import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  String _relative(int ms) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd/MM/yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  String _typeLabel(StockMovement m) {
    if (m.isIn) {
      if (m.type == StockTxn.purchase) return 'Purchase';
      if (m.type == StockTxn.opening) return 'Opening';
      if (m.type == StockTxn.refund) return 'Return';
      return 'Stock IN';
    }
    if (m.type == StockTxn.sale) return 'Sale';
    return 'Stock OUT';
  }

  String? _refLine(StockMovement m) {
    if (m.referenceType == 'invoice' &&
        (m.referenceLabel?.isNotEmpty ?? false)) {
      return '${_typeLabel(m)} · ${m.referenceLabel}';
    }
    if (m.note != null && m.note!.trim().isNotEmpty) {
      return m.note!.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final filter = ref.watch(stockHistoryFilterProvider);
    final history = ref.watch(stockHistoryProvider);

    return Scaffold(
      appBar: GlassPageHeader(
        title: 'Stock History',
        actions: [
          IconButton(
            tooltip: 'Stock overview',
            onPressed: () => context.push('/stock/overview'),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/stock/movement');
          if (saved == true) {
            ref.invalidate(stockHistoryProvider);
            ref.invalidate(productsProvider);
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: 'Search by product name or SKU',
              onChanged: (v) =>
                  ref.read(stockHistorySearchProvider.notifier).state = v,
              trailing: IconButton(
                tooltip: 'Scan',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final product =
                      await context.push<Product>('/scan?purpose=stockIn');
                  if (product == null) return;
                  ref.read(stockHistorySearchProvider.notifier).state =
                      product.name;
                },
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SoftPeriodBadge(
                  label: 'All',
                  selected: filter == StockHistoryFilter.all,
                  onTap: () => ref
                      .read(stockHistoryFilterProvider.notifier)
                      .state = StockHistoryFilter.all,
                ),
                SoftPeriodBadge(
                  label: 'Stock IN',
                  selected: filter == StockHistoryFilter.stockIn,
                  onTap: () => ref
                      .read(stockHistoryFilterProvider.notifier)
                      .state = StockHistoryFilter.stockIn,
                ),
                SoftPeriodBadge(
                  label: 'Stock OUT',
                  selected: filter == StockHistoryFilter.stockOut,
                  onTap: () => ref
                      .read(stockHistoryFilterProvider.notifier)
                      .state = StockHistoryFilter.stockOut,
                ),
              ],
            ),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(stockHistoryProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: 'No stock movements',
                    subtitle: 'Add stock in or adjust qty with the + button.',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final inMove = m.isIn;
                    final badgeColor =
                        inMove ? AppColors.success : AppColors.danger;
                    final qtyAbs = m.quantity.abs();
                    final pricePaise = inMove
                        ? (m.unitCostPaise ?? 0)
                        : m.sellingPricePaise;
                    final when = DateTime.fromMillisecondsSinceEpoch(
                      m.createdAt,
                    );
                    final refLine = _refLine(m);

                    return SoftCard(
                      radius: 10,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (m.productName ?? 'Product')
                                          .displayTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (m.productSku != null &&
                                        m.productSku!.isNotEmpty)
                                      Text(
                                        'SKU: ${m.productSku}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  inMove ? '＋ IN' : '➖ OUT',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: badgeColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                inMove
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 16,
                                color: badgeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${inMove ? '+' : '-'}$qtyAbs ${m.productUnit}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: badgeColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (pricePaise > 0) ...[
                                const SizedBox(width: 10),
                                Text(
                                  Money(pricePaise).format(symbol: symbol),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          if (refLine != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              refLine,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _relative(m.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('dd/MM/yyyy hh:mm a').format(when),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
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
