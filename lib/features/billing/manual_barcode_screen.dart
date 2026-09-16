import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.scannerEnterManual,
        subtitle: 'Numbers only · ${ManualBarcodeScreen.minLength}–${ManualBarcodeScreen.maxLength} digits',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SoftCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.barcode_reader,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.productsBarcode,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type the barcode printed on the product label.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 20),
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
                    prefixIcon: const Icon(Icons.pin_outlined),
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
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: scheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: scheme.error, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            child: Text(l10n.commonContinue),
          ),
        ),
      ),
    );
  }
}
