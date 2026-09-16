import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/repositories/product_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class AddStockMovementScreen extends ConsumerStatefulWidget {
  const AddStockMovementScreen({super.key, this.initialProduct});

  final Product? initialProduct;

  @override
  ConsumerState<AddStockMovementScreen> createState() =>
      _AddStockMovementScreenState();
}

class _AddStockMovementScreenState
    extends ConsumerState<AddStockMovementScreen> {
  late String _defaultNoteIn;
  late String _defaultNoteOut;
  bool _defaultNotesReady = false;

  final _qty = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  Product? _product;
  bool _isIn = true;
  bool _saving = false;
  List<Product> _allProducts = const [];
  bool _catalogLoaded = false;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    if (_product != null) {
      _cost.text = Money(_product!.purchasePricePaise).formatForField();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultNotesReady) return;
    final l10n = AppLocalizations.of(context);
    _defaultNoteIn = l10n.inventoryStockIn;
    _defaultNoteOut = l10n.inventoryStockOut;
    if (_notes.text.isEmpty) {
      _notes.text = _isIn ? _defaultNoteIn : _defaultNoteOut;
    }
    _defaultNotesReady = true;
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_product == null || _saving) return false;
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    if (qty <= 0) return false;
    if (_notes.text.trim().isEmpty) return false;
    if (_isIn && parseRupeesToPaise(_cost.text) <= 0) return false;
    return true;
  }

  bool get _notesAreDefault {
    final n = _notes.text.trim();
    if (!_defaultNotesReady) return n.isEmpty;
    return n.isEmpty || n == _defaultNoteIn || n == _defaultNoteOut;
  }

  void _setMovementType(bool isIn) {
    setState(() {
      _isIn = isIn;
      if (_notesAreDefault) {
        _notes.text = isIn ? _defaultNoteIn : _defaultNoteOut;
      }
    });
  }

  Future<List<Product>> _ensureCatalog() async {
    if (_catalogLoaded) return _allProducts;
    final store = await ref.read(storeProfileProvider.future);
    if (store == null) return const [];
    final results = await ref.read(productRepositoryProvider).getProducts(
          store.id,
          const ProductQuery(activeOnly: true, limit: 1000),
        );
    _allProducts = results;
    _catalogLoaded = true;
    return _allProducts;
  }

  void _selectProduct(Product product) {
    setState(() {
      _product = product;
      _cost.text = Money(product.purchasePricePaise).formatForField();
    });
  }

  Future<void> _openProductPicker() async {
    final products = await _ensureCatalog();
    if (!mounted) return;

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        products: products,
        selectedId: _product?.id,
        onScan: () async {
          Navigator.pop(ctx);
          final scanned = await context.push<Product>('/scan?purpose=stockIn');
          if (scanned != null && mounted) _selectProduct(scanned);
        },
      ),
    );

    if (selected != null && mounted) {
      _selectProduct(selected);
    }
  }

  Future<void> _save() async {
    if (!_canSave || _product == null) return;
    final l10n = AppLocalizations.of(context);
    final qty = int.parse(_qty.text.trim());
    final notes = _notes.text.trim();
    setState(() => _saving = true);
    try {
      final stock = ref.read(stockRepositoryProvider);
      if (_isIn) {
        await stock.addStock(
          productId: _product!.id,
          quantity: qty,
          unitCost: parseRupeesToPaise(_cost.text),
          note: notes,
        );
      } else {
        await stock.adjustStock(
          productId: _product!.id,
          delta: -qty,
          reason: notes,
        );
      }
      ref.invalidate(stockHistoryProvider);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      showSnack(context, l10n.inventorySaved);
      context.pop(true);
    } catch (_) {
      if (mounted) showSnack(context, l10n.errorsDatabase);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _productMeta(AppLocalizations l10n, Product p) {
    return [
      if ((p.sku ?? '').isNotEmpty) '${l10n.productsSku} ${p.sku}',
      if ((p.categoryName ?? '').isNotEmpty) p.categoryName!,
      '${l10n.productsStock} ${p.currentStock} ${p.unit}',
      if (p.barcodes.isNotEmpty) p.barcodes.first,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.inventoryAddMovementTitle,
        subtitle: l10n.inventoryHistorySubtitle,
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: KeyboardDismissOnTap(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    l10n.productsTitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_product == null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _openProductPicker,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.billingAddProduct),
                      ),
                    )
                  else
                    SoftCard(
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product!.name.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _productMeta(l10n, _product!),
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
                          TextButton(
                            onPressed: _openProductPicker,
                            child: Text(l10n.commonChange),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.inventoryAddMovementTitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          selected: _isIn,
                          label: l10n.inventoryStockIn,
                          icon: Icons.add_circle_outline_rounded,
                          color: AppColors.success,
                          onTap: () => _setMovementType(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeChip(
                          selected: !_isIn,
                          label: l10n.inventoryStockOut,
                          icon: Icons.remove_circle_outline_rounded,
                          color: AppColors.danger,
                          onTap: () => _setMovementType(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _qty,
                    label: l10n.commonQuantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixIcon: Icons.inventory_2_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_isIn) ...[
                    const SizedBox(height: 12),
                    _Field(
                      controller: _cost,
                      label: l10n.inventoryCostPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [ThousandDecimalFormatter()],
                      prefixIcon: Icons.currency_rupee_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Field(
                    controller: _notes,
                    label: l10n.inventoryNotesRequired,
                    maxLines: 3,
                    prefixIcon: Icons.notes_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(
                      _saving ? l10n.commonSaving : l10n.inventorySaveMovement,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({
    required this.products,
    required this.onScan,
    this.selectedId,
  });

  final List<Product> products;
  final int? selectedId;
  final VoidCallback onScan;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products.where((p) {
      final name = p.name.toLowerCase();
      final sku = (p.sku ?? '').toLowerCase();
      final category = (p.categoryName ?? '').toLowerCase();
      final barcodes = p.barcodes.map((b) => b.toLowerCase());
      return name.contains(q) ||
          sku.contains(q) ||
          category.contains(q) ||
          barcodes.any((b) => b.contains(q));
    }).toList();
  }

  String _meta(AppLocalizations l10n, Product p) {
    return [
      if ((p.sku ?? '').isNotEmpty) '${l10n.productsSku} ${p.sku}',
      if ((p.categoryName ?? '').isNotEmpty) p.categoryName!,
      '${l10n.productsStock} ${p.currentStock} ${p.unit}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.billingAddProduct,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.billingScanBarcode,
                        onPressed: widget.onScan,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SoftSearchField(
                    controller: _search,
                    hintText: l10n.inventorySearchProductHint,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                          child: Text(
                            _query.trim().isEmpty
                                ? l10n.productsEmptyTitle
                                : l10n.productsEmptySearchTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            final selected = p.id == widget.selectedId;
                            return ListTile(
                              title: Text(
                                p.name.displayTitle,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(_meta(l10n, p)),
                              trailing: selected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: scheme.primary,
                                    )
                                  : Icon(
                                      Icons.chevron_right_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? color : scheme.surfaceContainerHighest;
    final fg = selected ? Colors.white : scheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : scheme.outline.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(prefixIcon),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.compact),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.compact),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
