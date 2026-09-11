import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(productsProvider);
    final query = ref.watch(catalogQueryProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.productsTitle,
        actions: [
          IconButton(
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
                  label: 'All',
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
                  label: l10n.productsLowStockFilter,
                  selected: query.lowStock,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        lowStock: !query.lowStock,
                        inactiveOnly: false,
                      ),
                ),
                SoftPeriodBadge(
                  label: l10n.productsOutOfStockFilter,
                  selected: query.outOfStock,
                  onTap: () => ref.read(catalogQueryProvider.notifier).state =
                      query.copyWith(
                        outOfStock: !query.outOfStock,
                        inactiveOnly: false,
                      ),
                ),
                SoftPeriodBadge(
                  label: 'Inactive',
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
          const SizedBox(height: 8),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  ErrorState(onRetry: () => ref.invalidate(productsProvider)),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: l10n.productsEmptyTitle,
                    subtitle: l10n.productsEmptyBody,
                    actionLabel: l10n.productsAddProduct,
                    onAction: () => context.push('/products/edit'),
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final low = p.isLowStock;
                    final path = p.imagePath;
                    final hasImage = path != null && path.isNotEmpty;
                    return SoftCard(
                      radius: AppRadii.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onTap: () => context.push('/products/edit?id=${p.id}'),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.compact),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: hasImage
                                  ? AppImage(
                                      path: path,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: ColoredBox(
                                        color: scheme.primary
                                            .withValues(alpha: 0.08),
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          color: scheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : ColoredBox(
                                      color: scheme.primary
                                          .withValues(alpha: 0.08),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: scheme.primary,
                                        size: 20,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${p.primaryBarcode ?? p.sku ?? '—'} · ${p.categoryName ?? 'General'} · ${p.unit.toUpperCase()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Money(p.sellingPricePaise)
                                    .format(symbol: symbol),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${l10n.productsStock}: ${p.currentStock}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: low
                                          ? AppColors.warning
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: query.inactiveOnly
                                ? 'Activate'
                                : 'Deactivate',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () async {
                              if (query.inactiveOnly) {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'Activate product',
                                  body:
                                      'Show "${p.name}" in billing and catalogs again?',
                                  icon: Icons.restart_alt_rounded,
                                  confirmLabel: 'Activate',
                                );
                                if (!ok) return;
                                await ref
                                    .read(productRepositoryProvider)
                                    .activateProduct(p.id);
                              } else {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'Deactivate product',
                                  body:
                                      'Hide "${p.name}" from billing and catalogs? This is not a permanent delete — you can activate it again from the Inactive filter.',
                                  icon: Icons.visibility_off_outlined,
                                  confirmLabel: 'Deactivate',
                                  destructive: true,
                                );
                                if (!ok) return;
                                await ref
                                    .read(productRepositoryProvider)
                                    .deactivateProduct(p.id);
                              }
                              ref.invalidate(productsProvider);
                            },
                            icon: Icon(
                              query.inactiveOnly
                                  ? Icons.restart_alt_rounded
                                  : Icons.visibility_off_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
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
