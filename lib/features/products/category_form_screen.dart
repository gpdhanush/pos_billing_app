import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId, this.initialName});

  final int? categoryId;
  final String? initialName;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _submitted = false;
  bool _saving = false;

  static const _radius = 5.0;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 22),
      errorStyle: TextStyle(
        color: scheme.error,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
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

  Future<void> _save() async {
    dismissKeyboard();
    setState(() => _submitted = true);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final l10n = AppLocalizations.of(context);
    final store = ref.read(storeProfileProvider).valueOrNull;
    final name = _name.text.trim();
    if (store == null || name.isEmpty) {
      showSnack(context, l10n.errorsValidation);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      if (_isEdit) {
        await repo.renameCategory(widget.categoryId!, name);
      } else {
        await repo.addCategory(store.id, name);
      }
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: _isEdit ? 'Edit category' : l10n.categoriesAdd,
        subtitle: _isEdit
            ? 'Update category name'
            : 'Organize products in your catalog',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      children: [
                        _label(l10n.categoriesName),
                        TextFormField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.commonRequired
                        : null,
                    decoration: _decoration(
                      hint: 'Enter category name',
                      icon: Icons.label_outline_rounded,
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
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
}
