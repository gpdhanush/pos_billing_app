import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class ManualBarcodeScreen extends StatefulWidget {
  const ManualBarcodeScreen({super.key});

  static const minLength = 4;
  static const maxLength = 32;

  static String? validate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Enter a barcode number';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Barcode must contain digits only';
    }
    if (value.length < minLength) {
      return 'Enter at least $minLength digits';
    }
    if (value.length > maxLength) {
      return 'Barcode is too long';
    }
    return null;
  }

  @override
  State<ManualBarcodeScreen> createState() => _ManualBarcodeScreenState();
}

class _ManualBarcodeScreenState extends State<ManualBarcodeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final message = ManualBarcodeScreen.validate(_controller.text);
    if (message != null) {
      setState(() => _errorText = message);
      return;
    }
    context.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      resizeToAvoidBottomInset: true,
      appBar: GlassPageHeader(
        title: l10n.scannerEnterManual,
        subtitle:
            'Numbers only · ${ManualBarcodeScreen.minLength}–${ManualBarcodeScreen.maxLength} digits',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          children: [
            SoftCard(
              radius: AppRadii.xl,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.18),
                            scheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBarcodeScan,
                          size: 36,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.productsBarcode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type the barcode printed on the product label, then continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      child: Text(
                        l10n.commonContinue,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Barcode number',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        ManualBarcodeScreen.maxLength,
                      ),
                    ],
                    onChanged: (_) {
                      if (_errorText == null) return;
                      setState(
                        () => _errorText = ManualBarcodeScreen.validate(
                          _controller.text,
                        ),
                      );
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'e.g. 8901234567890',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPinCode,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 24,
                      ),
                      errorText: _errorText,
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide:
                            BorderSide(color: scheme.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(color: scheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide:
                            BorderSide(color: scheme.error, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
