import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/services/app_log_service.dart';
import 'package:pos_billing/core/services/app_reset_service.dart';
import 'package:pos_billing/shared/widgets/app_logo.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

/// Bottom-nav hub: shop tools plus app preferences (former Settings page).
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _loggingOut = false;

  String _themeLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'dark':
        return l10n.themeDark;
      case 'system':
        return l10n.themeSystem;
      case 'light':
      default:
        return l10n.themeLight;
    }
  }

  Future<void> _pickTheme(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget option({
          required String value,
          required String title,
          required String subtitle,
          required List<List<dynamic>> icon,
          required Color accent,
        }) {
          final selected = settings.themeModeName == value;
          return ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(icon: icon, size: 20, color: accent),
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : null,
            onTap: () => Navigator.pop(ctx, value),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.settingsTheme,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                option(
                  value: 'light',
                  title: l10n.themeLight,
                  subtitle: 'Bright & clear',
                  icon: HugeIcons.strokeRoundedSun01,
                  accent: const Color(0xFF3B82F6),
                ),
                option(
                  value: 'dark',
                  title: l10n.themeDark,
                  subtitle: 'Easy on the eyes',
                  icon: HugeIcons.strokeRoundedMoon02,
                  accent: const Color(0xFF6366F1),
                ),
                option(
                  value: 'system',
                  title: l10n.themeSystem,
                  subtitle: 'Match device setting',
                  icon: HugeIcons.strokeRoundedSettings01,
                  accent: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await ref.read(appSettingsProvider.notifier).setThemeMode(selected);
  }

  Future<void> _pickLanguage(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget option({
          required String value,
          required String title,
          required String subtitle,
          required List<List<dynamic>> icon,
        }) {
          final selected = settings.localeCode == value;
          return ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : null,
            onTap: () => Navigator.pop(ctx, value),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.settingsLanguage,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                option(
                  value: 'en',
                  title: l10n.languageEnglish,
                  subtitle: 'English',
                  icon: HugeIcons.strokeRoundedLanguageSquare,
                ),
                option(
                  value: 'ta',
                  title: l10n.languageTamil,
                  subtitle: 'தமிழ்',
                  icon: HugeIcons.strokeRoundedTranslate,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await ref.read(appSettingsProvider.notifier).setLocale(selected);
  }

  Future<void> _pickAccent(AppSettings settings) async {
    final current = AccentOptionX.fromStorage(settings.accent);
    final selected = await showModalBottomSheet<AccentOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Accent Color',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred color',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AccentOption.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, i) {
                    final option = AccentOption.values[i];
                    final selected = option == current;
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, option),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: option.seed,
                          border: Border.all(
                            color: selected
                                ? scheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: option.seed.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await ref
        .read(appSettingsProvider.notifier)
        .setAccent(selected.storageKey);
  }

  Future<void> _logoutAndWipe() async {
    if (_loggingOut) return;

    final deleteOk = await confirmDialog(
      context,
      title: 'Delete all data?',
      body:
          'This permanently removes products, sales, customers, expenses, stock, store details, backups on this device, and security keys.\n\nData cannot be restored unless you already saved a backup file elsewhere.',
      icon: Icons.delete_forever_rounded,
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!deleteOk || !mounted) return;

    final logoutOk = await confirmDialog(
      context,
      title: 'Log out & reset app?',
      body:
          'POS Billing will restart like a new install. You will set up language, theme, and store again.',
      icon: Icons.logout_rounded,
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!logoutOk || !mounted) return;

    setState(() => _loggingOut = true);
    final nav = Navigator.of(context, rootNavigator: true);
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
      if (nav.canPop()) nav.pop();
      if (!mounted) return;
      context.go('/onboarding');
    } catch (_) {
      if (nav.canPop()) nav.pop();
      if (!mounted) return;
      showSnack(context, 'Logout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _openPrivacyPolicy() {
    return context.push(
      '/browser?title=${Uri.encodeComponent('Privacy Policy')}'
      '&url=${Uri.encodeComponent(AppLinks.privacyPolicy)}',
    );
  }

  Future<void> _sendAppLogs() async {
    final ok = await AppLogService.sendLogsToSupport();
    if (!mounted) return;
    showSnack(
      context,
      ok
          ? 'Share pos_billing_crash.log — choose WhatsApp (${AppLinks.supportPhone})'
          : 'Unable to share log file',
    );
  }

  Future<void> _setBiometric(bool enabled) async {
    if (enabled) {
      final available =
          await ref.read(pinServiceProvider).biometricAvailable();
      if (!available) {
        if (mounted) {
          showSnack(context, 'Biometrics unavailable on this device');
        }
        return;
      }
      final ok = await ref.read(pinServiceProvider).authenticateBiometric(
            reason: 'Enable biometric lock for POS Billing',
          );
      if (!ok) {
        if (mounted) showSnack(context, 'Biometric not confirmed');
        return;
      }
      await ref.read(pinServiceProvider).clearPin();
      await ref.read(appSettingsProvider.notifier).setPinEnabled(false);
      await ref.read(appSettingsProvider.notifier).setBiometricEnabled(true);
      ref.read(unlockedProvider.notifier).state = true;
    } else {
      final ok = await ref.read(pinServiceProvider).authenticateBiometric(
            reason: 'Confirm to turn off app lock',
          );
      if (!ok) {
        if (mounted) showSnack(context, 'Biometric not confirmed');
        return;
      }
      await ref.read(pinServiceProvider).clearPin();
      await ref.read(appSettingsProvider.notifier).setPinEnabled(false);
      await ref.read(appSettingsProvider.notifier).setBiometricEnabled(false);
      ref.read(unlockedProvider.notifier).state = true;
    }
  }

  Widget _divider(ColorScheme scheme) => Divider(
        height: 1,
        indent: 70,
        color: scheme.outline.withValues(alpha: 0.5),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final accent = AccentOptionX.fromStorage(settings.accent);
    final languageLabel = settings.localeCode == 'ta'
        ? l10n.languageTamil
        : l10n.languageEnglish;

    final shop = <_MoreItem>[
      _MoreItem(
        icon: HugeIcons.strokeRoundedPackage,
        accent: AppColors.success,
        title: l10n.productsTitle,
        subtitle: 'Catalog & prices',
        onTap: () => context.push('/products'),
      ),
      _MoreItem(
        icon: HugeIcons.strokeRoundedTag01,
        accent: const Color(0xFF7C3AED),
        title: l10n.categoriesTitle,
        subtitle: 'Organize your products',
        onTap: () => context.push('/categories'),
      ),
      _MoreItem(
        icon: HugeIcons.strokeRoundedUserGroup,
        accent: scheme.primary,
        title: l10n.customersTitle,
        subtitle: 'Buyers & credit',
        onTap: () => context.push('/customers'),
      ),
    ];

    final business = <_MoreItem>[
      _MoreItem(
        icon: HugeIcons.strokeRoundedWallet01,
        accent: AppColors.danger,
        title: l10n.expensesTitle,
        subtitle: 'Shop spending',
        onTap: () => context.push('/expenses'),
      ),
      _MoreItem(
        icon: HugeIcons.strokeRoundedAnalyticsUp,
        accent: AppColors.success,
        title: l10n.reportsTitle,
        subtitle: 'Sales & business overview',
        onTap: () => context.push('/reports'),
      ),
    ];

    final tools = <_MoreItem>[
      _MoreItem(
        icon: HugeIcons.strokeRoundedCloudUpload,
        accent: scheme.primary,
        title: 'Backup & Restore',
        subtitle: 'Google Drive, local backup',
        onTap: () => context.push('/backup'),
      ),
      _MoreItem(
        icon: HugeIcons.strokeRoundedFileExport,
        accent: AppColors.warning,
        title: 'Export data',
        subtitle: 'Share reports & files',
        onTap: () => context.push('/settings/export'),
      ),
      _MoreItem(
        icon: HugeIcons.strokeRoundedPrinter,
        accent: const Color(0xFF7C3AED),
        title: 'Printer',
        subtitle: 'Receipt printer settings',
        onTap: () => context.push('/printer'),
      ),
    ];

    final support = <_MoreItem>[
      _MoreItem(
        icon: HugeIcons.strokeRoundedHelpCircle,
        accent: const Color(0xFFDB2777),
        title: 'Help & Feedback',
        subtitle: 'Guides, FAQs and support',
        onTap: () => context.push('/settings/contact'),
      ),
    ];

    final sections = <_MoreSection>[
      _MoreSection(
        icon: HugeIcons.strokeRoundedStore01,
        title: 'Shop Management',
        hint: 'Manage your shop',
        items: shop,
      ),
      _MoreSection(
        icon: HugeIcons.strokeRoundedChartAverage,
        title: 'Business',
        hint: 'Track your business',
        items: business,
      ),
      _MoreSection(
        icon: HugeIcons.strokeRoundedTools,
        title: 'Data & Tools',
        hint: 'Backup & devices',
        items: tools,
      ),
      _MoreSection(
        icon: HugeIcons.strokeRoundedCustomerSupport,
        title: 'Support',
        hint: 'Help & info',
        items: support,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navMore,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shop tools & preferences',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            for (final section in sections) ...[
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: _SectionHeader(
                  icon: section.icon,
                  title: section.title,
                  hint: section.hint,
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SoftCard(
                  radius: AppRadii.md,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < section.items.length; i++) ...[
                        if (i > 0) _divider(scheme),
                        _MoreRow(item: section.items[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: _SectionHeader(
                icon: HugeIcons.strokeRoundedSettings01,
                title: 'Preferences',
                hint: 'App & store',
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                radius: AppRadii.md,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedStore01,
                        accent: scheme.primary,
                        title: 'Store Settings',
                        subtitle: 'Business profile & receipts',
                        onTap: () => context.push('/settings/store'),
                      ),
                    ),
                    _divider(scheme),
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedFingerprintScan,
                        accent: AppColors.success,
                        title: 'App Lock',
                        subtitle: 'Fingerprint or face unlock',
                        trailing: Switch.adaptive(
                          value: settings.biometricEnabled,
                          onChanged: _setBiometric,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: _SectionHeader(
                icon: HugeIcons.strokeRoundedPaintBoard,
                title: 'Appearance',
                hint: 'Look & language',
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                radius: AppRadii.md,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedSun01,
                        accent: const Color(0xFF3B82F6),
                        title: l10n.settingsTheme,
                        subtitle: 'Light, Dark or System default',
                        value: _themeLabel(l10n, settings.themeModeName),
                        onTap: () => _pickTheme(settings),
                      ),
                    ),
                    _divider(scheme),
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedDroplet,
                        accent: const Color(0xFF7C3AED),
                        title: 'Accent Color',
                        subtitle: 'Choose your preferred color',
                        valueWidget: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accent.seed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        onTap: () => _pickAccent(settings),
                      ),
                    ),
                    _divider(scheme),
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedLanguageCircle,
                        accent: AppColors.success,
                        title: l10n.settingsLanguage,
                        subtitle: 'English / தமிழ்',
                        value: languageLabel,
                        onTap: () => _pickLanguage(settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: _SectionHeader(
                icon: HugeIcons.strokeRoundedInformationCircle,
                title: 'About',
                hint: 'Legal & support',
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                radius: AppRadii.md,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedSecurityLock,
                        accent: scheme.primary,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: _openPrivacyPolicy,
                      ),
                    ),
                    _divider(scheme),
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedBug01,
                        accent: AppColors.warning,
                        title: 'Send app logs',
                        subtitle: 'Share diagnostics on WhatsApp',
                        onTap: _sendAppLogs,
                      ),
                    ),
                    _divider(scheme),
                    _MoreRow(
                      item: _MoreItem(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        accent: const Color(0xFF0EA5E9),
                        title: 'App Version',
                        subtitle: 'POS Billing ${DbConstants.appVersion}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: _SectionHeader(
                icon: HugeIcons.strokeRoundedAlert02,
                title: 'Danger zone',
                hint: 'Irreversible',
                color: scheme.error,
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                radius: AppRadii.md,
                borderColor: scheme.error.withValues(alpha: 0.35),
                padding: EdgeInsets.zero,
                child: _MoreRow(
                  item: _MoreItem(
                    icon: HugeIcons.strokeRoundedLogout01,
                    accent: scheme.error,
                    title: _loggingOut ? 'Logging out…' : 'Log out & reset',
                    subtitle: 'Delete all local shop data',
                    destructive: true,
                    onTap: _loggingOut ? null : _logoutAndWipe,
                  ),
                ),
              ),
            ),
            ContainedSliver(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              child: SoftCard(
                radius: AppRadii.md,
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
            ),
          ],
        ),
      ),
    );
  }
}

class ContainedSliver extends StatelessWidget {
  const ContainedSliver({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MoreSection {
  const _MoreSection({
    required this.icon,
    required this.title,
    required this.hint,
    required this.items,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String hint;
  final List<_MoreItem> items;
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.value,
    this.valueWidget,
    this.destructive = false,
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? value;
  final Widget? valueWidget;
  final bool destructive;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.hint,
    this.color,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String hint;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.primary;
    return Row(
      children: [
        HugeIcon(icon: icon, size: 18, color: tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Text(
          hint,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item});

  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = item.destructive ? scheme.error : scheme.onSurface;

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(
                icon: item.icon,
                size: 20,
                color: item.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (item.trailing != null)
            item.trailing!
          else ...[
            if (item.valueWidget != null) ...[
              item.valueWidget!,
              const SizedBox(width: 6),
            ] else if (item.value != null) ...[
              Text(
                item.value!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
            ],
            if (item.onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ],
      ),
    );

    if (item.onTap == null) return row;
    return InkWell(onTap: item.onTap, child: row);
  }
}
