import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
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
  final _search = TextEditingController();
  final _qty = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  Product? _product;
  bool _isIn = true;
  bool _saving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    if (_product != null) {
      _cost.text = Money(_product!.purchasePricePaise).formatForField();
    }
  }

  @override
  void dispose() {
    _search.dispose();
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

  Future<void> _scan() async {
    final product = await context.push<Product>('/scan?purpose=stockIn');
    if (product == null || !mounted) return;
    setState(() {
      _product = product;
      _search.text = product.name;
      _query = product.name;
      if (_cost.text.trim().isEmpty) {
        _cost.text = Money(product.purchasePricePaise).formatForField();
      }
    });
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
      if (mounted) showSnack(context, 'Unable to save stock movement');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final products = ref.watch(productsProvider).valueOrNull ?? const [];
    final q = _query.trim().toLowerCase();
    final matches = q.isEmpty
        ? const <Product>[]
        : products
            .where((p) {
              final name = p.name.toLowerCase();
              final sku = (p.sku ?? '').toLowerCase();
              final barcodes = p.barcodes.map((e) => e.toLowerCase());
              return name.contains(q) ||
                  sku.contains(q) ||
                  barcodes.any((b) => b.contains(q));
            })
            .take(8)
            .toList();

    return Scaffold(
      appBar: GlassPageHeader(
        title: 'Add Stock Movement',
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
                    'SELECT PRODUCT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SoftSearchField(
                          controller: _search,
                          hintText: 'Search by name, SKU, or barcode',
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _scan,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 48,
                            height: 44,
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_product != null) ...[
                    const SizedBox(height: 10),
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
                                Text(
                                  'Stock: ${_product!.currentStock} ${_product!.unit}',
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
                            onPressed: () => setState(() {
                              _product = null;
                              _search.clear();
                              _query = '';
                            }),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  ] else if (matches.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SoftCard(
                      radius: 10,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < matches.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            ListTile(
                              dense: true,
                              title: Text(matches[i].name.displayTitle),
                              subtitle: Text(
                                matches[i].sku ??
                                    'Stock ${matches[i].currentStock}',
                              ),
                              onTap: () => setState(() {
                                _product = matches[i];
                                _search.text = matches[i].name;
                                _query = matches[i].name;
                                _cost.text = Money(matches[i].purchasePricePaise)
                                    .formatForField();
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'MOVEMENT DETAILS',
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
                          label: 'Stock IN',
                          icon: Icons.add_circle_outline_rounded,
                          color: AppColors.success,
                          onTap: () => setState(() => _isIn = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeChip(
                          selected: !_isIn,
                          label: 'Stock OUT',
                          icon: Icons.remove_circle_outline_rounded,
                          color: scheme.onSurfaceVariant,
                          onTap: () => setState(() => _isIn = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _qty,
                    label: 'Quantity',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixIcon: Icons.inventory_2_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_isIn) ...[
                    const SizedBox(height: 12),
                    _Field(
                      controller: _cost,
                      label: 'Cost Price',
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
                    label: 'Notes (Required)',
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
                    child: Text(_saving ? 'Saving…' : 'Save Movement'),
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
