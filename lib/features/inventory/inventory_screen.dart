import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  Future<void> _scanStockIn(BuildContext context, WidgetRef ref) async {
    final product = await context.push<Product>('/scan?purpose=stockIn');
    if (product == null || !context.mounted) return;
    final saved = await showAdjustStockSheet(context, product: product);
    if (saved == true) {
      ref.invalidate(productsProvider);
      if (context.mounted) {
        showSnack(context, AppLocalizations.of(context).inventorySaved);
      }
    }
  }

  Future<void> _adjustProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final saved = await showAdjustStockSheet(context, product: product);
    if (saved == true) {
      ref.invalidate(productsProvider);
      if (context.mounted) {
        showSnack(context, AppLocalizations.of(context).inventorySaved);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(productsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.inventoryTitle,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: l10n.inventoryStockIn,
            onPressed: () => _scanStockIn(context, ref),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<bool>('/stock/movement');
          if (saved == true) {
            ref.invalidate(productsProvider);
            ref.invalidate(stockHistoryProvider);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.inventoryStockIn),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(productsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.productsEmptyTitle,
              actionLabel: l10n.productsAddProduct,
              onAction: () => context.push('/products/edit'),
              icon: Icons.warehouse_outlined,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SectionHeader(
                  title: 'Stock overview',
                  actionLabel: 'See all',
                  onAction: () => context.push('/products'),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final low = p.isLowStock;
                    final path = p.imagePath;
                    final hasImage = path != null && path.isNotEmpty;
                    const radius = 7.0;
                    final accent = low ? AppColors.warning : AppColors.success;
                    final cardBg = low
                        ? AppColors.warning.withValues(alpha: 0.08)
                        : scheme.primary.withValues(alpha: 0.06);
                    final borderColor = low
                        ? AppColors.warning.withValues(alpha: 0.28)
                        : scheme.primary.withValues(alpha: 0.18);

                    return Material(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(radius),
                      child: InkWell(
                        onTap: () => _adjustProduct(context, ref, p),
                        onLongPress: () =>
                            context.push('/products/edit?id=${p.id}'),
                        borderRadius: BorderRadius.circular(radius),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: borderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(radius),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: hasImage
                                        ? AppImage(
                                            path: path,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            placeholder: ColoredBox(
                                              color: accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: accent,
                                                size: 22,
                                              ),
                                            ),
                                          )
                                        : ColoredBox(
                                            color: accent.withValues(
                                              alpha: 0.12,
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color: accent,
                                              size: 22,
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
                                        p.name.displayTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.categoryName ?? 'General'} · ${p.unit.toUpperCase()}',
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
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(radius),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${p.currentStock}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                      ),
                                      Text(
                                        low ? 'Low stock' : 'In stock',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: accent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
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
