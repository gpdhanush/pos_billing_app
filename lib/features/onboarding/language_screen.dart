import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/features/onboarding/onboarding_widgets.dart';
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
      body: OnboardBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: OnboardHeroIcon(
                  icon: HugeIcons.strokeRoundedLanguageCircle,
                  size: 88,
                  iconSize: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.languageTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 28),
              OnboardOptionCard(
                title: l10n.languageEnglish,
                subtitle: l10n.languageEnglishNative,
                icon: HugeIcons.strokeRoundedLanguageSquare,
                selected: current == 'en',
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).setLocale('en'),
              ),
              const SizedBox(height: 12),
              OnboardOptionCard(
                title: l10n.languageTamil,
                subtitle: l10n.languageTamilNative,
                icon: HugeIcons.strokeRoundedTranslate,
                selected: current == 'ta',
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).setLocale('ta'),
              ),
              const SizedBox(height: 32),
              OnboardPrimaryButton(
                label: l10n.commonContinue,
                icon: HugeIcons.strokeRoundedArrowRight01,
                onPressed: () {
                  dismissKeyboard();
                  final setupDone = ref
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
              ),
            ],
          ),
        ),
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
      body: OnboardBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: OnboardHeroIcon(
                  icon: HugeIcons.strokeRoundedPaintBoard,
                  size: 88,
                  iconSize: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.themeTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.themeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 28),
              OnboardOptionCard(
                title: l10n.themeLight,
                subtitle: l10n.themeLightHint,
                icon: HugeIcons.strokeRoundedSun03,
                selected: settings.themeModeName == 'light',
                onTap: () => ref
                    .read(appSettingsProvider.notifier)
                    .setThemeMode('light'),
              ),
              const SizedBox(height: 12),
              OnboardOptionCard(
                title: l10n.themeDark,
                subtitle: l10n.themeDarkHint,
                icon: HugeIcons.strokeRoundedMoon02,
                selected: settings.themeModeName == 'dark',
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).setThemeMode('dark'),
              ),
              const SizedBox(height: 12),
              OnboardOptionCard(
                title: l10n.themeSystem,
                subtitle: l10n.themeSystemHint,
                icon: HugeIcons.strokeRoundedComputerSettings,
                selected: settings.themeModeName == 'system',
                onTap: () => ref
                    .read(appSettingsProvider.notifier)
                    .setThemeMode('system'),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.themeAccent,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              AccentPicker(
                selected: AccentOptionX.fromStorage(settings.accent),
                onSelected: (accent) => ref
                    .read(appSettingsProvider.notifier)
                    .setAccent(accent.name),
              ),
              const SizedBox(height: 32),
              OnboardPrimaryButton(
                label: l10n.commonContinue,
                icon: HugeIcons.strokeRoundedArrowRight01,
                onPressed: () {
                  dismissKeyboard();
                  final setupDone = ref
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
