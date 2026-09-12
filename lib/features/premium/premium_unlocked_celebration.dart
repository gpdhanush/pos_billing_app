import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/app_logo.dart';

/// Celebration popup with fireworks/confetti after Premium unlock.
Future<void> showPremiumUnlockedCelebration(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'Premium unlocked',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, anim, secondary) {
      return const _PremiumUnlockedCelebration();
    },
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _PremiumUnlockedCelebration extends StatefulWidget {
  const _PremiumUnlockedCelebration();

  @override
  State<_PremiumUnlockedCelebration> createState() =>
      _PremiumUnlockedCelebrationState();
}

class _PremiumUnlockedCelebrationState
    extends State<_PremiumUnlockedCelebration> {
  late final ConfettiController _center;
  late final ConfettiController _left;
  late final ConfettiController _right;
  Timer? _autoClose;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _center = ConfettiController(duration: const Duration(seconds: 3));
    _left = ConfettiController(duration: const Duration(seconds: 3));
    _right = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _center.play();
      _left.play();
      _right.play();
    });
    _autoClose = Timer(const Duration(milliseconds: 2800), _closeOnce);
  }

  void _closeOnce() {
    if (_closed || !mounted) return;
    _closed = true;
    _autoClose?.cancel();
    _autoClose = null;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _center.dispose();
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _center,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 28,
              maxBlastForce: 28,
              minBlastForce: 10,
              gravity: 0.18,
              colors: [
                scheme.primary,
                AppColors.success,
                AppColors.warning,
                const Color(0xFFE91E63),
                const Color(0xFF00BCD4),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _left,
              blastDirection: -pi / 4,
              emissionFrequency: 0.06,
              numberOfParticles: 16,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.2,
              colors: [scheme.primary, AppColors.success, AppColors.warning],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _right,
              blastDirection: -3 * pi / 4,
              emissionFrequency: 0.06,
              numberOfParticles: 16,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.2,
              colors: [scheme.primary, AppColors.success, AppColors.warning],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(
                color: isLight ? AppColors.panel : AppColors.panelDark,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: [
                  BoxShadow(
                    color: scheme.onSurface.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 72, radius: 18, showShadow: true),
                  const SizedBox(height: 16),
                  Icon(LineIcons.trophy, size: 36, color: AppColors.warning),
                  const SizedBox(height: 10),
                  Text(
                    'Congratulations!',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium is now active. Enjoy unlimited products, stocks, expenses, reports and export.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _closeOnce,
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
