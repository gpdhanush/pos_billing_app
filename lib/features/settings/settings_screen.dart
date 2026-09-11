import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                      child: Text(
                        'Unlock with fingerprint or face only. No PIN.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      trailingText: DbConstants.appVersion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SoftCard(
                color: scheme.primary.withValues(alpha: 0.06),
                borderColor: scheme.primary.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.verified_outlined),
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
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final trailing = trailingText != null
        ? Text(
            trailingText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          )
        : trailingWidget ??
            (hasChevron
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  )
                : null);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
