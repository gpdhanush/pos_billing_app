import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/router/app_router.dart';
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
    final destinations = navDestinations(l10n);
    final shell = widget.shell;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onRootBack();
      },
      child: Scaffold(
        body: SafeArea(top: false, bottom: false, child: shell),
        bottomNavigationBar: SoftNavBar(
          currentIndex: shell.currentIndex,
          items: [
            for (final item in destinations)
              SoftNavItem(icon: item.icon, label: item.label),
          ],
          onTap: (index) {
            if (index == 4 && shell.currentIndex == 4) return;
            _goBranch(index);
          },
        ),
      ),
    );
  }
}
