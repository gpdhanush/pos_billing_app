import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});

  final int? expenseId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _method = PaymentMethods.cash;
  Expense? _existing;
  bool _loaded = false;
  bool _submitted = false;
  bool _saving = false;

  static const _radius = 5.0;

  bool get _isEdit => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.expenseId != null) {
      _existing =
          await ref.read(expenseRepositoryProvider).getById(widget.expenseId!);
      if (_existing != null && mounted) {
        _category.text = _existing!.category;
        _amount.text = Money(_existing!.amountPaise).formatForField();
        _note.text = _existing!.note ?? '';
        _method = _existing!.paymentMethod;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _note.dispose();
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
    if (store == null) return;

    final category = _category.text.trim();
    final amount = parseRupeesToPaise(_amount.text);
    if (category.isEmpty || amount <= 0) {
      showSnack(context, l10n.errorsValidation);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (_isEdit && _existing != null) {
        await repo.update(
          id: _existing!.id,
          category: category,
          amountPaise: amount,
          paymentMethod: _method,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      } else {
        await repo.create(
          storeId: store.id,
          category: category,
          amountPaise: amount,
          paymentMethod: _method,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      }
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
      backgroundColor: scheme.surface,
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
          _isEdit ? 'Edit expense' : l10n.expensesAdd,
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      children: [
                        _label(l10n.expensesCategory),
                        TextFormField(
                          controller: _category,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? l10n.commonRequired
                                  : null,
                          decoration: _decoration(
                            hint: 'e.g. Rent, Transport',
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(l10n.commonAmount),
                        TextFormField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [ThousandDecimalFormatter()],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.commonRequired;
                            }
                            if (parseRupeesToPaise(v) <= 0) {
                              return l10n.errorsValidation;
                            }
                            return null;
                          },
                          decoration: _decoration(
                            hint: '0.00',
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(l10n.expensesPaymentMethod),
                        DropdownButtonFormField<String>(
                          initialValue: _method,
                          items: [
                            DropdownMenuItem(
                              value: PaymentMethods.cash,
                              child: Text(l10n.checkoutCash),
                            ),
                            DropdownMenuItem(
                              value: PaymentMethods.upi,
                              child: Text(l10n.checkoutUpi),
                            ),
                            DropdownMenuItem(
                              value: PaymentMethods.card,
                              child: Text(l10n.checkoutCard),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _method = v ?? PaymentMethods.cash,
                          ),
                          decoration: _decoration(
                            hint: l10n.expensesPaymentMethod,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('${l10n.commonNotes} (Optional)'),
                        TextFormField(
                          controller: _note,
                          maxLines: 3,
                          decoration: _decoration(
                            hint: 'Enter notes',
                            icon: Icons.sticky_note_2_outlined,
                          ),
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
