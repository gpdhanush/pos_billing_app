import 'package:flutter/material.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_assets.dart';

/// App brand logo from [AppAssets.logo].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.radius,
    this.showShadow = false,
  });

  final double size;
  final double? radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadii.lg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.point_of_sale_rounded,
            size: size * 0.45,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
