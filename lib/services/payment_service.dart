import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/api_constants.dart';

final paymentServiceProvider = Provider<PaymentService>((_) => PaymentService());

class PaymentService {
  static const String _subscriptionKey = 'omniflix_subscription_type';
  static const String _expiryKey       = 'omniflix_expiry_date';
  static const String _pendingSessionKey = 'omniflix_pending_stripe_session';
  static const String _pendingKindKey    = 'omniflix_pending_stripe_kind';
  static const String _pendingPlanKey    = 'omniflix_pending_stripe_plan';
  static const String _pendingEventKey   = 'omniflix_pending_stripe_event';

  // ── Region helpers ──────────────────────────────────────────────────────────

  /// Derives FC equivalent of a USD price at the current indicative rate.
  static int usdToFc(double usd) => (usd * 2850).round();

  String formatUsd(double amount) => '\$${amount.toStringAsFixed(2)}';
  String formatEur(double amount) => '€${amount.toStringAsFixed(2)}';

  // ── Subscription management (local, shared_preferences) ───────────────────

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

  // ═══════════════════════════════════════════════════════════════════════════
  // RDC — Mobile Money (paiement en Franc Congolais via composeur USSD)
  // Flux 100 % client, pas de backend. Inchangé.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vodacom DRC USSD : *150*1*[montant]*[marchand]#
  String getMpesaUssdCode(int amountFc) {
    return AppConstants.mpesaUssdTemplate
        .replaceFirst('{amount}', amountFc.toString());
  }

  Future<bool> dialMpesaUssd(int amountFc) async {
    final code = getMpesaUssdCode(amountFc);
    final encoded = code.replaceAll('#', '%23');
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

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
      case PaymentMethod.stripe:
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

  Future<PaymentResult> initiatePayment({
    required PaymentMethod method,
    required SubscriptionType plan,
    required String phoneNumber,
  }) async {
    final amountFc = plan == SubscriptionType.daily
        ? AppConstants.dailyPriceFc
        : AppConstants.monthlyPriceFc;
    await dialUssd(method, amountFc);
    return PaymentResult(
      isSuccess: false,
      isPending: true,
      transactionCode: null,
      message: 'Composez le code USSD sur votre téléphone, confirmez avec votre PIN, '
          'puis appuyez sur "Confirmer le paiement" ci-dessous.',
      amountFc: amountFc,
    );
  }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // International — Stripe Checkout (carte bancaire, USD)
  // Passe par le backend OmniFlix qui crée la session Stripe.
  // ═══════════════════════════════════════════════════════════════════════════

  Uri get _backendUri => Uri.parse(ApiConstants.backendBaseUrl);

  /// Demande au backend de créer une Checkout Session pour l'abonnement.
  /// Retourne l'URL Stripe à ouvrir dans le navigateur externe et le session_id.
  Future<StripeCheckout?> createStripeCheckout({
    required SubscriptionType plan,
  }) async {
    final packageId = plan == SubscriptionType.daily ? 'daily_sub' : 'monthly_sub';
    return _createCheckout(body: {
      'package_id': packageId,
      'origin_url': ApiConstants.backendBaseUrl,
    }, pending: {
      'kind': 'subscription',
      'plan': plan.name,
    });
  }

  /// Demande au backend de créer une Checkout Session pour un événement PPV.
  Future<StripeCheckout?> createStripePpvCheckout({required String eventId}) async {
    return _createCheckout(body: {
      'ppv_event_id': eventId,
      'origin_url': ApiConstants.backendBaseUrl,
    }, pending: {
      'kind': 'ppv',
      'event_id': eventId,
    });
  }

  Future<StripeCheckout?> _createCheckout({
    required Map<String, String> body,
    required Map<String, String> pending,
  }) async {
    try {
      final url = _backendUri.replace(path: '/api/stripe/checkout');
      final r = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return null;
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final sessionId = json['session_id'] as String;
      final checkoutUrl = json['url'] as String;
      final amount = (json['amount'] as num).toDouble();

      // Remember what's being paid so we can confirm on return
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingSessionKey, sessionId);
      await prefs.setString(_pendingKindKey, pending['kind']!);
      if (pending['plan'] != null) await prefs.setString(_pendingPlanKey, pending['plan']!);
      if (pending['event_id'] != null) await prefs.setString(_pendingEventKey, pending['event_id']!);

      return StripeCheckout(sessionId: sessionId, url: checkoutUrl, amountUsd: amount);
    } catch (_) {
      return null;
    }
  }

  /// Ouvre l'URL de checkout Stripe dans le navigateur externe de l'appareil.
  Future<bool> openStripeCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Appelé après le retour de l'utilisateur depuis Stripe. Interroge le
  /// backend pour vérifier que le paiement est "paid", puis active localement
  /// l'abonnement / l'accès PPV.
  Future<PaymentResult> confirmStripePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_pendingSessionKey);
    final kind = prefs.getString(_pendingKindKey);
    if (sessionId == null || kind == null) {
      return const PaymentResult(
        isSuccess: false,
        isPending: false,
        message: 'Aucun paiement Stripe en attente.',
        amountFc: 0,
      );
    }

    // Poll up to 5 times over ~10s to allow Stripe to settle
    Map<String, dynamic>? status;
    for (var attempt = 0; attempt < 5; attempt++) {
      status = await _fetchStripeStatus(sessionId);
      if (status != null && status['payment_status'] == 'paid') break;
      if (status != null && status['status'] == 'expired') break;
      await Future.delayed(const Duration(seconds: 2));
    }

    if (status == null) {
      return const PaymentResult(
        isSuccess: false, isPending: false,
        message: 'Impossible de vérifier le paiement. Vérifiez votre connexion.',
        amountFc: 0,
      );
    }

    if (status['payment_status'] != 'paid') {
      return PaymentResult(
        isSuccess: false, isPending: false,
        message: status['status'] == 'expired'
            ? 'Session Stripe expirée. Relancez le paiement.'
            : 'Paiement non encore confirmé. Réessayez dans quelques secondes.',
        amountFc: 0,
      );
    }

    // Payment confirmed — activate
    final cents = (status['amount_total'] as num).toInt();
    final amountUsd = cents / 100;
    final amountFc = usdToFc(amountUsd);

    if (kind == 'subscription') {
      final planName = prefs.getString(_pendingPlanKey);
      final plan = SubscriptionType.values.firstWhere(
        (e) => e.name == planName,
        orElse: () => SubscriptionType.monthly,
      );
      await _activateSubscription(plan);
    } else if (kind == 'ppv') {
      final eventId = prefs.getString(_pendingEventKey);
      if (eventId != null) await confirmEventAccess(eventId);
    }

    // Cleanup
    await prefs.remove(_pendingSessionKey);
    await prefs.remove(_pendingKindKey);
    await prefs.remove(_pendingPlanKey);
    await prefs.remove(_pendingEventKey);

    return PaymentResult(
      isSuccess: true,
      isPending: false,
      transactionCode: 'SP$sessionId',
      message: 'Paiement Stripe confirmé ! Accès activé.',
      amountFc: amountFc,
    );
  }

  Future<Map<String, dynamic>?> _fetchStripeStatus(String sessionId) async {
    try {
      final url = _backendUri.replace(path: '/api/stripe/status/$sessionId');
      final r = await http.get(url).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── PPV Events ─────────────────────────────────────────────────────────────

  Future<PaymentResult> payForEvent({
    required String eventId,
    required int priceFc,
    required PaymentMethod method,
    required String phoneNumber,
  }) async {
    if (method == PaymentMethod.stripe) {
      final checkout = await createStripePpvCheckout(eventId: eventId);
      if (checkout == null) {
        return PaymentResult(
          isSuccess: false, isPending: false,
          message: 'Erreur lors de la création de la session Stripe.',
          amountFc: priceFc,
        );
      }
      await openStripeCheckout(checkout.url);
      return PaymentResult(
        isSuccess: false,
        isPending: true,
        message: 'Complétez le paiement Stripe, puis confirmez ici.',
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

class StripeCheckout {
  final String sessionId;
  final String url;
  final double amountUsd;

  const StripeCheckout({
    required this.sessionId,
    required this.url,
    required this.amountUsd,
  });
}
