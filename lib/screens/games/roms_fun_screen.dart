import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/theme/app_theme.dart';

class RomsFunScreen extends StatefulWidget {
  final String? gameName;
  final String? consoleSlug;
  final String? consoleLabel;

  const RomsFunScreen({
    super.key,
    this.gameName,
    this.consoleSlug,
    this.consoleLabel,
  });

  @override
  State<RomsFunScreen> createState() => _RomsFunScreenState();
}

class _RomsFunScreenState extends State<RomsFunScreen> {
  InAppWebViewController? _webController;
  double _progress = 0;
  bool _canGoBack = false;
  String _pageTitle = '';

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // Ad/tracking domains to block
  static const _blockedDomains = [
    'doubleclick.net', 'googlesyndication.com', 'adnxs.com',
    'amazon-adsystem.com', 'outbrain.com', 'taboola.com',
    'popads.net', 'popcash.net', 'propellerads.com', 'trafficjunky.net',
    'exosrv.com', 'juicyads.com', 'plugrush.com', 'clickadu.com',
    'revcontent.com', 'mgid.com', 'adsterra.com', 'hilltopads.net',
  ];

  // Dark CSS injected into every page
  static const _darkCss = '''
    (function() {
      var style = document.createElement('style');
      style.innerHTML = `
        body, html { background-color: #0A0E1A !important; color: #E0E6FF !important; }
        header, nav, .header, .navbar, .nav-bar, .site-header {
          background-color: #141928 !important;
          border-bottom: 1px solid #1E2640 !important;
        }
        .card, .game-card, .item, .post, article, .entry {
          background-color: #141928 !important;
          border-color: #1E2640 !important;
        }
        a { color: #9E7BFF !important; }
        input, select, textarea {
          background-color: #1E2640 !important;
          color: #E0E6FF !important;
          border-color: #2D3558 !important;
        }
        .sidebar, aside { background-color: #141928 !important; }
        footer { background-color: #0A0E1A !important; }
        /* hide cookie banners and popups */
        .cookie-banner, .gdpr, .consent-popup, [class*="cookie"],
        [class*="popup"], [id*="popup"], .modal-overlay,
        [class*="advert"], [class*="banner-ad"], [id*="banner-ad"] {
          display: none !important;
        }
      `;
      document.head.appendChild(style);
    })();
  ''';

  // Remove ad elements after page load
  static const _adRemover = '''
    (function() {
      var selectors = [
        'iframe[src*="ad"]', 'ins.adsbygoogle', '[id*="google_ads"]',
        '[class*="advertisement"]', '[class*="ads-"]', '[id*="ads-"]',
        'div[data-ad]', '.sponsored', '.promo-banner',
      ];
      selectors.forEach(function(s) {
        document.querySelectorAll(s).forEach(function(el) { el.remove(); });
      });
    })();
  ''';

  String get _initialUrl {
    if (widget.gameName != null && widget.gameName!.isNotEmpty) {
      final q = Uri.encodeQueryComponent(widget.gameName!);
      return 'https://romsfun.com/?s=$q';
    }
    if (widget.consoleSlug != null) {
      return 'https://romsfun.com/roms/${widget.consoleSlug}/';
    }
    return 'https://romsfun.com/roms/';
  }

  String get _screenTitle {
    if (widget.gameName != null) return widget.gameName!;
    if (widget.consoleLabel != null) return widget.consoleLabel!;
    return 'Télécharger ROMs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () async {
            if (_canGoBack && _webController != null) {
              await _webController!.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _screenTitle,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_pageTitle.isNotEmpty)
              Text(
                _pageTitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Download icon badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.download_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('ROMs', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textMuted, size: 20),
            onPressed: () => _webController?.reload(),
          ),
        ],
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.bgCardLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
        initialSettings: InAppWebViewSettings(
          userAgent: _userAgent,
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          transparentBackground: true,
          supportZoom: false,
          disableHorizontalScroll: false,
          verticalScrollBarEnabled: false,
        ),
        onWebViewCreated: (controller) => _webController = controller,
        onLoadStart: (controller, url) {
          setState(() => _progress = 0.1);
        },
        onProgressChanged: (controller, progress) {
          setState(() => _progress = progress / 100.0);
        },
        onLoadStop: (controller, url) async {
          setState(() => _progress = 1.0);
          final canBack = await controller.canGoBack();
          setState(() => _canGoBack = canBack);
          // Inject dark theme + ad remover
          await controller.evaluateJavascript(source: _darkCss);
          await Future.delayed(const Duration(milliseconds: 500));
          await controller.evaluateJavascript(source: _adRemover);
        },
        onTitleChanged: (controller, title) {
          if (title != null && title.isNotEmpty) {
            setState(() => _pageTitle = title.replaceAll(' - RomsFun', '').trim());
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url?.toString() ?? '';
          for (final domain in _blockedDomains) {
            if (url.contains(domain)) {
              return NavigationActionPolicy.CANCEL;
            }
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
