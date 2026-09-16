import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/repositories/product_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/features/products/category_create_sheet.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/image_source_sheet.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

const _fieldRadius = 5.0;

const _productUnits = <String>[
  'pcs',
  'kg',
  'g',
  'liter',
  'ml',
  'dozen',
  'box',
];

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId, this.initialBarcode});

  final int? productId;
  final String? initialBarcode;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _purchase = TextEditingController();
  final _selling = TextEditingController();
  final _tax = TextEditingController();
  final _min = TextEditingController(text: '10');
  final _opening = TextEditingController();
  String _unit = 'pcs';
  int? _categoryId;
  String? _imagePath;
  Product? _existing;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _barcode.text = widget.initialBarcode ?? '';
    _load();
  }

  Future<void> _load() async {
    if (widget.productId != null) {
      _existing = await ref
          .read(productRepositoryProvider)
          .getProduct(widget.productId!);
      if (_existing != null && mounted) {
        _name.text = _existing!.name;
        _sku.text = _existing!.sku ?? '';
        _barcode.text = _existing!.barcodes.isEmpty
            ? ''
            : _existing!.barcodes.first;
        _unit = _productUnits.contains(_existing!.unit)
            ? _existing!.unit
            : 'pcs';
        _purchase.text =
            Money(_existing!.purchasePricePaise).formatForField();
        _selling.text = Money(_existing!.sellingPricePaise).formatForField();
        _tax.text = (_existing!.taxRateBp / 100).toString();
        _min.text = '${_existing!.minimumStock}';
        _opening.text = '${_existing!.currentStock}';
        _categoryId = _existing!.categoryId;
        _imagePath = _existing!.imagePath;
      }
    } else if (_sku.text.trim().isEmpty && mounted) {
      _generateSku();
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _purchase.dispose();
    _selling.dispose();
    _tax.dispose();
    _min.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _generateSku() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = (stamp % 1000000).toString().padLeft(6, '0');
    final noise = Random().nextInt(90) + 10;
    setState(() => _sku.text = 'SKU$suffix$noise');
  }

  Future<void> _pickCategory(List<Category> cats) async {
    final selected = await showCategoryPickerSheet(
      context,
      categories: [
        for (final c in cats) (id: c.id, name: c.name),
      ],
      selectedId: _categoryId,
    );
    if (!mounted || selected == null) return;
    setState(() => _categoryId = selected < 0 ? null : selected);
  }

  Future<bool> _confirmRemovePhoto() {
    return confirmDialog(
      context,
      title: 'Remove photo?',
      body: 'This product photo will be removed. You can upload a new one anytime.',
      icon: Icons.hide_image_outlined,
      confirmLabel: 'Remove',
      destructive: true,
    );
  }

  Future<void> _removePhoto() async {
    final ok = await _confirmRemovePhoto();
    if (!ok || !mounted) return;
    setState(() => _imagePath = null);
  }

  Future<void> _pickImage() async {
    final file = await showImagePickerFlow(
      context,
      title: 'Product photo',
      subtitle: 'Take a new photo or choose from gallery',
      showRemove: _hasImage,
      removeLabel: 'Remove photo',
      onRemove: _removePhoto,
    );
    if (file == null || !mounted) return;

    try {
      final saved = await _persistImage(file);
      setState(() => _imagePath = saved);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, 'Unable to save product image');
    }
  }

  Future<String> _persistImage(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'product_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext =
        p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final destPath = p.join(
      dir.path,
      'product_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(file.path).copy(destPath);
    return destPath;
  }

  Future<void> _scanBarcode() async {
    final code = await context.push<String>(
      '/scan?purpose=captureBarcode',
    );
    if (!mounted || code == null || code.trim().isEmpty) return;
    setState(() => _barcode.text = code.trim());
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 22),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _label(String text, {bool required = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            text: text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasImage {
    final path = _imagePath;
    return path != null && path.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final isEdit = widget.productId != null;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: isEdit ? l10n.productsEditProduct : l10n.productsAddProduct,
        subtitle: isEdit
            ? 'Update catalog details & pricing'
            : 'Add to catalog with price & stock',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      SoftCard(
                        radius: AppRadii.md,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        onTap: _pickImage,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: _hasImage
                                    ? AppImage(
                                        path: _imagePath,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        error: ColoredBox(
                                          color: scheme.primary
                                              .withValues(alpha: 0.08),
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: scheme.primary
                                            .withValues(alpha: 0.08),
                                        child: Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 28,
                                          color: scheme.primary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hasImage
                                        ? 'Product photo'
                                        : 'Add product photo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hasImage
                                        ? 'Tap to change or remove'
                                        : 'Camera or gallery • optional',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _hasImage ? 'Change' : 'Upload',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      if (_hasImage) ...[
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: _removePhoto,
                                          style: TextButton.styleFrom(
                                            foregroundColor: scheme.error,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label(l10n.productsProductName, required: true),
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration(
                          hint: 'Enter product name',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('SKU (Optional)'),
                      TextField(
                        controller: _sku,
                        decoration: _decoration(
                          hint: 'SKU',
                          icon: Icons.tag_rounded,
                          suffix: IconButton(
                            tooltip: 'Generate SKU',
                            onPressed: _generateSku,
                            icon: Icon(
                              Icons.auto_awesome_rounded,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('Barcode (Optional)'),
                      TextField(
                        controller: _barcode,
                        decoration: _decoration(
                          hint: 'Barcode',
                          icon: Icons.qr_code_2_rounded,
                          suffix: IconButton(
                            tooltip: 'Scan barcode',
                            onPressed: _scanBarcode,
                            icon: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _label('Category (Optional)')),
                          TextButton.icon(
                            onPressed: () async {
                              final id = await showCreateCategoryDialog(context);
                              if (id != null && mounted) {
                                setState(() => _categoryId = id);
                              }
                            },
                            icon: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                            label: Text(
                              'Add',
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _pickCategory(cats),
                        borderRadius: BorderRadius.circular(_fieldRadius),
                        child: InputDecorator(
                          decoration: _decoration(
                            hint: 'Select Category',
                            icon: Icons.category_outlined,
                            suffix: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          child: Text(
                            _categoryId == null
                                ? 'Select Category'
                                : (cats
                                        .where((c) => c.id == _categoryId)
                                        .map((c) => c.name.displayTitle)
                                        .firstOrNull ??
                                    'Select Category'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: _categoryId == null
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _label('Cost Price'),
                                TextField(
                                  controller: _purchase,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    ThousandDecimalFormatter(),
                                  ],
                                  decoration: _decoration(
                                    hint: 'Enter cost price',
                                    icon: Icons.currency_rupee_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _label(
                                  l10n.productsSellingPrice,
                                  required: true,
                                ),
                                TextField(
                                  controller: _selling,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    ThousandDecimalFormatter(),
                                  ],
                                  decoration: _decoration(
                                    hint: 'Enter selling price',
                                    icon: Icons.sell_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _label(
                                  isEdit
                                      ? l10n.inventoryCurrentStock
                                      : 'Stock Quantity',
                                  required: isEdit,
                                ),
                                TextField(
                                  controller: _opening,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration(
                                    hint: isEdit ? '0' : 'Enter quantity',
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _label(l10n.productsUnit, required: true),
                                DropdownButtonFormField<String>(
                                  initialValue: _unit,
                                  isExpanded: true,
                                  items: [
                                    for (final unit in _productUnits)
                                      DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit.toUpperCase()),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _unit = v);
                                  },
                                  decoration: _decoration(
                                    hint: 'PCS',
                                    icon: Icons.straighten_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _label('Min. stock alert'),
                                TextField(
                                  controller: _min,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration(
                                    hint: '10',
                                    icon: Icons.warning_amber_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _label('GST (%)'),
                                TextField(
                                  controller: _tax,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _decoration(
                                    hint: '0',
                                    icon: Icons.percent_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_existing != null) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final inactive = !_existing!.isActive;
                            final ok = await confirmDialog(
                              context,
                              title: inactive
                                  ? 'Activate product'
                                  : 'Deactivate product',
                              body: inactive
                                  ? 'Show this product in billing and catalogs again?'
                                  : 'Hide this product from billing and catalogs? Not a permanent delete — reactivate later from Products → Inactive.',
                              icon: inactive
                                  ? Icons.restart_alt_rounded
                                  : Icons.visibility_off_outlined,
                              confirmLabel:
                                  inactive ? 'Activate' : 'Deactivate',
                              destructive: !inactive,
                            );
                            if (!ok || !context.mounted) return;
                            final navigator = Navigator.of(context);
                            if (inactive) {
                              await ref
                                  .read(productRepositoryProvider)
                                  .activateProduct(_existing!.id);
                            } else {
                              await ref
                                  .read(productRepositoryProvider)
                                  .deactivateProduct(_existing!.id);
                            }
                            ref.invalidate(productsProvider);
                            navigator.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                            side: BorderSide(color: scheme.outline),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: Icon(
                            _existing!.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.restart_alt_rounded,
                          ),
                          label: Text(
                            _existing!.isActive
                                ? 'Deactivate product'
                                : 'Activate product',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_fieldRadius),
                          ),
                        ),
                        icon: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(l10n.commonSave),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    dismissKeyboard();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return;
    if (_name.text.trim().isEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.errorsValidation)));
      return;
    }
    if (_selling.text.trim().isEmpty || parseRupeesToPaise(_selling.text) <= 0) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.errorsValidation)));
      return;
    }
    final openingText = _opening.text.trim();
    final openingStock =
        openingText.isEmpty ? 0 : int.tryParse(openingText);
    if (openingStock == null || openingStock < 0) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.errorsValidation)));
      return;
    }

    final barcodes = _barcode.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final taxBp = ((double.tryParse(_tax.text) ?? 0) * 100).round();

    setState(() => _saving = true);
    try {
      if (_existing == null) {
        await ref.read(productRepositoryProvider).createProduct(
              ProductDraft(
                storeId: store.id,
                name: _name.text.trim(),
                sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
                categoryId: _categoryId,
                unit: _unit,
                purchasePricePaise: parseRupeesToPaise(_purchase.text),
                sellingPricePaise: parseRupeesToPaise(_selling.text),
                taxRateBp: taxBp,
                minimumStock: int.tryParse(_min.text) ?? 0,
                openingStock: openingStock,
                imagePath: _imagePath,
                barcodes: barcodes,
              ),
            );
      } else {
        final newStock = int.tryParse(_opening.text.trim());
        if (newStock == null || newStock < 0) {
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.errorsValidation)),
          );
          return;
        }
        final delta = newStock - _existing!.currentStock;

        await ref.read(productRepositoryProvider).updateProduct(
              Product(
                id: _existing!.id,
                storeId: store.id,
                name: _name.text.trim(),
                sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
                categoryId: _categoryId,
                unit: _unit,
                purchasePricePaise: parseRupeesToPaise(_purchase.text),
                sellingPricePaise: parseRupeesToPaise(_selling.text),
                taxRateBp: taxBp,
                minimumStock: int.tryParse(_min.text) ?? 0,
                currentStock: _existing!.currentStock,
                imagePath: _imagePath,
                createdAt: _existing!.createdAt,
                updatedAt: _existing!.updatedAt,
              ),
              barcodes: barcodes,
            );

        if (delta != 0) {
          await ref.read(stockRepositoryProvider).adjustStock(
                productId: _existing!.id,
                delta: delta,
                reason: 'Manual stock update',
              );
        }
      }
      await ref.read(backupDirtyTrackerProvider).markDirty();
      ref.invalidate(productsProvider);
      if (!mounted) return;
      navigator.pop();
    } on DuplicateBarcodeException {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.errorsDuplicateBarcode)),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
