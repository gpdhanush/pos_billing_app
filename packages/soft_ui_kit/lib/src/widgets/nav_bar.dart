import 'package:flutter/material.dart';
import 'package:soft_ui_kit/src/theme/app_theme.dart';

/// One tab in a [SoftNavBar].
class SoftNavItem {
  const SoftNavItem({required this.icon, required this.label});

  /// Typically an [Icon]. Color is applied by the bar.
  final Widget icon;

  /// Short label shown under the icon.
  final String label;
}

/// Floating capsule bottom navigation bar.
///
/// Place it on [Scaffold.bottomNavigationBar]. Selected items use
/// [ColorScheme.primary]; idle items use [ColorScheme.onSurfaceVariant].
///
/// ```dart
/// SoftNavBar(
///   currentIndex: index,
///   onTap: (i) => setState(() => index = i),
///   items: const [
///     SoftNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
///     SoftNavItem(icon: Icon(Icons.history), label: 'History'),
///     SoftNavItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Billing'),
///   ],
/// )
/// ```
class SoftNavBar extends StatelessWidget {
  const SoftNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<SoftNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
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
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    label: items[i].label,
                    icon: items[i].icon,
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
