import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos_billing/core/constants/app_constants.dart';

/// Premium payment config — values loaded from `.env` (see `.env.example`).
class PremiumApiConfig {
  static String get baseUrl {
    final v = dotenv.maybeGet('PREMIUM_API_BASE')?.trim();
    if (v == null || v.isEmpty) return 'https://posbilling.app/api';
    return v;
  }

  /// Public Razorpay key (safe on client). Prefer key returned by create-order.
  static String get razorpayKeyId =>
      dotenv.maybeGet('RAZORPAY_KEY_ID')?.trim() ?? '';

  /// When true, Unlock requires live server + gateway (no local fallback).
  static bool get requireServer {
    final v = dotenv.maybeGet('PREMIUM_REQUIRE_SERVER')?.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  static const createOrderPath = '/premium/create-order';
  static const verifyPath = '/premium/verify';
  static const statusPath = '/premium/status';

  static bool get hasRazorpayKey => razorpayKeyId.isNotEmpty;
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
        compareAtPaise: 49900,
        title: 'Grow your shop faster',
        badge: 'LIMITED OFFER',
        subtitle: 'One-time · Lifetime Premium',
      );
}
