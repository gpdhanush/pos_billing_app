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
import 'package:pos_billing/core/database/repositories/product_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
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
  final _opening = TextEditingController(text: '0');
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

  Future<void> _pickImage() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove image'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() => _imagePath = null);
      return;
    }

    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
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
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          isEdit ? l10n.productsEditProduct : l10n.productsAddProduct,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Material(
                              color: scheme.surface,
                              borderRadius:
                                  BorderRadius.circular(_fieldRadius + 7),
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius:
                                    BorderRadius.circular(_fieldRadius + 7),
                                child: Ink(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      _fieldRadius + 7,
                                    ),
                                    border: Border.all(color: scheme.outline),
                                    color: scheme.surface,
                                  ),
                                  child: _hasImage
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            _fieldRadius + 6,
                                          ),
                                          child: AppImage(
                                            path: _imagePath,
                                            fit: BoxFit.cover,
                                            width: 140,
                                            height: 140,
                                            error: Icon(
                                              Icons.broken_image_outlined,
                                              color: scheme.onSurfaceVariant,
                                              size: 36,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                _hasImage
                                    ? 'Change Product Image'
                                    : 'Add Product Image',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _label(l10n.productsProductName),
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration(
                          hint: 'Enter product name',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('Category (Optional)'),
                      DropdownButtonFormField<int?>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Select Category',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          for (final c in cats)
                            DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name.displayTitle),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        decoration: _decoration(
                          hint: 'Select Category',
                          icon: Icons.category_outlined,
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
                                    hint: '0.00',
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
                                _label(l10n.productsSellingPrice),
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
                                    hint: '0.00',
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
                                ),
                                TextField(
                                  controller: _opening,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration(
                                    hint: '0',
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
                                _label(l10n.productsUnit),
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
                      _label('Minimum Stock Alert Level (Optional)'),
                      TextField(
                        controller: _min,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(
                          hint: '10',
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label(l10n.productsTaxGst),
                      TextField(
                        controller: _tax,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          hint: '0',
                          icon: Icons.percent_rounded,
                        ),
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
                openingStock: int.tryParse(_opening.text) ?? 0,
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
