import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/auth/google_auth_service.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/features/backup/backup_passphrase_dialog.dart';
import 'package:pos_billing/features/onboarding/onboarding_widgets.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

/// Optional Google Drive connect step — never blocks POS usage.
class GoogleConnectScreen extends ConsumerStatefulWidget {
  const GoogleConnectScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<GoogleConnectScreen> createState() =>
      _GoogleConnectScreenState();
}

class _GoogleConnectScreenState extends ConsumerState<GoogleConnectScreen> {
  bool _busy = false;
  bool _checking = true;
  GoogleAccountSession? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExisting());
  }

  Future<void> _checkExisting() async {
    final session =
        await ref.read(googleAuthServiceProvider).restoreSilently();
    if (!mounted) return;

    if (session != null && !widget.fromSettings) {
      // Already connected during onboarding → mark step done and continue.
      await ref.read(settingsRepositoryProvider).setBool(
            SettingKeys.googleSetupSkipped,
            true,
          );
      ref.invalidate(googleSessionProvider);
      if (!mounted) return;
      context.go('/home');
      return;
    }

    setState(() {
      _session = session;
      _checking = false;
    });
  }

  Future<void> _finish({required bool connected}) async {
    if (!widget.fromSettings) {
      // Mark Google setup step as completed (connected or skipped).
      await ref.read(settingsRepositoryProvider).setBool(
            SettingKeys.googleSetupSkipped,
            true,
          );
    }
    ref.invalidate(googleSessionProvider);
    if (!mounted) return;
    if (widget.fromSettings) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    final analytics = ref.read(analyticsServiceProvider);
    try {
      final session = await ref.read(googleAuthServiceProvider).signIn();
      ref.invalidate(googleSessionProvider);
      await analytics.logEvent('google_sign_in_success');
      if (!mounted) return;
      setState(() => _session = session);

      final drive = ref.read(driveClientProvider);
      final crypto = ref.read(backupCryptoProvider);
      final envelope = await drive.downloadEnvelope();
      if (!mounted) return;

      if (envelope != null) {
        // Reinstall / new device: unlock the existing Drive key.
        if (!await crypto.hasLocalDek()) {
          if (!mounted) return;
          final pass = await promptUnlockBackupPassphrase(context);
          if (pass != null && pass.length >= 8) {
            await crypto.unwrapDekWithPassphrase(envelope, pass);
          }
        }
      } else {
        if (!mounted) return;
        final pass = await promptCreateBackupPassphrase(context);
        if (pass != null && pass.length >= 8) {
          await ref.read(backupServiceProvider).ensureDriveKeyEnvelope(
                requestPassphrase: () async => pass,
              );
        }
      }
      if (!mounted) return;
      showSnack(context, 'Google Drive connected');
      await _finish(connected: true);
    } on DriveAuthException {
      await analytics.logEvent('google_sign_in_failed');
      await analytics.recordError('google_sign_in_failed', reason: 'auth');
      if (!mounted) return;
      showSnack(context, 'Google sign-in failed');
    } on RestoreException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message);
    } on BackupException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message);
    } catch (_) {
      await analytics.logEvent('google_sign_in_failed');
      if (!mounted) return;
      showSnack(context, 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final ok = await confirmDisconnectGoogle(context);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(googleAuthServiceProvider).signOut();
      ref.invalidate(googleSessionProvider);
      if (!mounted) return;
      setState(() => _session = null);
      showSnack(context, 'Google Drive disconnected');
      if (widget.fromSettings) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = _session != null;

    if (_checking) {
      return Scaffold(
        body: OnboardBackdrop(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: OnboardBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _busy
                        ? null
                        : () => _finish(connected: connected),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: OnboardHeroIcon(
                    icon: connected
                        ? HugeIcons.strokeRoundedCloudSavingDone02
                        : HugeIcons.strokeRoundedCloudUpload,
                    size: 96,
                    iconSize: 42,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  connected
                      ? 'Google Drive connected'
                      : 'Back up to Google Drive',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  connected
                      ? (_session!.email)
                      : 'Optionally connect Google so encrypted backups sync to your private Drive app data. You can skip and set this up later in Settings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                if (!connected) ...[
                  const SizedBox(height: 28),
                  SoftCard(
                    child: Column(
                      children: [
                        _bullet(
                          context,
                          HugeIcons.strokeRoundedSecurityLock,
                          'AES-256 encrypted — keys never uploaded in plain text',
                        ),
                        const SizedBox(height: 10),
                        _bullet(
                          context,
                          HugeIcons.strokeRoundedCloudUpload,
                          'Stored only in Drive appDataFolder',
                        ),
                        const SizedBox(height: 10),
                        _bullet(
                          context,
                          HugeIcons.strokeRoundedSmartPhone01,
                          'Restore on a new phone with your recovery passphrase',
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (connected) ...[
                  OnboardPrimaryButton(
                    label: widget.fromSettings ? 'Done' : 'Continue',
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    loading: _busy,
                    onPressed: () => _finish(connected: true),
                  ),
                  if (widget.fromSettings) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _disconnect,
                      child: const Text('Disconnect'),
                    ),
                  ],
                ] else ...[
                  OnboardPrimaryButton(
                    label: _busy ? 'Connecting…' : 'Connect Google Drive',
                    icon: HugeIcons.strokeRoundedCloudUpload,
                    loading: _busy,
                    onPressed: _connect,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        _busy ? null : () => _finish(connected: false),
                    child: const Text('Skip for now'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(
    BuildContext context,
    List<List<dynamic>> icon,
    String text,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, size: 20, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
