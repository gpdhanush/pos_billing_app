import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/services/app_log_service.dart';
import 'package:pos_billing/core/services/app_reset_service.dart';
import 'package:pos_billing/features/premium/premium_sheets.dart';
import 'package:pos_billing/shared/widgets/app_logo.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _logoutAndWipe() async {
    if (_loggingOut) return;

    final deleteOk = await confirmDialog(
      context,
      title: 'Delete all data?',
      body: 'This permanently removes products, sales, customers, expenses, stock, store details, backups on this device, and security keys.\n\nData cannot be restored unless you already saved a backup file elsewhere.',
      icon: Icons.delete_forever_rounded,
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!deleteOk || !mounted) return;

    final logoutOk = await confirmDialog(
      context,
      title: 'Log out & reset app?',
      body: 'POS Billing will restart like a new install. You will set up language, theme, and store again.',
      icon: Icons.logout_rounded,
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!logoutOk || !mounted) return;

    setState(() => _loggingOut = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      await ref.read(appResetServiceProvider).wipeAllLocalData();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/onboarding');
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showSnack(context, 'Logout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.settingsTitle,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingsRow(
                      context,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Premium',
                      trailingWidget: Switch(
                        value: settings.premiumUnlocked,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setPremiumUnlocked(v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              settings.premiumUnlocked
                                  ? 'Unlimited access is on (toggle for testing).'
                                  : 'Free: 10 products, stocks & expenses each. Unlock ₹99 once.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'FAQ',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => showPremiumFaqSheet(context),
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                          TextButton(
                            onPressed: () => context.push('/premium'),
                            child: const Text('Unlock'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.storefront_outlined,
                      title: 'Store Settings',
                      hasChevron: true,
                      onTap: () => context.push('/settings/store'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.language_rounded,
                      title: l10n.settingsLanguage,
                      trailingText: settings.localeCode == 'ta'
                          ? l10n.languageTamil
                          : l10n.languageEnglish,
                      onTap: () => context.push('/setup/language'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.palette_outlined,
                      title: l10n.settingsTheme,
                      trailingText: 'Theme',
                      onTap: () => context.push('/setup/theme'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.fingerprint_rounded,
                      title: 'App Lock',
                      trailingWidget: Switch(
                        value: settings.biometricEnabled,
                        onChanged: (v) async {
                          if (v) {
                            final available = await ref
                                .read(pinServiceProvider)
                                .biometricAvailable();
                            if (!available) {
                              if (context.mounted) {
                                showSnack(
                                  context,
                                  'Biometrics unavailable on this device',
                                );
                              }
                              return;
                            }
                            final ok = await ref
                                .read(pinServiceProvider)
                                .authenticateBiometric(
                                  reason:
                                      'Enable biometric lock for POS Billing',
                                );
                            if (!ok) {
                              if (context.mounted) {
                                showSnack(context, 'Biometric not confirmed');
                              }
                              return;
                            }
                            await ref.read(pinServiceProvider).clearPin();
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setPinEnabled(false);
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setBiometricEnabled(true);
                            ref.read(unlockedProvider.notifier).state = true;
                          } else {
                            await ref.read(pinServiceProvider).clearPin();
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setPinEnabled(false);
                            await ref
                                .read(appSettingsProvider.notifier)
                                .setBiometricEnabled(false);
                            ref.read(unlockedProvider.notifier).state = true;
                          }
                        },
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                    //   child: Text(
                    //     'Unlock with fingerprint or face only. No PIN.',
                    //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    //           color: scheme.onSurfaceVariant,
                    //         ),
                    //   ),
                    // ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.print_outlined,
                      title: 'Printer',
                      hasChevron: true,
                      onTap: () => context.push('/printer'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.cloud_outlined,
                      title: 'Backup',
                      hasChevron: true,
                      onTap: () => context.push('/backup'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.file_download_outlined,
                      title: 'Export data',
                      hasChevron: true,
                      trailingWidget: settings.premiumUnlocked
                          ? null
                          : Icon(
                              Icons.lock_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                      onTap: () {
                        if (!settings.premiumUnlocked) {
                          showPremiumLockedAlert(
                            context: context,
                            ref: ref,
                            feature: 'Export data',
                          );
                          return;
                        }
                        context.push('/settings/export');
                      },
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.security_outlined,
                      title: 'Permissions',
                      hasChevron: true,
                      onTap: () => context.push('/permissions'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingsRow(
                      context,
                      icon: Icons.article_outlined,
                      title: 'Terms & Conditions',
                      hasChevron: true,
                      onTap: () {},
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      hasChevron: true,
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(l10n.privacyBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.commonClose),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: 'Contact us',
                      hasChevron: true,
                      onTap: () => context.push('/settings/contact'),
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.bug_report_outlined,
                      title: 'Send app logs',
                      hasChevron: true,
                      onTap: () async {
                        final ok = await AppLogService.sendLogsToSupport();
                        if (!context.mounted) return;
                        showSnack(
                          context,
                          ok
                              ? 'Share or email the log to ${AppLinks.supportEmail}'
                              : 'Unable to prepare logs',
                        );
                      },
                    ),
                    const Divider(indent: 68),
                    _settingsRow(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      trailingText: DbConstants.appVersion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Danger zone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 10),
              SoftCard(
                borderColor: scheme.error.withValues(alpha: 0.35),
                padding: EdgeInsets.zero,
                child: _settingsRow(
                  context,
                  icon: Icons.logout_rounded,
                  title: _loggingOut ? 'Logging out…' : 'Log out & reset',
                  hasChevron: true,
                  destructive: true,
                  onTap: _loggingOut ? null : _logoutAndWipe,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Deletes all local shop data permanently, then returns to setup.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 18),
              SoftCard(
                color: scheme.primary.withValues(alpha: 0.06),
                borderColor: scheme.primary.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const AppLogo(size: 42, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline-first billing built for daily shop use.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    bool hasChevron = false,
    bool destructive = false,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = destructive ? scheme.error : null;
    final trailing = trailingText != null
        ? Text(
            trailingText,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          )
        : trailingWidget ??
              (hasChevron
                  ? Icon(
                      Icons.chevron_right_rounded,
                      color: accent ?? scheme.onSurfaceVariant,
                    )
                  : null);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            size: 40,
            background: destructive
                ? scheme.error.withValues(alpha: 0.10)
                : null,
            foreground: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: accent),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
