import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/premium_access.dart';
import 'package:pos_billing/features/premium/premium_sheets.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  String _typeLabel(StockMovement m) {
    if (m.isIn) {
      if (m.type == StockTxn.purchase) return 'PURCHASE';
      if (m.type == StockTxn.opening) return 'OPENING';
      if (m.type == StockTxn.refund) return 'RETURN';
      return 'IN';
    }
    if (m.type == StockTxn.sale) return 'SALE';
    return 'OUT';
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
    final dateFmt = DateFormat('dd-MMM-yyyy hh:mm:ss a');

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
          final allowed = await ensurePremiumQuota(
            context: context,
            ref: ref,
            kind: PremiumQuotaKind.stocks,
          );
          if (!allowed || !context.mounted) return;
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
                  return const EmptyState(
                    title: 'No stock movements',
                    subtitle: 'Stock in and stock out activity will show here.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                    final subtitle = [
                      when,
                      _typeLabel(m),
                      ?refHint,
                    ].join(' · ');

                    return SoftCard(
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              inMove
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${inMove ? '+' : '-'}$qtyAbs ${m.productUnit}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: color,
                                    ),
                              ),
                              if (pricePaise > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  Money(pricePaise).format(symbol: symbol),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
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
    );
  }
}
