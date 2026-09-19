import 'package:flutter/material.dart';
import 'package:soft_ui_kit/src/theme/app_theme.dart';

/// Circular accent swatch used in theme pickers.
class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 52,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor = AppTheme.onColor(color);
    return AnimatedScale(
      scale: selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white.withValues(alpha: 0.55),
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: selected ? 0.4 : 0.2),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? Icon(Icons.check_rounded, color: onColor, size: size * 0.38)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Wrap of [AccentOption] swatches for setup / settings.
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.spacing = 12,
  });

  final AccentOption selected;
  final ValueChanged<AccentOption> onSelected;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final accent in AccentOption.values)
          AccentSwatch(
            color: accent.seed,
            selected: selected == accent,
            onTap: () => onSelected(accent),
          ),
      ],
    );
  }
}
