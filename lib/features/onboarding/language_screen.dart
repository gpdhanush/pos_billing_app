import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.watch(appSettingsProvider).valueOrNull?.localeCode ?? 'en';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(title: l10n.languageTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            l10n.languageSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              children: [
                _langTile(
                  context,
                  title: l10n.languageEnglish,
                  selected: current == 'en',
                  onTap: () =>
                      ref.read(appSettingsProvider.notifier).setLocale('en'),
                ),
                const Divider(),
                _langTile(
                  context,
                  title: l10n.languageTamil,
                  selected: current == 'ta',
                  onTap: () =>
                      ref.read(appSettingsProvider.notifier).setLocale('ta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              dismissKeyboard();
              final setupDone =
                  ref
                      .read(storeProfileProvider)
                      .valueOrNull
                      ?.isSetupCompleted ??
                  false;
              if (setupDone) {
                context.pop();
              } else {
                context.go('/setup/theme');
              }
            },
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }

  Widget _langTile(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(title: l10n.themeTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            l10n.themeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.themeLight),
                  selected: settings.themeModeName == 'light',
                  onSelected: (_) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode('light'),
                ),
                ChoiceChip(
                  label: Text(l10n.themeDark),
                  selected: settings.themeModeName == 'dark',
                  onSelected: (_) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode('dark'),
                ),
                ChoiceChip(
                  label: Text(l10n.themeSystem),
                  selected: settings.themeModeName == 'system',
                  onSelected: (_) => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode('system'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: l10n.themeAccent),
          const SizedBox(height: 10),
          SoftCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final accent in AccentOption.values)
                  _AccentSwatch(
                    option: accent,
                    label: accent.label,
                    selected: settings.accent == accent.name,
                    onTap: () => ref
                        .read(appSettingsProvider.notifier)
                        .setAccent(accent.name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              dismissKeyboard();
              final setupDone =
                  ref
                      .read(storeProfileProvider)
                      .valueOrNull
                      ?.isSetupCompleted ??
                  false;
              if (setupDone) {
                context.pop();
              } else {
                context.go('/setup/store');
              }
            },
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AccentOption option;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: 86,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected
                ? option.seed
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: option.seed,
                shape: BoxShape.circle,
              ),
            ),
            // const SizedBox(height: 8),
            // Text(
            //   label,
            //   style: Theme.of(context).textTheme.labelSmall,
            //   textAlign: TextAlign.center,
            //   maxLines: 2,
            //   overflow: TextOverflow.ellipsis,
            // ),
          ],
        ),
      ),
    );
  }
}
