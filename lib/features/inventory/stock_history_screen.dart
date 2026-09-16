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
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  String _typeLabel(StockMovement m) {
    if (m.isIn) {
      if (m.type == StockTxn.purchase) return 'Purchase';
      if (m.type == StockTxn.opening) return 'Opening';
      if (m.type == StockTxn.refund) return 'Return';
      return 'Stock in';
    }
    if (m.type == StockTxn.sale) return 'Sale';
    return 'Stock out';
  }

  String? _refHint(StockMovement m) {
    if (m.referenceType == 'invoice' &&
        (m.referenceLabel?.isNotEmpty ?? false)) {
      return m.referenceLabel;
    }
    final note = m.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final filter = ref.watch(stockHistoryFilterProvider);
    final history = ref.watch(stockHistoryProvider);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<bool>('/stock/movement');
          if (saved == true) {
            ref.invalidate(stockHistoryProvider);
            ref.invalidate(productsProvider);
            ref.invalidate(inventoryProductsProvider);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add movement'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canPop) ...[
                    Material(
                      color: scheme.primary.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock History',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock in, stock out & adjustments',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
            const SizedBox(height: 10),
            Expanded(
              child: history.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ErrorState(
                  onRetry: () => ref.invalidate(stockHistoryProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'No stock movements',
                      subtitle:
                          'Stock in and stock out activity will show here.',
                      showIcon: false,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = items[i];
                      final inMove = m.isIn;
                      final color =
                          inMove ? AppColors.success : AppColors.danger;
                      final qtyAbs = m.quantity.abs();
                      final pricePaise = inMove
                          ? (m.unitCostPaise ?? 0)
                          : m.sellingPricePaise;
                      final when = dateFmt.format(
                        DateTime.fromMillisecondsSinceEpoch(m.createdAt),
                      );
                      final refHint = _refHint(m);
                      final meta = [
                        when,
                        _typeLabel(m),
                        ?refHint,
                      ].join(' • ');

                      return SoftCard(
                        radius: AppRadii.md,
                        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: ColoredBox(
                                  color: color.withValues(alpha: 0.12),
                                  child: Center(
                                    child: HugeIcon(
                                      icon: inMove
                                          ? HugeIcons.strokeRoundedArrowUp01
                                          : HugeIcons.strokeRoundedArrowDown01,
                                      size: 22,
                                      color: color,
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
                                    (m.productName ?? 'Product').displayTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    meta,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${inMove ? '+' : '-'}$qtyAbs ${m.productUnit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                ),
                                if (pricePaise > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    Money(pricePaise).format(symbol: symbol),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
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
      ),
    );
  }
}
