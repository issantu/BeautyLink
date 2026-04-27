import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../core/constants/app_constants.dart';

class PaymentService {
  static const String _subscriptionKey = 'omniflix_subscription_type';
  static const String _expiryKey = 'omniflix_expiry_date';

  // Load current subscription from local storage
  Future<Subscription> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_subscriptionKey);
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

  // Initiate mobile money payment
  Future<PaymentResult> initiatePayment({
    required PaymentMethod method,
    required SubscriptionType plan,
    required String phoneNumber,
  }) async {
    // In production, this connects to mobile money APIs:
    // - Airtel Money API
    // - Vodacom M-Pesa API
    // - Orange Money API
    // - Africell Money API
    // For now, simulates a push payment request

    final amount = plan == SubscriptionType.daily
        ? AppConstants.dailyPriceFc
        : AppConstants.monthlyPriceFc;

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    // Simulate successful payment (90% success rate in demo)
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      await _activateSubscription(plan);
      return PaymentResult(
        isSuccess: true,
        transactionCode: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        message: 'Paiement réussi! Votre ${plan == SubscriptionType.daily ? 'pass journée' : 'abonnement mensuel'} est activé.',
        amountFc: amount,
      );
    } else {
      return PaymentResult(
        isSuccess: false,
        message: 'Paiement échoué. Vérifiez votre solde et réessayez.',
        amountFc: amount,
      );
    }
  }

  // Activate subscription after successful payment
  Future<void> _activateSubscription(SubscriptionType plan) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expiry = plan == SubscriptionType.daily
        ? now.add(const Duration(days: 1))
        : now.add(const Duration(days: 30));

    await prefs.setString(_subscriptionKey, plan.name);
    await prefs.setString(_expiryKey, expiry.toIso8601String());
  }

  // Check if user can watch content (has active subscription)
  Future<bool> hasActiveSubscription() async {
    final sub = await getCurrentSubscription();
    return sub.isActive && !sub.isExpired;
  }

  // Process PPV event payment
  Future<PaymentResult> payForEvent({
    required String eventId,
    required int priceFc,
    required PaymentMethod method,
    required String phoneNumber,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      final prefs = await SharedPreferences.getInstance();
      final purchasedEvents = prefs.getStringList('purchased_events') ?? [];
      if (!purchasedEvents.contains(eventId)) {
        purchasedEvents.add(eventId);
        await prefs.setStringList('purchased_events', purchasedEvents);
      }

      return PaymentResult(
        isSuccess: true,
        transactionCode: 'EVT${DateTime.now().millisecondsSinceEpoch}',
        message: 'Paiement réussi! Vous pouvez maintenant regarder l\'événement.',
        amountFc: priceFc,
      );
    } else {
      return PaymentResult(
        isSuccess: false,
        message: 'Paiement échoué. Vérifiez votre solde et réessayez.',
        amountFc: priceFc,
      );
    }
  }

  Future<bool> hasAccessToEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedEvents = prefs.getStringList('purchased_events') ?? [];
    return purchasedEvents.contains(eventId);
  }

  // Get USSD code for mobile money provider
  String getUssdCode(PaymentMethod method, int amount, String merchantCode) {
    switch (method) {
      case PaymentMethod.airtel:
        return '*185*2*1*$merchantCode*$amount#';
      case PaymentMethod.mpesa:
        return '*111*2*1*$merchantCode*$amount#';
      case PaymentMethod.orange:
        return '#144*1*$merchantCode*$amount#';
      case PaymentMethod.africell:
        return '*210*2*$merchantCode*$amount#';
    }
  }
}

class PaymentResult {
  final bool isSuccess;
  final String message;
  final String? transactionCode;
  final int amountFc;

  const PaymentResult({
    required this.isSuccess,
    required this.message,
    this.transactionCode,
    required this.amountFc,
  });
}
