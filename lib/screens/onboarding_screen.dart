import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _lokkeInstalled = false;

  final _pages = const [
    _OnboardingPage(
      emoji: '🎬',
      title: 'Bienvenue sur OmniFlix',
      subtitle: 'Films • TV Direct • Jeux Vidéo\nTout en un seul endroit',
      description:
          'Accédez à des milliers de chaînes TV, films en français, '
          'séries et jeux vidéo depuis votre téléphone.',
      isLokke: false,
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: 'Installez Lokke VPN',
      subtitle: 'Indispensable pour la TV',
      description:
          'Lokke VPN débloque toutes les chaînes TV du monde entier, '
          'contourne les restrictions géographiques et protège '
          'votre connexion. Gratuit et facile à utiliser.',
      isLokke: true,
    ),
    _OnboardingPage(
      emoji: '📺',
      title: 'Activez Lokke avant de regarder',
      subtitle: 'Un seul geste suffit',
      description:
          '1. Ouvrez Lokke sur votre téléphone\n'
          '2. Appuyez sur "Connecter"\n'
          '3. Revenez sur OmniFlix et profitez !',
      isLokke: false,
    ),
    _OnboardingPage(
      emoji: '🚀',
      title: 'Vous êtes prêt !',
      subtitle: 'Abonnez-vous et commencez',
      description:
          'Pass Journée à 3 000 FC ou Abonnement Mensuel à 46 000 FC. '
          'Payez via Mobile Money (Airtel, M-Pesa, Orange, Africell).',
      isLokke: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(
                  page: _pages[i],
                  onDownloadLokke: _downloadLokke,
                  lokkeInstalled: _lokkeInstalled,
                ),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primary
                        : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _currentPage == _pages.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _finish,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '🎬  Commencer à regarder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage == 1 && !_lokkeInstalled
                              ? '📥  Télécharger Lokke'
                              : 'Suivant  →',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 1 && !_lokkeInstalled) {
      _downloadLokke();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _downloadLokke() async {
    // Try Play Store first, fallback to APKPure
    final playStoreUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.lokke.android',
    );
    final apkUrl = Uri.parse('https://lokke.app/download');

    if (await canLaunchUrl(playStoreUrl)) {
      await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(apkUrl, mode: LaunchMode.externalApplication);
    }

    // After returning from Play Store, mark as installed
    setState(() => _lokkeInstalled = true);

    // Move to next page automatically after download
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final bool isLokke;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isLokke,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final VoidCallback onDownloadLokke;
  final bool lokkeInstalled;

  const _PageContent({
    required this.page,
    required this.onDownloadLokke,
    required this.lokkeInstalled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji / Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: page.isLokke
                  ? const LinearGradient(
                      colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),

          // Lokke special card
          if (page.isLokke) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B09B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00B09B).withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🔒', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokke VPN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Gratuit • Android & iOS',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (lokkeInstalled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.live.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✓ Installé',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.live,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.bgCardLight),
                  const SizedBox(height: 8),
                  _LokkeFeature(
                      icon: '🌍', text: 'Accès à toutes les chaînes mondiales'),
                  _LokkeFeature(icon: '🚫', text: 'Bloque publicités et trackers'),
                  _LokkeFeature(
                      icon: '⚡', text: 'Connexion rapide et stable'),
                  _LokkeFeature(icon: '🆓', text: 'Gratuit, sans inscription'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LokkeFeature extends StatelessWidget {
  final String icon;
  final String text;

  const _LokkeFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
