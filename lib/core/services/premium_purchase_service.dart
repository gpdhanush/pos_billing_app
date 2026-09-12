import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/constants/premium_config.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class PremiumOrder {
  const PremiumOrder({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    this.name = 'POS Billing Premium',
    this.description = 'One-time Premium unlock',
  });

  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String name;
  final String description;
}

class PremiumPurchaseException implements Exception {
  PremiumPurchaseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PremiumPurchaseService {
  PremiumPurchaseService({
    required this.connectivity,
    required this.settings,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final ConnectivityService connectivity;
  final AppSettingsController settings;
  final http.Client _client;

  Razorpay? _razorpay;

  Future<String> deviceId() async {
    final existing = await settings.readRaw(SettingKeys.installId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await settings.writeRaw(SettingKeys.installId, id);
    return id;
  }

  Future<void> ensureOnline() async {
    final online = await connectivity.isOnline;
    if (!online) {
      throw PremiumPurchaseException(
        'Internet required. Connect and try again to verify Premium on our server.',
      );
    }
  }

  Future<bool> fetchPremiumStatus() async {
    await ensureOnline();
    final id = await deviceId();
    final uri = Uri.parse('${PremiumApiConfig.baseUrl}${PremiumApiConfig.statusPath}')
        .replace(queryParameters: {'deviceId': id});
    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PremiumPurchaseException(
        'Plan is unavailable right now. Please check your connection and try again.',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final unlocked = body['premium'] == true || body['unlocked'] == true;
    if (unlocked) {
      await settings.setPremiumUnlocked(true);
      final token = body['licenseToken'] as String?;
      if (token != null && token.isNotEmpty) {
        await settings.writeRaw(SettingKeys.premiumLicenseToken, token);
      }
    }
    return unlocked;
  }

  Future<PremiumOrder> createOrder({
    required String storeName,
    String preferredMethod = 'phonepe',
  }) async {
    await ensureOnline();
    final id = await deviceId();
    final uri =
        Uri.parse('${PremiumApiConfig.baseUrl}${PremiumApiConfig.createOrderPath}');
    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'deviceId': id,
            'storeName': storeName,
            'amountPaise': PremiumLimits.unlockPricePaise,
            'preferredMethod': preferredMethod,
            'product': 'premium_lifetime',
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PremiumPurchaseException(
        'Plan is unavailable right now. Please check your connection and try again.',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final orderId = '${body['orderId'] ?? body['id'] ?? ''}';
    final keyId =
        '${body['keyId'] ?? body['razorpayKeyId'] ?? PremiumApiConfig.razorpayKeyId}';
    if (orderId.isEmpty || keyId.isEmpty) {
      throw PremiumPurchaseException(
        'Payment gateway is not configured on the server yet.',
      );
    }

    return PremiumOrder(
      orderId: orderId,
      amountPaise:
          (body['amountPaise'] as num?)?.toInt() ?? PremiumLimits.unlockPricePaise,
      currency: '${body['currency'] ?? 'INR'}',
      keyId: keyId,
      name: '${body['name'] ?? 'POS Billing Premium'}',
      description: '${body['description'] ?? 'One-time Premium unlock'}',
    );
  }

  Future<PaymentSuccessResponse> openCheckout({
    required PremiumOrder order,
    String? contact,
    String? email,
  }) async {
    _razorpay?.clear();
    final razorpay = Razorpay();
    _razorpay = razorpay;
    final completer = Completer<PaymentSuccessResponse>();

    void onSuccess(PaymentSuccessResponse response) {
      if (!completer.isCompleted) completer.complete(response);
    }

    void onError(PaymentFailureResponse response) {
      if (!completer.isCompleted) {
        completer.completeError(
          PremiumPurchaseException(
            response.message?.trim().isNotEmpty == true
                ? response.message!
                : 'Payment cancelled or failed.',
          ),
        );
      }
    }

    void onExternal(ExternalWalletResponse response) {
      debugPrint('External wallet: ${response.walletName}');
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternal);

    razorpay.open({
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': order.name,
      'description': order.description,
      'order_id': order.orderId,
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      'theme': {'color': '#2F6BFF'},
    });

    try {
      return await completer.future.timeout(const Duration(minutes: 10));
    } finally {
      razorpay.clear();
      if (identical(_razorpay, razorpay)) _razorpay = null;
    }
  }

  Future<void> verifyAndUnlock({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await ensureOnline();
    final id = await deviceId();
    final uri =
        Uri.parse('${PremiumApiConfig.baseUrl}${PremiumApiConfig.verifyPath}');
    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'deviceId': id,
            'orderId': orderId,
            'paymentId': paymentId,
            'signature': signature,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PremiumPurchaseException(
        'Could not verify payment on server. Keep internet on and retry.',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final ok = body['premium'] == true ||
        body['unlocked'] == true ||
        body['verified'] == true;
    if (!ok) {
      throw PremiumPurchaseException(
        'Server rejected this payment. Contact support if amount was deducted.',
      );
    }

    await settings.setPremiumUnlocked(true);
    final token = body['licenseToken'] as String?;
    if (token != null && token.isNotEmpty) {
      await settings.writeRaw(SettingKeys.premiumLicenseToken, token);
    }
  }

  /// Purchase flow:
  /// 1) Needs internet
  /// 2) If Razorpay/server not configured yet → unlock locally
  /// 3) Else create order → Razorpay → verify → unlock
  Future<void> purchasePremium({
    required String storeName,
    String preferredMethod = 'phonepe',
    String? contact,
    String? email,
  }) async {
    await ensureOnline();

    // Live keys / server not wired yet — still unlock after online check.
    if (!PremiumApiConfig.requireServer && !PremiumApiConfig.hasRazorpayKey) {
      await settings.setPremiumUnlocked(true);
      return;
    }

    try {
      final order = await createOrder(
        storeName: storeName,
        preferredMethod: preferredMethod,
      );
      final payment = await openCheckout(
        order: order,
        contact: contact,
        email: email,
      );
      final paymentId = payment.paymentId;
      final signature = payment.signature;
      if (paymentId == null ||
          paymentId.isEmpty ||
          signature == null ||
          signature.isEmpty) {
        throw PremiumPurchaseException(
          'Incomplete payment response from gateway.',
        );
      }
      await verifyAndUnlock(
        orderId: order.orderId,
        paymentId: paymentId,
        signature: signature,
      );
    } on PremiumPurchaseException {
      rethrow;
    } catch (_) {
      if (!PremiumApiConfig.requireServer) {
        await settings.setPremiumUnlocked(true);
        return;
      }
      throw PremiumPurchaseException(
        'Plan is unavailable right now. Please check your connection and try again.',
      );
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
