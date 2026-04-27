class AppConstants {
  static const String appName = 'OmniFlix';
  static const String appTagline = 'Films • TV Direct • Jeux Vidéo';

  // Pricing in Franc Congolais (FC)
  static const int dailyPriceFc = 3000;
  static const int monthlyPriceFc = 46000;
  static const String currency = 'FC';
  static const String currencyName = 'Franc Congolais';

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
