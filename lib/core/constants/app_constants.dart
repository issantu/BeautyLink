class AppConstants {
  static const String appName = 'OmniFlix';
  static const String appTagline = 'Films • TV Direct • Jeux Vidéo';

  // ── Pricing RDC (Franc Congolais) ─────────────────────────────────────────
  static const int dailyPriceFc = 3000;
  static const int monthlyPriceFc = 46000;
  static const String currency = 'FC';
  static const String currencyName = 'Franc Congolais';

  // ── Pricing International (USD / EUR) ─────────────────────────────────────
  static const double dailyPriceUsd = 1.99;
  static const double monthlyPriceUsd = 14.99;
  static const double dailyPriceEur = 1.89;
  static const double monthlyPriceEur = 13.99;

  // ── M-Pesa RDC — compte marchand dédié OmniFlix ───────────────────────────
  // Numéro Vodacom DRC : +243-839495208
  static const String mpesaMerchantNumber = '839495208';
  static const String mpesaMerchantFull   = '+243839495208';
  // Code USSD Vodacom DRC pour paiement marchand : *150*1*[montant]*[marchand]#
  static const String mpesaUssdTemplate   = '*150*1*{amount}*839495208#';

  // ── PayPal — international ─────────────────────────────────────────────────
  // Remplacer par le lien PayPal.me réel après création du compte PayPal Business
  static const String paypalMeLink        = 'https://www.paypal.me/omniflixapp';
  static const String paypalBusinessEmail = 'payments@omniflix.app'; // placeholder

  // Savings percentage
  static const double monthlySavings = 0.49; // ~49% cheaper vs daily

  // Mobile Money Providers
  static const List<Map<String, String>> mobileMoneyProviders = [
    {
      'id': 'airtel',
      'name': 'Airtel Money',
      'icon': 'airtel',
      'ussd': '*185#',
      'color': '#E60000',
    },
    {
      'id': 'mpesa',
      'name': 'M-Pesa (Vodacom)',
      'icon': 'mpesa',
      'ussd': '*111#',
      'color': '#00A651',
    },
    {
      'id': 'orange',
      'name': 'Orange Money',
      'icon': 'orange',
      'ussd': '#144#',
      'color': '#FF6600',
    },
    {
      'id': 'africell',
      'name': 'Africell Money',
      'icon': 'africell',
      'ussd': '*210#',
      'color': '#0066CC',
    },
  ];

  // TV Categories (prioritized)
  static const List<Map<String, dynamic>> tvCategories = [
    {'id': 'sports', 'name': 'Sport', 'icon': '⚽', 'priority': 1},
    {'id': 'combat', 'name': 'Combat', 'icon': '🥊', 'priority': 2},
    {'id': 'music', 'name': 'Musique', 'icon': '🎵', 'priority': 3},
    {'id': 'movies', 'name': 'Films/Séries', 'icon': '🎬', 'priority': 4},
    {'id': 'news', 'name': 'Info', 'icon': '📰', 'priority': 5},
    {'id': 'general', 'name': 'Généraliste', 'icon': '📺', 'priority': 6},
  ];

  // Movie Categories
  static const List<Map<String, dynamic>> movieOrigins = [
    {'id': 'hollywood', 'name': 'Hollywood', 'flag': '🇺🇸'},
    {'id': 'nollywood', 'name': 'Nollywood', 'flag': '🇳🇬'},
    {'id': 'bollywood', 'name': 'Bollywood', 'flag': '🇮🇳'},
    {'id': 'french', 'name': 'Cinéma Français', 'flag': '🇫🇷'},
    {'id': 'african', 'name': 'Cinéma Africain', 'flag': '🌍'},
  ];

  // PPV Event Source Types
  static const List<String> eventSourceTypes = [
    'youtube',
    'web',
    'local_file',
    'm3u',
    'mp4',
    'hls',
    'rtmp',
  ];

  // Subscription Plans
  static const List<Map<String, dynamic>> subscriptionPlans = [
    {
      'id': 'daily',
      'name': 'Pass Journée',
      'price': dailyPriceFc,
      'duration': '1 jour',
      'durationDays': 1,
      'badge': null,
    },
    {
      'id': 'monthly',
      'name': 'Abonnement Mensuel',
      'price': monthlyPriceFc,
      'duration': '1 mois',
      'durationDays': 30,
      'badge': 'Meilleur Prix',
    },
  ];
}
