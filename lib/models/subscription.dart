enum SubscriptionType { none, daily, monthly }

enum PaymentMethod { airtel, mpesa, orange, africell }

class Subscription {
  final SubscriptionType type;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool isActive;

  const Subscription({
    required this.type,
    this.startDate,
    this.expiryDate,
    this.isActive = false,
  });

  const Subscription.none()
      : type = SubscriptionType.none,
        startDate = null,
        expiryDate = null,
        isActive = false;

  bool get isExpired {
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate!);
  }

  String get statusLabel {
    if (!isActive || isExpired) return 'Inactif';
    return type == SubscriptionType.daily ? 'Pass Journée' : 'Mensuel';
  }

  String get expiryLabel {
    if (expiryDate == null) return 'Aucun';
    final diff = expiryDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Expiré';
    if (diff.inHours < 24) return 'Expire dans ${diff.inHours}h';
    return 'Expire le ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }
}

class PaymentTransaction {
  final String id;
  final PaymentMethod method;
  final int amountFc;
  final SubscriptionType subscriptionType;
  final DateTime timestamp;
  final bool isSuccessful;
  final String? phoneNumber;
  final String? transactionCode;

  const PaymentTransaction({
    required this.id,
    required this.method,
    required this.amountFc,
    required this.subscriptionType,
    required this.timestamp,
    required this.isSuccessful,
    this.phoneNumber,
    this.transactionCode,
  });

  String get methodName {
    switch (method) {
      case PaymentMethod.airtel:
        return 'Airtel Money';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.orange:
        return 'Orange Money';
      case PaymentMethod.africell:
        return 'Africell Money';
    }
  }
}
