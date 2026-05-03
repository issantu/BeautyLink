import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

// VPN state provider
final vpnActiveProvider = StateProvider<bool>((ref) => false);

class VavooScreen extends ConsumerStatefulWidget {
  const VavooScreen({super.key});

  @override
  ConsumerState<VavooScreen> createState() => _VavooScreenState();
}

class _VavooScreenState extends ConsumerState<VavooScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _canGoBack = false;
  double _progress = 0;
  String _currentUrl = 'https://vavoo.to';

  // Ad/tracker domains to block
  static const _blockedDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adnxs.com',
    'ads.yahoo.com',
    'amazon-adsystem.com',
    'advertising.com',
    'adsrvr.org',
    'rubiconproject.com',
    'pubmatic.com',
    'openx.net',
    'casalemedia.com',
    'criteo.com',
    'taboola.com',
    'outbrain.com',
    'smartadserver.com',
    'adform.net',
    'adsafeprotected.com',
    'moatads.com',
    'scorecardresearch.com',
    'quantserve.com',
    'chartbeat.com',
    'hotjar.com',
  ];

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    supportZoom: false,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    clearCache: false,
    userAgent:
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    transparentBackground: true,
    disableDefaultErrorPage: true,
    // Allow fullscreen for video
    allowsBackForwardNavigationGestures: true,
  );

  @override
  Widget build(BuildContext context) {
    final vpnActive = ref.watch(vpnActiveProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _TopBar(
              currentUrl: _currentUrl,
              canGoBack: _canGoBack,
              vpnActive: vpnActive,
              isLoading: _isLoading,
              progress: _progress,
              onBack: () => _webViewController?.goBack(),
              onRefresh: () => _webViewController?.reload(),
              onHome: () => _webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri('https://vavoo.to')),
              ),
              onToggleVpn: () => _toggleVpn(context),
              onSearch: (q) => _search(q),
            ),

            // VPN reminder banner (shown when VPN is off)
            if (!vpnActive) _VpnReminderBanner(onTap: () => _toggleVpn(context)),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://vavoo.to'),
                    ),
                    initialSettings: _settings,
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                        _currentUrl = url?.toString() ?? 'https://vavoo.to';
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() => _isLoading = false);
                      _canGoBack = await controller.canGoBack();
                      // Inject ad blocker script
                      await _injectAdBlocker(controller);
                      // Inject dark mode
                      await _injectDarkMode(controller);
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() => _progress = progress / 100.0);
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url?.toString() ?? '';
                      // Block ad domains
                      for (final domain in _blockedDomains) {
                        if (url.contains(domain)) {
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onEnterFullscreen: (controller) {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky);
                    },
                    onExitFullscreen: (controller) {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.edgeToEdge);
                    },
                    onReceivedError: (controller, request, error) {
                      if (error.type == WebResourceErrorType.NOT_CONNECTED_TO_INTERNET) {
                        _showNoInternet();
                      }
                    },
                  ),

                  // Progress bar
                  if (_isLoading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        minHeight: 2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _injectAdBlocker(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      (function() {
        // Remove ad elements
        var selectors = [
          '[class*="ad-"]', '[id*="ad-"]', '[class*="ads-"]',
          '[id*="ads-"]', '[class*="banner"]', '[class*="popup"]',
          'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
          '[class*="overlay"]', '[id*="overlay"]'
        ];
        selectors.forEach(function(sel) {
          document.querySelectorAll(sel).forEach(function(el) {
            if (el.tagName !== 'VIDEO' && el.tagName !== 'CANVAS') {
              el.style.display = 'none';
            }
          });
        });

        // Block popups
        window.open = function() { return null; };
        window.alert = function() {};
        window.confirm = function() { return true; };
      })();
    ''');
  }

  Future<void> _injectDarkMode(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = \`
          :root { color-scheme: dark; }
          body { background-color: #0A0E1A !important; }
          * { scrollbar-width: thin; scrollbar-color: #7C4DFF transparent; }
        \`;
        document.head.appendChild(style);
      })();
    ''');
  }

  void _search(String query) {
    final url = query.startsWith('http')
        ? query
        : 'https://vavoo.to/search?q=${Uri.encodeComponent(query)}';
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  void _toggleVpn(BuildContext context) {
    final isActive = ref.read(vpnActiveProvider);
    if (!isActive) {
      _showVpnOptions(context);
    } else {
      ref.read(vpnActiveProvider.notifier).state = false;
      _showSnack('VPN désactivé');
    }
  }

  void _showVpnOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VpnOptionsSheet(
        onActivate: (method) {
          Navigator.pop(context);
          _activateVpn(method);
        },
      ),
    );
  }

  void _activateVpn(String method) {
    ref.read(vpnActiveProvider.notifier).state = true;
    _showSnack('VPN activé — Connexion sécurisée');
    // Reload page with VPN active
    Future.delayed(const Duration(milliseconds: 500), () {
      _webViewController?.reload();
    });
  }

  void _showNoInternet() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Pas de connexion',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Vérifiez votre connexion internet et réessayez.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _webViewController?.reload();
            },
            child: const Text('Réessayer',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

// ---- Sub-widgets ----

class _TopBar extends StatefulWidget {
  final String currentUrl;
  final bool canGoBack;
  final bool vpnActive;
  final bool isLoading;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onHome;
  final VoidCallback onToggleVpn;
  final Function(String) onSearch;

  const _TopBar({
    required this.currentUrl,
    required this.canGoBack,
    required this.vpnActive,
    required this.isLoading,
    required this.progress,
    required this.onBack,
    required this.onRefresh,
    required this.onHome,
    required this.onToggleVpn,
    required this.onSearch,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              if (widget.canGoBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 18),
                  onPressed: widget.onBack,
                ),

              // Home logo
              GestureDetector(
                onTap: widget.onHome,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VAVOO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // URL bar / Search
              Expanded(
                child: _showSearch
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une chaîne...',
                          hintStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                            onPressed: () =>
                                setState(() => _showSearch = false),
                          ),
                        ),
                        onSubmitted: (q) {
                          widget.onSearch(q);
                          setState(() => _showSearch = false);
                        },
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _showSearch = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.bgCardLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_rounded,
                                  size: 11, color: AppColors.live),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'vavoo.to',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(width: 4),

              // VPN toggle
              GestureDetector(
                onTap: widget.onToggleVpn,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.vpnActive
                        ? AppColors.live.withOpacity(0.2)
                        : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.vpnActive
                          ? AppColors.live
                          : AppColors.bgCardLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.vpn_lock_rounded,
                        size: 14,
                        color: widget.vpnActive
                            ? AppColors.live
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.vpnActive ? 'ON' : 'VPN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.vpnActive
                              ? AppColors.live
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Refresh
              IconButton(
                icon: Icon(
                  widget.isLoading
                      ? Icons.close_rounded
                      : Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: widget.onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _VpnOptionsSheet extends StatelessWidget {
  final Function(String) onActivate;
  const _VpnOptionsSheet({required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activer le VPN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Le VPN débloque toutes les chaînes et protège votre connexion.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _VpnOption(
            icon: Icons.public_rounded,
            title: 'VPN Automatique',
            subtitle: 'Connexion optimale automatique',
            color: AppColors.live,
            onTap: () => onActivate('auto'),
          ),
          const SizedBox(height: 10),
          _VpnOption(
            icon: Icons.flag_rounded,
            title: 'Serveur Europe (France)',
            subtitle: 'Accès aux chaînes françaises',
            color: AppColors.primary,
            onTap: () => onActivate('europe'),
          ),
          const SizedBox(height: 10),
          _VpnOption(
            icon: Icons.language_rounded,
            title: 'Serveur Afrique',
            subtitle: 'Accès aux chaînes africaines',
            color: AppColors.ppv,
            onTap: () => onActivate('africa'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous pouvez aussi activer Lokke VPN sur votre téléphone '
                    'avant d\'ouvrir l\'app pour un bypass complet.',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _VpnReminderBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VpnReminderBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.12),
          border: Border(
            bottom: BorderSide(color: AppColors.gold.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Activez Lokke VPN pour débloquer toutes les chaînes',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.5)),
              ),
              child: const Text(
                'Activer',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VpnOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VpnOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
