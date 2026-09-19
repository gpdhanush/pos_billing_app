import 'package:soft_ui_kit/soft_ui_kit.dart' as app_ui;
import 'package:flutter/material.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/core/money/money.dart';

export 'package:soft_ui_kit/soft_ui_kit.dart'
    show
        AccentPicker,
        AccentSwatch,
        DisplayTitle,
        EmptyState,
        GlassPageHeader,
        IconBadge,
        InitialsAvatar,
        KeyboardDismissOnTap,
        PrimaryCtaBar,
        QtyStepper,
        SectionHeader,
        SoftCard,
        SoftInfoBadge,
        SoftNavBar,
        SoftNavItem,
        SoftPeriodBadge,
        SoftQuickAction,
        SoftSearchField,
        StatTile,
        dismissKeyboard,
        dismissKeyboardAnd,
        showSnack;

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return app_ui.ErrorState(
      onRetry: onRetry,
      message: message,
      fallbackTitle: l10n.commonError,
      retryLabel: l10n.commonRetry,
    );
  }
}

Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final l10n = AppLocalizations.of(context);
  return app_ui.showAppDatePicker(
    context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: l10n.commonSelectDate,
    cancelText: l10n.commonCancel,
    confirmText: l10n.commonDone,
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) {
  return showConfirmBottomSheet(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    icon: icon,
    destructive: destructive,
  );
}

Future<bool> showConfirmBottomSheet(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) {
  final l10n = AppLocalizations.of(context);
  return app_ui.showConfirmBottomSheet(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel ?? l10n.commonConfirm,
    cancelLabel: cancelLabel ?? l10n.commonCancel,
    icon: icon,
    destructive: destructive,
  );
}

Future<bool> showExitBottomSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showConfirmBottomSheet(
    context,
    title: l10n.commonExitApp,
    body: l10n.appTagline,
    confirmLabel: l10n.commonClose,
    cancelLabel: l10n.commonCancel,
    icon: Icons.logout_rounded,
  );
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ThousandDecimalFormatter()],
      decoration: InputDecoration(hintText: label, prefixText: '₹ '),
      validator: requiredField
          ? (v) => (v == null || v.trim().isEmpty)
                ? AppLocalizations.of(context).commonRequired
                : null
          : null,
    );
  }
}
