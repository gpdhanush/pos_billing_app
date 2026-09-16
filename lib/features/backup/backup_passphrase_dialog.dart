import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/features/onboarding/onboarding_widgets.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

/// Opens a full-screen passphrase page. Returns the passphrase or null.
Future<String?> showBackupPassphraseDialog(
  BuildContext context, {
  required String title,
  String? body,
  bool confirmMatch = false,
}) {
  return Navigator.of(context).push<String>(
    PageRouteBuilder<String>(
      fullscreenDialog: true,
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackupPassphrasePage(
          title: title,
          body: body,
          confirmMatch: confirmMatch,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class BackupPassphrasePage extends StatefulWidget {
  const BackupPassphrasePage({
    super.key,
    required this.title,
    this.body,
    this.confirmMatch = false,
  });

  final String title;
  final String? body;
  final bool confirmMatch;

  @override
  State<BackupPassphrasePage> createState() => _BackupPassphrasePageState();
}

class _BackupPassphrasePageState extends State<BackupPassphrasePage> {
  late final TextEditingController _controller;
  late final TextEditingController _confirm;
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  var _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confirm.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    dismissKeyboard();
    final value = _controller.text;
    if (value.length < 8) {
      setState(() => _error = l10n.passphraseMinHint);
      return;
    }
    if (widget.confirmMatch && value != _confirm.text) {
      setState(() => _error = l10n.errorsPinMismatch);
      return;
    }
    setState(() => _error = null);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Let Scaffold resize once; do not also pad by viewInsets.
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            dismissKeyboard();
            Navigator.pop(context);
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 22,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Static icon — no pulse animation (avoids keyboard jank).
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSecurityLock,
                            size: 28,
                            color: scheme.primary,
                            strokeWidth: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.body ?? l10n.backupLocalOnly,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SoftCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.confirmMatch
                                  ? l10n.passphraseSetTitle
                                  : l10n.passphraseEnterTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controller,
                              focusNode: _passFocus,
                              obscureText: _obscure,
                              autofocus: true,
                              textInputAction: widget.confirmMatch
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onChanged: (_) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                              onSubmitted: (_) {
                                if (widget.confirmMatch) {
                                  _confirmFocus.requestFocus();
                                } else {
                                  _submit();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: l10n.passphraseMinHint,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 8,
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedLockPassword,
                                    size: 20,
                                    color: scheme.primary,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 24,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: HugeIcon(
                                    icon: _obscure
                                        ? HugeIcons.strokeRoundedView
                                        : HugeIcons.strokeRoundedViewOffSlash,
                                    size: 20,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.confirmMatch) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.passphraseReenter,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _confirm,
                                focusNode: _confirmFocus,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                onSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: l10n.passphraseReenter,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      right: 8,
                                    ),
                                    child: HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle02,
                                      size: 20,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 24,
                                  ),
                                ),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedAlert02,
                                    size: 18,
                                    color: scheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedInformationCircle,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.backupLocalOnly,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      OnboardPrimaryButton(
                        label: l10n.commonContinue,
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            dismissKeyboard();
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.commonCancel,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<String?> promptCreateBackupPassphrase(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showBackupPassphraseDialog(
    context,
    title: l10n.passphraseSetTitle,
    body: l10n.onboardingBackupBody,
    confirmMatch: true,
  );
}

Future<String?> promptUnlockBackupPassphrase(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showBackupPassphraseDialog(
    context,
    title: l10n.passphraseEnterTitle,
    body: l10n.backupLocalOnly,
    confirmMatch: false,
  );
}

Future<bool> confirmDisconnectGoogle(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return confirmDialog(
    context,
    title: l10n.passphraseDisconnectDrive,
    body: l10n.backupLocalOnly,
    icon: Icons.link_off_rounded,
    confirmLabel: l10n.googleDisconnect,
    destructive: true,
  );
}
