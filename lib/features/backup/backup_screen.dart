import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

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
      messenger?.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Unable to delete backup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: GlassPageHeader(title: l10n.backupTitle),
      body: FutureBuilder(
        future: Future.wait([
          ref.read(backupServiceProvider).history(),
          ref.read(backupServiceProvider).lastSuccessful(),
          ref.read(driveClientProvider).accountEmail,
          ref.read(backupServiceProvider).localBackupDirectoryPath(),
        ]),
        builder: (context, snap) {
          final history = snap.data?[0] as List<BackupRecord>? ?? const [];
          final last = snap.data?[1] as BackupRecord?;
          final email = snap.data?[2] as String?;
          final backupPath = snap.data?[3] as String? ?? '…';
          final latestId = last?.id;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              SoftCard(
                child: Text(l10n.backupLocalOnly),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Local backup folder',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Downloads → POS Billing → backup',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      backupPath,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: backupPath),
                          );
                          if (!context.mounted) return;
                          showSnack(context, 'Backup path copied');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy path'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const IconBadge(icon: Icons.cloud_outlined),
                      title: Text(l10n.backupGoogle),
                      subtitle: Text(email ?? l10n.backupConnectGoogle),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            if (email == null) {
                              await ref.read(driveClientProvider).signIn();
                            } else {
                              await ref.read(driveClientProvider).signOut();
                            }
                            if (!mounted) return;
                            setState(() {});
                          } on DriveAuthException {
                            if (!context.mounted) return;
                            showSnack(context, l10n.errorsDriveAuth);
                          }
                        },
                        child: Text(
                          email == null
                              ? l10n.backupConnectGoogle
                              : l10n.backupDisconnectGoogle,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const IconBadge(icon: Icons.history_rounded),
                      title: Text(l10n.backupLast),
                      subtitle: Text(
                        last == null
                            ? l10n.backupNone
                            : DateFormat.yMMMd().add_jm().format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  last.createdAt,
                                ),
                              ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const IconBadge(icon: Icons.schedule_rounded),
                      title: Text(l10n.backupAutomatic),
                      subtitle: Text(settings?.autoBackup ?? 'off'),
                      trailing: DropdownButton<String>(
                        value: settings?.autoBackup ?? 'off',
                        items: [
                          DropdownMenuItem(
                            value: 'off',
                            child: Text(l10n.backupOff),
                          ),
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text(l10n.backupDaily),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text(l10n.backupWeekly),
                          ),
                        ],
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setAutoBackup(v ?? 'off'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        setState(() => _busy = true);
                        try {
                          await ref
                              .read(backupServiceProvider)
                              .createBackup(uploadToDrive: email != null);
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.commonSuccess)),
                          );
                          setState(() {});
                        } on BackupException {
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.errorsBackup)),
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: Text(l10n.backupNow),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: l10n.backupView),
              const SizedBox(height: 4),
              Text(
                'You can delete older backups. The latest successful backup is kept.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                EmptyState(title: l10n.backupNone)
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < history.length; i++) ...[
                        if (i > 0) const Divider(),
                        Builder(
                          builder: (context) {
                            final item = history[i];
                            final isLatestSuccessful =
                                item.status == 'successful' &&
                                    item.id == latestId;
                            final canRestore = item.status == 'successful' &&
                                item.localPath != null;
                            final canDelete = !isLatestSuccessful;

                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(child: Text(item.fileName)),
                                  if (isLatestSuccessful)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Latest',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(item.status),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canRestore)
                                    TextButton(
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.maybeOf(context);
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
                                          await ref
                                              .read(backupServiceProvider)
                                              .restoreFromFile(
                                                item.localPath!,
                                                afterClosed: () async {
                                                  final db =
                                                      await AppDatabase.open();
                                                  ref
                                                          .read(
                                                            databaseHolderProvider
                                                                .notifier,
                                                          )
                                                          .state =
                                                      db;
                                                  ref.invalidate(
                                                    storeProfileProvider,
                                                  );
                                                  ref.invalidate(
                                                    appSettingsProvider,
                                                  );
                                                },
                                              );
                                          if (!mounted) return;
                                          messenger?.showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text(l10n.commonSuccess),
                                            ),
                                          );
                                        } on RestoreException {
                                          if (!mounted) return;
                                          messenger?.showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text(l10n.errorsRestore),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(l10n.backupRestore),
                                    ),
                                  if (canDelete)
                                    IconButton(
                                      tooltip: 'Delete backup',
                                      onPressed: () => _deleteBackup(item),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                ],
                              ),
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
}
