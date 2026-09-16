import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/utils/formatters.dart';
import 'package:pos_billing/core/utils/invoice_numbering.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/core/utils/validators.dart';
import 'package:pos_billing/shared/models/store_profile.dart';
import 'package:pos_billing/shared/widgets/app_image.dart';
import 'package:pos_billing/shared/widgets/image_source_sheet.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  final _page = PageController();
  int _step = 0;
  final _name = TextEditingController();
  final _display = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _pin = TextEditingController();
  final _gstin = TextEditingController();
  final _tax = TextEditingController();
  final _prefix = TextEditingController(text: 'INV');
  final _startNo = TextEditingController(text: '1');
  final _footer = TextEditingController();
  bool _gst = false;
  String _bizType = 'Regular';
  String? _logoPath;
  bool _loaded = false;
  bool _saving = false;

  static const _radius = 5.0;

  @override
  void dispose() {
    _page.dispose();
    for (final c in [
      _name,
      _display,
      _phone,
      _altPhone,
      _email,
      _website,
      _addr1,
      _addr2,
      _area,
      _city,
      _district,
      _state,
      _country,
      _pin,
      _gstin,
      _tax,
      _prefix,
      _startNo,
      _footer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(StoreProfile? store) {
    if (_loaded || store == null) return;
    _loaded = true;
    _name.text = store.businessName.toUpperCase();
    _display.text = (store.displayName ?? '').displayTitle;
    _phone.text = store.phone ?? '';
    _altPhone.text = store.alternatePhone ?? '';
    _email.text = store.email ?? '';
    _website.text = store.website ?? '';
    _addr1.text = store.addressLine1 ?? '';
    _addr2.text = store.addressLine2 ?? '';
    _area.text = store.area ?? '';
    _city.text = store.city ?? '';
    _district.text = store.district ?? '';
    _state.text = store.state ?? '';
    _country.text = store.country;
    _pin.text = store.postalCode ?? '';
    _gst = store.isGstRegistered;
    _gstin.text = store.gstin ?? '';
    _bizType = store.businessType ?? 'Regular';
    _tax.text = (store.defaultTaxRateBp / 100).toString();
    _prefix.text = store.invoicePrefix;
    _startNo.text = '${store.nextInvoiceNumber}';
    _footer.text = store.receiptFooter ?? '';
    _logoPath = store.logoPath;
  }

  StoreProfile _build(StoreProfile? existing) {
    final taxBp = ((double.tryParse(_tax.text) ?? 0) * 100).round();
    final now = nowMillis();
    return StoreProfile(
      id: existing?.id ?? 0,
      businessName: _name.text.trim().toUpperCase(),
      displayName: _display.text.trim().displayTitle,
      logoPath: _logoPath,
      addressLine1: _addr1.text.trim(),
      addressLine2: _addr2.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      district: _district.text.trim(),
      state: _state.text.trim(),
      country: _country.text.trim().isEmpty ? 'India' : _country.text.trim(),
      postalCode: _pin.text.trim(),
      phone: _phone.text.trim(),
      alternatePhone: _altPhone.text.trim(),
      email: _email.text.trim(),
      website: _website.text.trim(),
      isGstRegistered: _gst,
      gstin: _gstin.text.trim().toUpperCase(),
      businessType: _bizType,
      defaultTaxRateBp: taxBp,
      invoicePrefix: _prefix.text.trim().isEmpty ? 'INV' : _prefix.text.trim(),
      nextInvoiceNumber: int.tryParse(_startNo.text) ?? 1,
      receiptFooter: _footer.text.trim().isEmpty ? null : _footer.text.trim(),
      isSetupCompleted: existing?.isSetupCompleted ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _pickLogo() async {
    final file = await showImagePickerFlow(
      context,
      title: 'Store logo',
      subtitle: 'Take a photo or choose from gallery',
      showRemove: _logoPath != null && _logoPath!.isNotEmpty,
      removeLabel: 'Remove logo',
      onRemove: () async {
        setState(() => _logoPath = null);
      },
    );
    if (file == null || !mounted) return;
    try {
      final saved = await _persistLogo(file);
      setState(() => _logoPath = saved);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, 'Unable to save business logo');
    }
  }

  Future<String> _persistLogo(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'store_logos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext =
        p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final destPath = p.join(
      dir.path,
      'logo_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(file.path).copy(destPath);
    return destPath;
  }

  String? _validate() {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) return l10n.errorsBusinessName;
    if (AppValidators.optionalPhone(_phone.text) != null) {
      return l10n.errorsInvalidPhone;
    }
    if (AppValidators.optionalPhone(_altPhone.text) != null) {
      return l10n.errorsInvalidPhone;
    }
    if (AppValidators.optionalEmail(_email.text) != null) {
      return l10n.errorsInvalidEmail;
    }
    if (AppValidators.optionalWebsite(_website.text) != null) {
      return l10n.errorsInvalidWebsite;
    }
    if (_gst && AppValidators.optionalGstin(_gstin.text) != null) {
      return l10n.errorsInvalidGstin;
    }
    return null;
  }

  Future<void> _save({required bool complete}) async {
    dismissKeyboard();
    final error = _validate();
    if (error != null) {
      showSnack(context, error);
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = ref.read(storeProfileProvider).valueOrNull;
      await ref
          .read(storeProfileProvider.notifier)
          .save(_build(existing), complete: complete);
      if (!mounted) return;

      if (widget.editing) {
        // Prefer go() so a router refresh after save cannot remount this
        // screen at step 0 (Store tab) again.
        context.go('/more');
      } else {
        // First-time setup → biometric screen, never bounce back here.
        context.go('/setup/security');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goBack() {
    dismissKeyboard();
    if (_step > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    if (widget.editing && context.canPop()) {
      context.pop();
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    _hydrate(store);

    final steps = [
      l10n.setupStepStore,
      l10n.setupStepContact,
      l10n.setupStepGst,
      l10n.setupStepInvoice,
    ];
    final title = widget.editing
        ? l10n.settingsStoreDetails
        : steps[_step.clamp(0, steps.length - 1)];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
        leading: (widget.editing || _step > 0)
            ? IconButton(
                onPressed: _saving ? null : _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? scheme.onPrimary
                                : scheme.onPrimary.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onPrimary.withValues(
                                  alpha: i <= _step ? 1 : 0.7,
                                ),
                                fontWeight: i == _step
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (i < steps.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _storeStep(l10n, scheme),
                _contactStep(l10n),
                _gstStep(l10n),
                _invoiceStep(l10n, scheme),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _goBack,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                        ),
                        child: Text(l10n.commonBack),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _step > 0 ? 1 : 1,
                    child: FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () {
                              dismissKeyboard();
                              if (_step < 3) {
                                _page.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                _save(complete: true);
                              }
                            },
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
                          : Icon(
                              _step < 3
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                            ),
                      label: Text(
                        _step < 3
                            ? l10n.commonNext
                            : (widget.editing
                                ? l10n.commonSave
                                : l10n.setupComplete),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeStep(AppLocalizations l10n, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoPath != null && _logoPath!.isNotEmpty
                      ? AppImage(
                          path: _logoPath,
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                          placeholder: Icon(
                            Icons.storefront_rounded,
                            size: 48,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: scheme.primary,
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_logoPath != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _logoPath = null),
              child: const Text('Remove logo'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _label('${l10n.storeBusinessName} *'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [UpperCaseTextFormatter()],
          decoration: _decoration(
            hint: 'Enter business name',
            icon: Icons.storefront_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeDisplayName),
        TextField(
          controller: _display,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextFormatter()],
          decoration: _decoration(
            hint: 'Display name (optional)',
            icon: Icons.badge_outlined,
          ),
        ),
      ],
    );
  }

  Widget _contactStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        _label(l10n.storePhone),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _decoration(
            hint: 'Primary phone',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeAltPhone),
        TextField(
          controller: _altPhone,
          keyboardType: TextInputType.phone,
          decoration: _decoration(
            hint: 'Alternate phone',
            icon: Icons.phone_android_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.commonEmail),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration(
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeWebsite),
        TextField(
          controller: _website,
          decoration: _decoration(
            hint: 'Website',
            icon: Icons.language_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeAddress1),
        TextField(
          controller: _addr1,
          decoration: _decoration(
            hint: 'Address line 1',
            icon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeAddress2),
        TextField(
          controller: _addr2,
          decoration: _decoration(
            hint: 'Address line 2',
            icon: Icons.home_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeArea),
        TextField(
          controller: _area,
          decoration: _decoration(
            hint: 'Area',
            icon: Icons.map_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeCity),
        TextField(
          controller: _city,
          decoration: _decoration(
            hint: 'City',
            icon: Icons.location_city_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeDistrict),
        TextField(
          controller: _district,
          decoration: _decoration(
            hint: 'District',
            icon: Icons.apartment_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeState),
        TextField(
          controller: _state,
          decoration: _decoration(
            hint: 'State',
            icon: Icons.flag_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeCountry),
        TextField(
          controller: _country,
          decoration: _decoration(
            hint: 'Country',
            icon: Icons.public_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label(l10n.storePostalCode),
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            hint: 'PIN / ZIP',
            icon: Icons.pin_outlined,
          ),
        ),
      ],
    );
  }

  Widget _gstStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        _label(l10n.storeGstRegistered),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _gst,
          title: Text(_gst ? l10n.commonYes : l10n.commonNo),
          onChanged: (v) => setState(() => _gst = v),
        ),
        if (_gst) ...[
          const SizedBox(height: 8),
          _label('${l10n.storeGstin} *'),
          TextField(
            controller: _gstin,
            textCapitalization: TextCapitalization.characters,
            decoration: _decoration(
              hint: 'GSTIN',
              icon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(height: 16),
          _label(l10n.storeBusinessType),
          DropdownButtonFormField<String>(
            initialValue: _bizType,
            items: [
              DropdownMenuItem(
                value: 'Regular',
                child: Text(l10n.storeBusinessRegular),
              ),
              DropdownMenuItem(
                value: 'Composition',
                child: Text(l10n.storeBusinessComposition),
              ),
              DropdownMenuItem(
                value: 'Other',
                child: Text(l10n.storeBusinessOther),
              ),
            ],
            onChanged: (v) => setState(() => _bizType = v ?? 'Regular'),
            decoration: _decoration(
              hint: l10n.storeBusinessType,
              icon: Icons.business_outlined,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _label(l10n.storeDefaultTax),
        TextField(
          controller: _tax,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(
            hint: 'Default tax %',
            icon: Icons.percent_rounded,
          ),
        ),
      ],
    );
  }

  Widget _invoiceStep(AppLocalizations l10n, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        _label(l10n.storeInvoicePrefix),
        TextField(
          controller: _prefix,
          textCapitalization: TextCapitalization.characters,
          decoration: _decoration(
            hint: 'INV',
            icon: Icons.tag_rounded,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeStartingNumber),
        TextField(
          controller: _startNo,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            hint: '1',
            icon: Icons.numbers_rounded,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _label(l10n.storeReceiptFooter),
        TextField(
          controller: _footer,
          maxLines: 3,
          decoration: _decoration(
            hint: 'Thank you note',
            icon: Icons.sticky_note_2_outlined,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _label(l10n.storeReceiptPreview),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            children: [
              Text(
                _name.text.trim().isEmpty
                    ? l10n.storeBusinessName
                    : _name.text.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                InvoiceNumbering.format(
                  prefix: _prefix.text,
                  number: int.tryParse(_startNo.text) ?? 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _footer.text.trim().isEmpty
                    ? l10n.storeThankYouDefault
                    : _footer.text.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
