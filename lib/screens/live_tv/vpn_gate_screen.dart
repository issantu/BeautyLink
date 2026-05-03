import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/vpn_service.dart';
import 'vavoo_screen.dart';

class VpnGateScreen extends StatefulWidget {
  const VpnGateScreen({super.key});

  @override
  State<VpnGateScreen> createState() => _VpnGateScreenState();
}

class _VpnGateScreenState extends State<VpnGateScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _vpnActive = false;
  bool _downloading = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVpn();
    // Auto-check every 3 seconds while screen is open
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVpn(),
    );
  }

  // Re-check when user returns to the app (after installing/activating Lokke)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVpn();
    }
  }

  Future<void> _checkVpn() async {
    final active = await VpnService.isVpnActive();
    if (!mounted) return;
    setState(() {
      _vpnActive = active;
      _checking = false;
    });

    // Auto-enter vavoo.to when VPN detected
    if (active) {
      _checkTimer?.cancel();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _enterVavoo();
    }
  }

  void _enterVavoo() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const VavooScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _downloadLokke() async {
    setState(() => _downloading = true);

    final playStore = Uri.parse(VpnService.lokkePlayStore);
    final website = Uri.parse(VpnService.lokkeWebsite);

    if (await canLaunchUrl(playStore)) {
      await launchUrl(playStore, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(website, mode: LaunchMode.externalApplication);
    }

    setState(() => _downloading = false);
  }

  Future<void> _downloadApk() async {
    final apk = Uri.parse(VpnService.lokkeApkDirect);
    if (await canLaunchUrl(apk)) {
      await launchUrl(apk, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _checking
            ? const _CheckingState()
            : _vpnActive
                ? const _VpnConnectedState()
                : _VpnRequiredState(
                    onDownload: _downloadLokke,
                    onDownloadApk: _downloadApk,
                    onRetry: _checkVpn,
                    downloading: _downloading,
                  ),
      ),
    );
  }
}

// ---- States ----

class _CheckingState extends StatelessWidget {
  const _CheckingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Vérification VPN...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _VpnConnectedState extends StatelessWidget {
  const _VpnConnectedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.live.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.live, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.vpn_lock_rounded,
                  color: AppColors.live, size: 44),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'VPN Actif ✓',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.live,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connexion sécurisée — Chargement...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.live),
            ),
          ),
        ],
      ),
    );
  }
}

class _VpnRequiredState extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onDownloadApk;
  final VoidCallback onRetry;
  final bool downloading;

  const _VpnRequiredState({
    required this.onDownload,
    required this.onDownloadApk,
    required this.onRetry,
    required this.downloading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Shield icon
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B09B).withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.security_rounded, color: Colors.white, size: 54),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'VPN Requis',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'La TV en Direct nécessite un VPN actif\npour accéder à toutes les chaînes.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Lokke card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00B09B).withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokke VPN Browser',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '✓ Gratuit  •  ✓ Sans inscription  •  ✓ Rapide',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.bgCardLight),
                const SizedBox(height: 12),

                // Benefits
                _Benefit(icon: '🌍', text: 'Accès à toutes les chaînes mondiales'),
                _Benefit(icon: '🚫', text: 'Bloque publicités automatiquement'),
                _Benefit(icon: '🛡️', text: 'Anonymise votre connexion'),
                _Benefit(icon: '⚡', text: 'Streaming rapide et stable'),

                const SizedBox(height: 18),

                // Primary download button (Play Store)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: downloading ? null : onDownload,
                    icon: downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 22),
                    label: const Text(
                      'Télécharger Lokke (Play Store)',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B09B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // APK direct download (fallback)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onDownloadApk,
                    icon: const Icon(Icons.install_mobile_rounded,
                        size: 18, color: AppColors.textSecondary),
                    label: const Text(
                      'Télécharger APK direct',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.bgCardLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Steps after download
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Après installation :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _Step(num: '1', text: 'Ouvrez Lokke sur votre téléphone'),
                _Step(num: '2', text: 'Appuyez sur "Connecter"'),
                _Step(
                    num: '3',
                    text: 'Revenez sur OmniFlix — accès automatique !'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Retry button
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 18),
            label: const Text(
              'Vérifier à nouveau',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'OmniFlix détecte automatiquement\nquand Lokke est activé.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
