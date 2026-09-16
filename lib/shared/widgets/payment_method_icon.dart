import 'package:flutter/material.dart';
import 'package:pos_billing/core/constants/app_assets.dart';
import 'package:pos_billing/core/constants/app_constants.dart';

/// PNG badge for cash / UPI / card / credit payment methods.
class PaymentMethodIcon extends StatelessWidget {
  const PaymentMethodIcon({
    super.key,
    required this.method,
    this.size = 40,
    this.radius = 10,
  });

  final String method;
  final double size;
  final double radius;

  static String? assetFor(String method) {
    switch (method.toLowerCase().trim()) {
      case PaymentMethods.cash:
        return AppAssets.payCash;
      case PaymentMethods.upi:
        return AppAssets.payUpi;
      case PaymentMethods.card:
        return AppAssets.payCard;
      case PaymentMethods.credit:
        return AppAssets.payCredit;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asset = assetFor(method);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: asset == null
            ? ColoredBox(
                color: scheme.primary.withValues(alpha: 0.10),
                child: Icon(
                  Icons.payments_outlined,
                  size: size * 0.48,
                  color: scheme.primary,
                ),
              )
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.primary.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.payments_outlined,
                    size: size * 0.48,
                    color: scheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}
