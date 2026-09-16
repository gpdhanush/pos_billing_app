import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/router/app_router.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _exitSheetOpen = false;

  Future<bool> _confirmDiscardCart() async {
    final cart = ref.read(cartProvider);
    if (!cart.hasUnsavedValues) return true;

    final l10n = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l10n.billingLeaveConfirm,
      body: l10n.billingLeaveBody,
      icon: Icons.shopping_cart_outlined,
      confirmLabel: l10n.commonExit,
      cancelLabel: l10n.commonStay,
      destructive: true,
    );
    if (!ok) return false;
    ref.read(cartProvider.notifier).clear();
    return true;
  }

  Future<void> _goBranch(int index) async {
    if (widget.shell.currentIndex == 2 && index != 2) {
      final ok = await _confirmDiscardCart();
      if (!ok || !mounted) return;
    }
    widget.shell.goBranch(index, initialLocation: true);
  }

  Future<void> _onRootBack() async {
    if (_exitSheetOpen) return;

    // Prefer leaving a secondary tab for Home before asking to exit.
    if (widget.shell.currentIndex != 0) {
      if (widget.shell.currentIndex == 2) {
        final ok = await _confirmDiscardCart();
        if (!ok || !mounted) return;
      }
      widget.shell.goBranch(0, initialLocation: true);
      return;
    }

    _exitSheetOpen = true;
    final shouldExit = await showExitBottomSheet(context);
    _exitSheetOpen = false;
    if (shouldExit && mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = navDestinations(l10n);
    final shell = widget.shell;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onRootBack();
      },
      child: Scaffold(
        body: SafeArea(top: false, bottom: false, child: shell),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.onSurface.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    _navItem(
                      context: context,
                      label: items[0].label,
                      icon: items[0].icon,
                      selected: shell.currentIndex == 0,
                      onTap: () => _goBranch(0),
                    ),
                    _navItem(
                      context: context,
                      label: items[1].label,
                      icon: items[1].icon,
                      selected: shell.currentIndex == 1,
                      onTap: () => _goBranch(1),
                    ),
                    _navItem(
                      context: context,
                      label: l10n.navBilling,
                      icon: const Icon(LineIcons.cashRegister),
                      selected: shell.currentIndex == 2,
                      onTap: () => _goBranch(2),
                    ),
                    _navItem(
                      context: context,
                      label: items[3].label,
                      icon: items[3].icon,
                      selected: shell.currentIndex == 3,
                      onTap: () => _goBranch(3),
                    ),
                    _navItem(
                      context: context,
                      label: items[4].label,
                      icon: items[4].icon,
                      selected: shell.currentIndex == 4,
                      onTap: () async {
                        if (shell.currentIndex != 4) {
                          await _goBranch(4);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required String label,
    required Widget icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 26),
              child: icon,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
