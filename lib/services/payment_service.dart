import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../core/constants/app_constants.dart';

final paymentServiceProvider = Provider<PaymentService>((_) => PaymentService());

class PaymentService {
  static const String _subscriptionKey = 'omniflix_subscription_type';
  static const String _expiryKey       = 'omniflix_expiry_date';

  // ── Region helpers ──────────────────────────────────────────────────────────

  /// Derives FC equivalent of a USD price at the current indicative rate.
  static int usdToFc(double usd) => (usd * 2850).round();

  String formatUsd(double amount) =>
      '\$${amount.toStringAsFixed(2)}';

  String formatEur(double amount) =>
      '€${amount.toStringAsFixed(2)}';

  // ── Subscription management ────────────────────────────────────────────────

  Future<Subscription> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr  = prefs.getString(_subscriptionKey);
    final expiryStr = prefs.getString(_expiryKey);

    if (typeStr == null || expiryStr == null) return const Subscription.none();

    final type = SubscriptionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SubscriptionType.none,
    );
    if (type == SubscriptionType.none) return const Subscription.none();

    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return const Subscription.none();

    return Subscription(
      type: type,
      expiryDate: expiry,
      isActive: DateTime.now().isBefore(expiry),
    );
  }

  Future<bool> hasActiveSubscription() async {
    final sub = await getCurrentSubscription();
    return sub.isActive && !sub.isExpired;
  }

  Future<void> _activateSubscription(SubscriptionType plan) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = plan == SubscriptionType.daily
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 30));
    await prefs.setString(_subscriptionKey, plan.name);
    await prefs.setString(_expiryKey, expiry.toIso8601String());
  }

  // ── M-Pesa DRC (Vodacom) ───────────────────────────────────────────────────

  /// Builds the USSD code that the customer dials to pay the OmniFlix
  /// M-Pesa merchant account (+243-839495208).
  /// Vodacom DRC format: *150*1*[montant]*[marchand]#
  String getMpesaUssdCode(int amountFc) {
    return AppConstants.mpesaUssdTemplate
        .replaceFirst('{amount}', amountFc.toString());
  }

  /// Opens the phone dialer pre-filled with the USSD code.
  Future<bool> dialMpesaUssd(int amountFc) async {
    final code = getMpesaUssdCode(amountFc);
    // Encode '#' as %23 for tel: URIs
    final encoded = code.replaceAll('#', '%23');
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  // ── Airtel / Orange / Africell ────────────────────────────────────────────

  String getUssdCode(PaymentMethod method, int amountFc) {
    final merchant = AppConstants.mpesaMerchantNumber;
    switch (method) {
      case PaymentMethod.airtel:
        return '*185*2*1*$merchant*$amountFc#';
      case PaymentMethod.mpesa:
        return getMpesaUssdCode(amountFc);
      case PaymentMethod.orange:
        return '#144*1*$merchant*$amountFc#';
      case PaymentMethod.africell:
        return '*210*2*$merchant*$amountFc#';
      case PaymentMethod.paypal:
        return '';
    }
  }

  Future<bool> dialUssd(PaymentMethod method, int amountFc) async {
    final code = getUssdCode(method, amountFc);
    if (code.isEmpty) return false;
    final encoded = code.replaceAll('#', '%23');
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  // ── PayPal (International) ────────────────────────────────────────────────

  /// Opens the PayPal.me page with the amount pre-filled (USD).
  Future<bool> openPayPal({required double amountUsd}) async {
    final amount = amountUsd.toStringAsFixed(2);
    final url = Uri.parse('${AppConstants.paypalMeLink}/$amount');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ── Payment initiation (Mobile Money — DRC) ────────────────────────────────

  Future<PaymentResult> initiatePayment({
    required PaymentMethod method,
    required SubscriptionType plan,
    required String phoneNumber,
  }) async {
    final amountFc = plan == SubscriptionType.daily
        ? AppConstants.dailyPriceFc
        : AppConstants.monthlyPriceFc;

    // Trigger USSD on device
    await dialUssd(method, amountFc);

    // Payment confirmation is manual: user dials and confirms on their phone.
    // We return a "pending" state — the PaymentScreen will show instructions
    // and a "Confirmer le paiement" button that activates the subscription.
    return PaymentResult(
      isSuccess: false,
      isPending: true,
      transactionCode: null,
      message: 'Composez le code USSD sur votre téléphone, confirmez avec votre PIN, '
          'puis appuyez sur "Confirmer le paiement" ci-dessous.',
      amountFc: amountFc,
    );
  }

  /// Called when the user confirms they have completed the mobile money payment.
  Future<PaymentResult> confirmMobileMoneyPayment({
    required SubscriptionType plan,
    required int amountFc,
  }) async {
    await _activateSubscription(plan);
    final code = 'MM${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      isSuccess: true,
      isPending: false,
      transactionCode: code,
      message: 'Abonnement activé ! Profitez d\'OmniFlix.',
      amountFc: amountFc,
    );
  }

  /// Called after the user returns from PayPal checkout.
  Future<PaymentResult> confirmPayPalPayment({
    required SubscriptionType plan,
    required double amountUsd,
  }) async {
    await _activateSubscription(plan);
    final code = 'PP${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      isSuccess: true,
      isPending: false,
      transactionCode: code,
      message: 'Paiement PayPal confirmé ! Abonnement activé.',
      amountFc: usdToFc(amountUsd),
    );
  }

  // ── PPV Events ─────────────────────────────────────────────────────────────

  Future<PaymentResult> payForEvent({
    required String eventId,
    required int priceFc,
    required PaymentMethod method,
    required String phoneNumber,
  }) async {
    if (method == PaymentMethod.paypal) {
      final usd = priceFc / 2850;
      await openPayPal(amountUsd: usd);
      return PaymentResult(
        isSuccess: false,
        isPending: true,
        message: 'Complétez le paiement PayPal, puis confirmez ici.',
        amountFc: priceFc,
      );
    }

    await dialUssd(method, priceFc);
    return PaymentResult(
      isSuccess: false,
      isPending: true,
      message: 'Composez le code USSD, confirmez avec votre PIN, puis revenez ici.',
      amountFc: priceFc,
    );
  }

  Future<void> confirmEventAccess(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList('purchased_events') ?? [];
    if (!purchased.contains(eventId)) {
      purchased.add(eventId);
      await prefs.setStringList('purchased_events', purchased);
    }
  }

  Future<bool> hasAccessToEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('purchased_events') ?? []).contains(eventId);
  }
}

class PaymentResult {
  final bool isSuccess;
  final bool isPending;
  final String message;
  final String? transactionCode;
  final int amountFc;

  const PaymentResult({
    required this.isSuccess,
    required this.isPending,
    required this.message,
    this.transactionCode,
    required this.amountFc,
  });
}
