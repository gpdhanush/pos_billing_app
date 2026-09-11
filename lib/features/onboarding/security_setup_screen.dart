import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

/// Onboarding / settings: enable biometric app lock only (no PIN).
class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  bool _enable = true;
  bool _bioAvailable = false;
  bool _checking = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBio());
  }

  Future<void> _checkBio() async {
    final available = await ref.read(pinServiceProvider).biometricAvailable();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _enable = available;
      _checking = false;
    });
  }

  Future<void> _continue({required bool skip}) async {
    dismissKeyboard();
    setState(() => _saving = true);
    try {
      if (!skip && _enable) {
        if (!_bioAvailable) {
          showSnack(context, 'Biometrics unavailable on this device');
          return;
        }
        final ok = await ref.read(pinServiceProvider).authenticateBiometric(
              reason: 'Enable biometric lock for POS Billing',
            );
        if (!ok) {
          if (!mounted) return;
          showSnack(context, 'Biometric not confirmed');
          return;
        }
        await ref.read(pinServiceProvider).clearPin();
        await ref.read(appSettingsProvider.notifier).setPinEnabled(false);
        await ref.read(appSettingsProvider.notifier).setBiometricEnabled(true);
      } else {
        await ref.read(pinServiceProvider).clearPin();
        await ref.read(appSettingsProvider.notifier).setPinEnabled(false);
        await ref.read(appSettingsProvider.notifier).setBiometricEnabled(false);
      }
      ref.read(unlockedProvider.notifier).state = true;
      if (!mounted) return;
      // Finish setup flow completely — never pop back to store form.
      context.go('/home');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(title: l10n.securityTitle),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                SoftCard(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 36,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Biometric app lock',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bioAvailable
                            ? 'Use fingerprint or face unlock when opening the app. No PIN required.'
                            : 'Biometrics are not available on this device. You can continue without app lock.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      if (_bioAvailable) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _enable,
                          title: const Text('Enable biometric lock'),
                          onChanged: (v) => setState(() => _enable = v),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _continue(skip: !_bioAvailable || !_enable),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonContinue),
                ),
                if (_bioAvailable)
                  TextButton(
                    onPressed: _saving ? null : () => _continue(skip: true),
                    child: Text(l10n.securitySkip),
                  ),
              ],
            ),
    );
  }
}

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  bool _busy = false;
  bool _failed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBio());
  }

  Future<void> _tryBio() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _failed = false;
    });
    final ok = await ref.read(pinServiceProvider).authenticateBiometric(
          reason: 'Unlock POS Billing',
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.read(unlockedProvider.notifier).state = true;
      context.go('/home');
    } else {
      setState(() {
        _failed = true;
        _error = 'Biometric unlock failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final accent = _failed ? scheme.error : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent,
                    Color.lerp(accent, scheme.secondary, 0.35)!,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SoftInfoBadge(
                          label: _busy
                              ? 'Verifying…'
                              : (_failed ? 'Locked' : 'App Lock'),
                          background: Colors.white.withValues(alpha: 0.18),
                          foreground: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: _busy
                            ? const Padding(
                                padding: EdgeInsets.all(34),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _failed
                                    ? Icons.fingerprint_outlined
                                    : Icons.fingerprint_rounded,
                                color: Colors.white,
                                size: 54,
                              ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.lockTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store?.name ?? 'POS Billing',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    SoftCard(
                      color: _failed
                          ? scheme.error.withValues(alpha: 0.06)
                          : scheme.surface,
                      borderColor: _failed
                          ? scheme.error.withValues(alpha: 0.25)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBadge(
                            icon: _failed
                                ? Icons.error_outline_rounded
                                : Icons.shield_outlined,
                            background: (_failed ? scheme.error : scheme.primary)
                                .withValues(alpha: 0.12),
                            foreground: _failed ? scheme.error : scheme.primary,
                            size: 44,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _failed
                                      ? 'Unlock failed'
                                      : 'Secure unlock',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _error ??
                                      'Use fingerprint or face to open your shop securely.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _failed
                                            ? scheme.error
                                            : scheme.onSurfaceVariant,
                                        height: 1.35,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _tryBio,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: accent,
                          foregroundColor: _failed
                              ? scheme.onError
                              : scheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        icon: _busy
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: _failed
                                      ? scheme.onError
                                      : scheme.onPrimary,
                                ),
                              )
                            : Icon(
                                _failed
                                    ? Icons.refresh_rounded
                                    : Icons.fingerprint_rounded,
                              ),
                        label: Text(
                          _failed
                              ? 'Try again'
                              : l10n.lockUseBiometric,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your billing data stays on this device.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
