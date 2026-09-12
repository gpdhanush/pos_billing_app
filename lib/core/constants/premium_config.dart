import 'package:pos_billing/core/constants/app_constants.dart';

/// Backend + Razorpay config for Premium purchase.
///
/// Pass at build time:
/// `--dart-define=PREMIUM_API_BASE=https://your.api`
/// `--dart-define=RAZORPAY_KEY_ID=rzp_live_xxx`
class PremiumApiConfig {
  static const baseUrl = String.fromEnvironment(
    'PREMIUM_API_BASE',
    defaultValue: 'https://posbilling.app/api',
  );

  /// Public Razorpay key (safe on client). Prefer key returned by create-order.
  static const razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  static const createOrderPath = '/premium/create-order';
  static const verifyPath = '/premium/verify';
  static const statusPath = '/premium/status';
}

class PremiumPlanOffer {
  const PremiumPlanOffer({
    required this.amountPaise,
    required this.compareAtPaise,
    required this.title,
    required this.badge,
    required this.subtitle,
  });

  final int amountPaise;
  final int compareAtPaise;
  final String title;
  final String badge;
  final String subtitle;

  factory PremiumPlanOffer.local() => const PremiumPlanOffer(
        amountPaise: PremiumLimits.unlockPricePaise,
        compareAtPaise: 19900,
        title: 'One-time unlock',
        badge: 'ONE TIME ONLY',
        subtitle: 'Lifetime forever · No renewals',
      );
}
