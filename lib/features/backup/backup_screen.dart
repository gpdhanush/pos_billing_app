import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/services/backup_service.dart';
import 'package:pos_billing/core/services/google_drive_client.dart';
import 'package:pos_billing/features/backup/backup_passphrase_dialog.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  BackupProgressStage? _stage;
  List<DriveBackupEntry> _driveBackups = const [];
  bool _showAllDrive = false;
  bool _showAllLocal = false;

  static final _stamp = DateFormat('MMM d, yyyy h:mm a');

  String _stageLabel(BackupProgressStage stage) {
    switch (stage) {
      case BackupProgressStage.preparing:
        return 'Preparing…';
      case BackupProgressStage.creatingCopy:
        return 'Creating database copy…';
      case BackupProgressStage.encrypting:
        return 'Encrypting…';
      case BackupProgressStage.uploading:
        return 'Uploading to Drive…';
      case BackupProgressStage.verifying:
        return 'Verifying upload…';
      case BackupProgressStage.completed:
        return 'Completed';
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _autoLabel(AppLocalizations l10n, String? value) {
    switch (value) {
      case 'daily':
        return l10n.backupDaily;
      case 'weekly':
        return l10n.backupWeekly;
      default:
        return l10n.backupOff;
    }
  }

  Future<String?> _passphraseForBackup({required bool create}) {
    return create
        ? promptCreateBackupPassphrase(context)
        : promptUnlockBackupPassphrase(context);
  }

  Future<void> _refreshDriveList() async {
    try {
      final drive = ref.read(driveClientProvider);
      final auth = ref.read(googleAuthServiceProvider);
      // Ensure silent restore before listing so appDataFolder is readable.
      await auth.restoreSilently();
      if (!await drive.isSignedIn) {
        if (mounted) setState(() => _driveBackups = const []);
        return;
      }
      final list = await drive.listBackups();
      if (mounted) setState(() => _driveBackups = list);
    } catch (_) {
      // Keep previous list on transient errors — don't wipe history.
      if (mounted && _driveBackups.isEmpty) {
        setState(() => _driveBackups = const []);
      }
    }
  }

  Future<void> _deleteBackup(BackupRecord record) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete backup?',
      body:
          'Remove "${record.fileName}" from this device? The latest backup cannot be deleted.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(backupServiceProvider).deleteBackup(record.id);
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Backup deleted')),
      );
      setState(() {});
    } on BackupException catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Unable to delete backup')),
      );
    }
  }

  Future<void> _deleteDriveBackup(DriveBackupEntry entry) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete Drive backup?',
      body: 'Remove "${entry.name}" from Google Drive?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(driveClientProvider).deleteBackupFile(entry.id);
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Drive backup deleted')),
      );
      await _refreshDriveList();
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Unable to delete Drive backup')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupNow({required bool signedIn}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final analytics = ref.read(analyticsServiceProvider);
    setState(() {
      _busy = true;
      _stage = BackupProgressStage.preparing;
    });
    try {
      await analytics.logEvent('backup_started');
      await ref.read(backupServiceProvider).createBackup(
            uploadToDrive: signedIn,
            onProgress: (stage) {
              if (mounted) setState(() => _stage = stage);
            },
            requestPassphraseForEnvelope: signedIn
                ? () async {
                    final hasDek =
                        await ref.read(backupCryptoProvider).hasLocalDek();
                    final envelope =
                        await ref.read(driveClientProvider).downloadEnvelope();
                    if (!mounted) return null;
                    if (envelope != null && !hasDek) {
                      return _passphraseForBackup(create: false);
                    }
                    if (envelope == null) {
                      return _passphraseForBackup(create: true);
                    }
                    return null;
                  }
                : null,
          );
      await analytics.logEvent('backup_success');
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonSuccess)),
      );
      await _refreshDriveList();
      setState(() {});
    } on BackupException catch (e) {
      await analytics.logEvent('backup_failed');
      await analytics.recordError('backup_failed', reason: 'user_backup');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      await analytics.logEvent('backup_failed');
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorsBackup)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
        });
      }
    }
  }

  Future<void> _toggleGoogle(String? email) async {
    final analytics = ref.read(analyticsServiceProvider);
    try {
      if (email == null) {
        await ref.read(googleAuthServiceProvider).signIn();
        ref.invalidate(googleSessionProvider);
        await analytics.logEvent('google_sign_in_success');
        if (!mounted) return;
        final hasDek = await ref.read(backupCryptoProvider).hasLocalDek();
        final envelope =
            await ref.read(driveClientProvider).downloadEnvelope();
        if (!mounted) return;
        if (envelope == null) {
          final pass = await promptCreateBackupPassphrase(context);
          if (pass != null) {
            await ref.read(backupServiceProvider).ensureDriveKeyEnvelope(
                  requestPassphrase: () async => pass,
                );
          }
        } else if (!hasDek) {
          final pass = await promptUnlockBackupPassphrase(context);
          if (pass != null) {
            await ref.read(backupCryptoProvider).unwrapDekWithPassphrase(
                  envelope,
                  pass,
                );
          }
        }
      } else {
        final ok = await confirmDisconnectGoogle(context);
        if (!ok) return;
        await ref.read(googleAuthServiceProvider).signOut();
        ref.invalidate(googleSessionProvider);
      }
      if (!mounted) return;
      await _refreshDriveList();
      setState(() {});
    } on DriveAuthException {
      await analytics.logEvent('google_sign_in_failed');
      if (!mounted) return;
      showSnack(context, AppLocalizations.of(context).errorsDriveAuth);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, AppLocalizations.of(context).errorsDriveAuth);
    }
  }

  Future<void> _showHelp() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About backups',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Local backups are saved on this device. Connect Google Drive to also sync encrypted copies to your private Drive app data folder. Your recovery passphrase is required to restore encrypted Drive backups.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLastDetails(BackupRecord? last) async {
    if (last == null) {
      showSnack(context, AppLocalizations.of(context).backupNone);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final size = _formatBytes(last.fileSize);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last backup details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _detailRow(ctx, 'File', last.fileName),
              _detailRow(
                ctx,
                'Created',
                _stamp.format(
                  DateTime.fromMillisecondsSinceEpoch(last.createdAt),
                ),
              ),
              _detailRow(
                ctx,
                'Status',
                last.status.displayTitle,
                valueColor: last.status == 'successful'
                    ? AppColors.success
                    : scheme.error,
              ),
              if (size.isNotEmpty) _detailRow(ctx, 'Size', size),
              if (last.localPath != null)
                _detailRow(ctx, 'Path', last.localPath!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(googleAuthServiceProvider).restoreSilently();
      ref.invalidate(googleSessionProvider);
      if (mounted) await _refreshDriveList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(googleSessionProvider).valueOrNull;

    // Live Drive session (not only a cached email from secure storage).
    ref.listen(googleSessionProvider, (prev, next) {
      final email = next.valueOrNull?.email;
      if (email != null && email.isNotEmpty) {
        _refreshDriveList();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: GlassPageHeader(
        title: 'Backup & Restore',
        subtitle: 'Keep your data safe and accessible',
        height: 68,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 22,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Drive backups',
            onPressed: _busy
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    await _refreshDriveList();
                    if (!mounted) return;
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(
                          _driveBackups.isEmpty
                              ? 'No Drive backups found'
                              : '${_driveBackups.length} Drive backup(s)',
                        ),
                      ),
                    );
                  },
            icon: Icon(Icons.refresh_rounded, color: scheme.primary),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: _showHelp,
            icon: Icon(Icons.help_outline_rounded, color: scheme.primary),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          ref.read(backupServiceProvider).history(),
          ref.read(backupServiceProvider).lastSuccessful(),
          ref.read(driveClientProvider).isSignedIn,
        ]),
        builder: (context, snap) {
          final history = snap.data?[0] as List<BackupRecord>? ?? const [];
          final last = snap.data?[1] as BackupRecord?;
          final driveLive = snap.data?[2] as bool? ?? false;
          final email = session?.email;
          final latestId = last?.id;
          final signedIn = driveLive && email != null && email.isNotEmpty;
          final visibleDrive = _showAllDrive
              ? _driveBackups
              : _driveBackups.take(3).toList();
          final visibleLocal =
              _showAllLocal ? history : history.take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _GoogleDriveCard(
                signedIn: signedIn,
                displayName: session?.displayName,
                email: email,
                photoUrl: session?.photoUrl,
                busy: _busy,
                connectLabel: l10n.backupConnectGoogle,
                disconnectLabel: 'Disconnect',
                onToggle: () => _toggleGoogle(signedIn ? email : null),
              ),
              const SizedBox(height: 12),
              _LastBackupCard(
                last: last,
                stamp: _stamp,
                onViewDetails: () => _showLastDetails(last),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: EdgeInsets.zero,
                radius: AppRadii.md,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedClock01,
                      title: l10n.backupAutomatic,
                      subtitle: 'Automatically backup your data',
                      trailing: _AutoBackupMenu(
                        value: settings?.autoBackup ?? 'off',
                        label: _autoLabel(l10n, settings?.autoBackup),
                        daily: l10n.backupDaily,
                        weekly: l10n.backupWeekly,
                        off: l10n.backupOff,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setAutoBackup(v),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 68,
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedWifi01,
                      title: 'Wi‑Fi only',
                      subtitle: 'Auto-backup only when connected to Wi‑Fi',
                      trailing: Switch.adaptive(
                        value: settings?.backupWifiOnly ?? true,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setBackupWifiOnly(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                radius: AppRadii.md,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    _TintIconBox(
                      icon: HugeIcons.strokeRoundedFolder02,
                      tint: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local backup folder',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Downloads → POS Billing → backup',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_busy && _stage != null) ...[
                SoftCard(
                  radius: AppRadii.md,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _stage == BackupProgressStage.completed
                            ? 1
                            : null,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _stageLabel(_stage!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed:
                    _busy ? null : () => _backupNow(signedIn: signedIn),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCloudUpload,
                      size: 22,
                      color: scheme.onPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.backupNow,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (signedIn) ...[
                const SizedBox(height: 26),
                _SectionTitle(
                  title: 'Drive backups',
                  actionLabel: _driveBackups.length > 3
                      ? (_showAllDrive ? 'Show less' : 'View all')
                      : null,
                  onAction: _driveBackups.length > 3
                      ? () => setState(() => _showAllDrive = !_showAllDrive)
                      : null,
                ),
                const SizedBox(height: 10),
                if (_driveBackups.isEmpty)
                  SoftCard(
                    radius: AppRadii.md,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCloudOff,
                          size: 36,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Drive backups yet. Your backups will appear here after the first backup.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  )
                else
                  SoftCard(
                    padding: EdgeInsets.zero,
                    radius: AppRadii.md,
                    child: Column(
                      children: [
                        for (var i = 0; i < visibleDrive.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 68,
                              color: scheme.outline.withValues(alpha: 0.5),
                            ),
                          _DriveBackupTile(
                            entry: visibleDrive[i],
                            stamp: _stamp,
                            busy: _busy,
                            onRestore: () async {
                              final ok = await confirmDialog(
                                context,
                                title: l10n.backupRestore,
                                body: l10n.backupConfirmRestore,
                                icon: Icons.restore_rounded,
                                confirmLabel: l10n.backupRestore,
                                destructive: true,
                              );
                              if (!ok || !mounted) return;
                              await _restoreDrive(visibleDrive[i]);
                            },
                            onDelete: () =>
                                _deleteDriveBackup(visibleDrive[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 26),
              _SectionTitle(
                title: 'Local backups',
                actionLabel: history.length > 3
                    ? (_showAllLocal ? 'Show less' : 'View all')
                    : null,
                onAction: history.length > 3
                    ? () => setState(() => _showAllLocal = !_showAllLocal)
                    : null,
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                SoftCard(
                  radius: AppRadii.md,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedFile01,
                        size: 36,
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.backupNone,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  radius: AppRadii.md,
                  child: Column(
                    children: [
                      for (var i = 0; i < visibleLocal.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 68,
                            color: scheme.outline.withValues(alpha: 0.5),
                          ),
                        Builder(
                          builder: (context) {
                            final item = visibleLocal[i];
                            final isLatestSuccessful =
                                item.status == 'successful' &&
                                    item.id == latestId;
                            final canRestore = item.status == 'successful' &&
                                item.localPath != null;
                            final canDelete = !isLatestSuccessful;
                            final size = _formatBytes(item.fileSize);
                            final when = _stamp.format(
                              DateTime.fromMillisecondsSinceEpoch(
                                item.createdAt,
                              ),
                            );
                            final meta = [
                              when,
                              if (size.isNotEmpty) size,
                            ].join(' • ');

                            return _LocalBackupTile(
                              fileName: item.fileName,
                              meta: meta,
                              canRestore: canRestore,
                              canDelete: canDelete,
                              onRestore: () => _restoreLocal(item),
                              onDelete: () => _deleteBackup(item),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _restoreLocal(BackupRecord item) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final analytics = ref.read(analyticsServiceProvider);
    final ok = await confirmDialog(
      context,
      title: l10n.backupRestore,
      body: l10n.backupConfirmRestore,
      icon: Icons.restore_rounded,
      confirmLabel: l10n.backupRestore,
      destructive: true,
    );
    if (!ok) return;
    try {
      await analytics.logEvent('restore_started');
      await ref.read(backupServiceProvider).restoreFromFile(
            item.localPath!,
            confirmStoreMismatch: (backupId, currentId) => confirmDialog(
              context,
              title: 'Different store?',
              body:
                  'This backup belongs to store #$backupId, but this device has store #${currentId ?? '-'}. Continue?',
              icon: Icons.warning_amber_rounded,
              confirmLabel: 'Restore anyway',
              destructive: true,
            ),
            afterClosed: () async {
              final db = await AppDatabase.open();
              ref.read(databaseHolderProvider.notifier).state = db;
              ref.invalidate(storeProfileProvider);
              ref.invalidate(appSettingsProvider);
            },
          );
      await analytics.logEvent('restore_success');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(l10n.commonSuccess)));
    } on RestoreException catch (e) {
      await analytics.logEvent('restore_failed');
      await analytics.recordError('restore_failed', reason: 'local');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _restoreDrive(DriveBackupEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final analytics = ref.read(analyticsServiceProvider);
    setState(() => _busy = true);
    try {
      await analytics.logEvent('restore_started');
      final bytes = await ref.read(driveClientProvider).download(entry.id);
      await ref.read(backupServiceProvider).restoreFromBytes(
            bytes,
            requestPassphraseForUnlock: () =>
                promptUnlockBackupPassphrase(context),
            confirmStoreMismatch: (backupId, currentId) => confirmDialog(
              context,
              title: 'Different store?',
              body:
                  'This backup belongs to store #$backupId, but this device has store #${currentId ?? '-'}. Continue?',
              icon: Icons.warning_amber_rounded,
              confirmLabel: 'Restore anyway',
              destructive: true,
            ),
            afterClosed: () async {
              final db = await AppDatabase.open();
              ref.read(databaseHolderProvider.notifier).state = db;
              ref.invalidate(storeProfileProvider);
              ref.invalidate(appSettingsProvider);
            },
          );
      await analytics.logEvent('restore_success');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(l10n.commonSuccess)));
    } on RestoreException catch (e) {
      await analytics.logEvent('restore_failed');
      await analytics.recordError('restore_failed', reason: 'drive');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      await analytics.logEvent('restore_failed');
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(l10n.errorsRestore)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ─── UI pieces ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TintIconBox extends StatelessWidget {
  const _TintIconBox({
    required this.icon,
    this.tint,
  });

  final List<List<dynamic>> icon;
  final Color? tint;
  final double size = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: HugeIcon(icon: icon, size: size * 0.48, color: color),
      ),
    );
  }
}

class _SoftActionChip extends StatelessWidget {
  const _SoftActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleDriveLogo extends StatelessWidget {
  const _GoogleDriveLogo();

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.52, size * 0.52),
          painter: _DriveLogoPainter(),
        ),
      ),
    );
  }
}

class _DriveLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF0F9D58);
    final yellow = Paint()..color = const Color(0xFFF4B400);

    // Simplified Drive triangle mark.
    final top = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.18, h * 0.58)
      ..lineTo(w * 0.82, h * 0.58)
      ..close();
    canvas.drawPath(top, blue);

    final left = Path()
      ..moveTo(w * 0.18, h * 0.58)
      ..lineTo(0, h)
      ..lineTo(w * 0.36, h)
      ..close();
    canvas.drawPath(left, green);

    final right = Path()
      ..moveTo(w * 0.82, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(w * 0.64, h)
      ..close();
    canvas.drawPath(right, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleDriveCard extends StatelessWidget {
  const _GoogleDriveCard({
    required this.signedIn,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.busy,
    required this.connectLabel,
    required this.disconnectLabel,
    required this.onToggle,
  });

  final bool signedIn;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool busy;
  final String connectLabel;
  final String disconnectLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (email ?? '');

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          if (signedIn && photoUrl != null && photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _GoogleDriveLogo(),
              ),
            )
          else
            const _GoogleDriveLogo(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Drive',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  signedIn
                      ? (displayName?.trim().isNotEmpty == true
                          ? '$name\n$email'
                          : (email ?? ''))
                      : 'Connect to sync encrypted backups',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _SoftActionChip(
            icon: signedIn
                ? HugeIcons.strokeRoundedUnlink01
                : HugeIcons.strokeRoundedLink01,
            label: signedIn ? disconnectLabel : 'Connect',
            onPressed: busy ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _LastBackupCard extends StatelessWidget {
  const _LastBackupCard({
    required this.last,
    required this.stamp,
    required this.onViewDetails,
  });

  final BackupRecord? last;
  final DateFormat stamp;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok = last?.status == 'successful';
    final accent = last == null
        ? scheme.onSurfaceVariant
        : (ok ? AppColors.success : scheme.error);

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: last == null
                    ? HugeIcons.strokeRoundedCloudOff
                    : (ok
                        ? HugeIcons.strokeRoundedTick02
                        : HugeIcons.strokeRoundedAlert02),
                size: 22,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last backup',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  last == null
                      ? AppLocalizations.of(context).backupNone
                      : stamp.format(
                          DateTime.fromMillisecondsSinceEpoch(last!.createdAt),
                        ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (last != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Status: ${last!.status.displayTitle}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onViewDetails,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 2),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 14,
                      color: scheme.primary,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          _TintIconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _AutoBackupMenu extends StatelessWidget {
  const _AutoBackupMenu({
    required this.value,
    required this.label,
    required this.daily,
    required this.weekly,
    required this.off,
    required this.onChanged,
  });

  final String value;
  final String label;
  final String daily;
  final String weekly;
  final String off;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'off', child: Text(off)),
        PopupMenuItem(value: 'daily', child: Text(daily)),
        PopupMenuItem(value: 'weekly', child: Text(weekly)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveBackupTile extends StatelessWidget {
  const _DriveBackupTile({
    required this.entry,
    required this.stamp,
    required this.busy,
    required this.onRestore,
    required this.onDelete,
  });

  final DriveBackupEntry entry;
  final DateFormat stamp;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = entry.modifiedTime == null
        ? 'Drive'
        : stamp.format(entry.modifiedTime!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          _TintIconBox(icon: HugeIcons.strokeRoundedCloudSavingDone02),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  when,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            enabled: !busy,
            onSelected: (v) {
              if (v == 'restore') onRestore();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'restore', child: Text('Restore')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalBackupTile extends StatelessWidget {
  const _LocalBackupTile({
    required this.fileName,
    required this.meta,
    required this.canRestore,
    required this.canDelete,
    required this.onRestore,
    required this.onDelete,
  });

  final String fileName;
  final String meta;
  final bool canRestore;
  final bool canDelete;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          _TintIconBox(icon: HugeIcons.strokeRoundedFile01),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (canRestore || canDelete)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'restore') onRestore();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                if (canRestore)
                  const PopupMenuItem(
                    value: 'restore',
                    child: Text('Restore'),
                  ),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
              ],
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMoreVertical,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
