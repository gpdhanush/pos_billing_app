import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/utils/validators.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final _customerSearch = StateProvider<String>((ref) => '');

final customersListProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  return ref
      .watch(customerRepositoryProvider)
      .search(store.id, ref.watch(_customerSearch));
});

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  Future<void> _showCustomerActions(
    BuildContext context,
    WidgetRef ref, {
    required Customer customer,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.visibility_rounded, color: scheme.primary),
                  title: const Text('View details'),
                  subtitle: const Text('Orders, contact & history'),
                  onTap: () => Navigator.pop(ctx, 'view'),
                ),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: scheme.primary),
                  title: const Text('Update'),
                  subtitle: const Text('Edit customer details'),
                  onTap: () => Navigator.pop(ctx, 'update'),
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: const Text('Delete'),
                  subtitle: const Text('Remove from customer list'),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;

    if (action == 'view') {
      await context.push('/customers/view?id=${customer.id}');
      ref.invalidate(customersListProvider);
      return;
    }

    if (action == 'update') {
      final saved =
          await context.push<Object?>('/customers/edit?id=${customer.id}');
      if (saved != null) ref.invalidate(customersListProvider);
      return;
    }

    final ok = await confirmDialog(
      context,
      title: 'Delete customer',
      body: 'Remove "${customer.name}" from your customer list?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(customerRepositoryProvider).deactivate(customer.id);
    ref.invalidate(customersListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(customersListProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.customersTitle,
        subtitle: 'Contacts, credit & dues',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<Object?>('/customers/edit');
          if (saved != null) ref.invalidate(customersListProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.customersAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: l10n.customersSearchHint,
              onChanged: (v) => ref.read(_customerSearch.notifier).state = v,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(customersListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No customers found',
                    subtitle:
                        'Add customers to track credit and billing history.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final due = c.outstandingBalancePaise > 0;
                    final meta = [
                      if ((c.phone ?? '').isNotEmpty) c.phone!,
                      if ((c.email ?? '').isNotEmpty) c.email!,
                      due ? 'Due' : 'Settled',
                    ].join(' • ');

                    return SoftCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      onTap: () =>
                          context.push('/customers/view?id=${c.id}'),
                      onLongPress: () => _showCustomerActions(
                        context,
                        ref,
                        customer: c,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: ColoredBox(
                                color: scheme.primary.withValues(alpha: 0.08),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 22,
                                    color: scheme.primary,
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
                                  c.name.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta.isEmpty ? 'Customer' : meta,
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
                          Text(
                            Money(c.outstandingBalancePaise)
                                .format(symbol: symbol),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: due ? scheme.error : scheme.primary,
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

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final int? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _limit = TextEditingController();
  final _opening = TextEditingController();
  final _notes = TextEditingController();
  Customer? _existing;
  bool _loaded = true;
  bool _submitted = false;
  bool _saving = false;

  static const _radius = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    _existing = await ref
        .read(customerRepositoryProvider)
        .get(widget.customerId!);
    if (_existing != null && mounted) {
      _name.text = _existing!.name;
      _phone.text = _existing!.phone ?? '';
      _email.text = _existing!.email ?? '';
      _address.text = _existing!.address ?? '';
      _limit.text = Money(_existing!.creditLimitPaise).formatForField();
      _notes.text = _existing!.notes ?? '';
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _limit.dispose();
    _opening.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter customer name';
    if (text.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z0-9 .'-]+$").hasMatch(text)) {
      return 'Enter a valid name';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!AppValidators.isEmail(text)) return 'Enter a valid email address';
    return null;
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

    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return;

    setState(() => _saving = true);
    try {
      if (_existing == null) {
        final created = await ref.read(customerRepositoryProvider).create(
              storeId: store.id,
              name: _name.text.trim(),
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              address:
                  _address.text.trim().isEmpty ? null : _address.text.trim(),
              creditLimitPaise: parseRupeesToPaise(_limit.text),
              openingBalancePaise: parseRupeesToPaise(_opening.text),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            );
        ref.invalidate(customersListProvider);
        if (!mounted) return;
        context.pop(created.id);
      } else {
        await ref.read(customerRepositoryProvider).update(
              Customer(
                id: _existing!.id,
                storeId: store.id,
                name: _name.text.trim(),
                phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                address:
                    _address.text.trim().isEmpty ? null : _address.text.trim(),
                creditLimitPaise: parseRupeesToPaise(_limit.text),
                outstandingBalancePaise: _existing!.outstandingBalancePaise,
                notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                createdAt: _existing!.createdAt,
                updatedAt: _existing!.updatedAt,
              ),
            );
        ref.invalidate(customersListProvider);
        if (!mounted) return;
        context.pop(_existing!.id);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.customerId != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: isEdit ? l10n.customersEdit : l10n.customersAdd,
        subtitle: isEdit
            ? 'Update contact & credit details'
            : 'Save buyer for billing & dues',
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      children: [
                        _label('Customer Name'),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          validator: _validateName,
                          decoration: _decoration(
                            hint: 'Enter customer name',
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Phone Number (Optional)'),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: _validatePhone,
                          decoration: _decoration(
                            hint: 'Enter 10-digit mobile number',
                            icon: Icons.phone_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 16),
                        _label('Email Address (Optional)'),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          decoration: _decoration(
                            hint: 'Enter email address',
                            icon: Icons.mail_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_existing == null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(l10n.customersCreditLimit),
                                    TextFormField(
                                      controller: _limit,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(l10n.customersOpeningBalance),
                                    TextFormField(
                                      controller: _opening,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      inputFormatters: [
                                        ThousandDecimalFormatter(),
                                      ],
                                      decoration: _decoration(
                                        hint: '0.00',
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _label(l10n.customersCreditLimit),
                          TextFormField(
                            controller: _limit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [ThousandDecimalFormatter()],
                            decoration: _decoration(
                              hint: '0.00',
                              icon: Icons.currency_rupee_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${l10n.customersOutstanding}: ${Money(_existing!.outstandingBalancePaise)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _label('Address (Optional)'),
                        TextFormField(
                          controller: _address,
                          maxLines: 3,
                          decoration: _decoration(
                            hint: 'Enter customer address',
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(l10n.commonNotes),
                        TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: _decoration(
                            hint: 'Enter notes',
                            icon: Icons.sticky_note_2_outlined,
                          ),
                        ),
                        if (_existing != null) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await confirmDialog(
                                context,
                                title: 'Delete customer',
                                body:
                                    'Remove "${_existing!.name}" from your customer list?',
                                icon: Icons.delete_outline_rounded,
                                confirmLabel: 'Delete',
                                destructive: true,
                              );
                              if (!ok || !context.mounted) return;
                              final navigator = Navigator.of(context);
                              await ref
                                  .read(customerRepositoryProvider)
                                  .deactivate(_existing!.id);
                              ref.invalidate(customersListProvider);
                              navigator.pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.error,
                              side: BorderSide(color: scheme.error),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete customer'),
                          ),
                        ],
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
                        label: Text(
                          isEdit ? l10n.commonSave : l10n.customersAdd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
