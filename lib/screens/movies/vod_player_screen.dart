import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vod_entry.dart';
import '../../providers/movies_provider.dart';
import '../../services/iptv_service.dart';
import '../../widgets/cast_button.dart';

/// VOD player screen.
/// Pass [entry] to play a known VodEntry directly.
/// Pass [searchTitle] to search the IPTV library and play the best match.
class VodPlayerScreen extends ConsumerStatefulWidget {
  final VodEntry? entry;
  final String? searchTitle;

  const VodPlayerScreen({super.key, this.entry, this.searchTitle})
      : assert(entry != null || searchTitle != null,
            'Provide either entry or searchTitle');

  @override
  ConsumerState<VodPlayerScreen> createState() => _VodPlayerScreenState();
}

class _VodPlayerScreenState extends ConsumerState<VodPlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  VodEntry? _entry;
  bool _searching = false;
  bool _notFound = false;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _entry = widget.entry;
      _initPlayer();
    } else {
      _resolveAndPlay();
    }
  }

  Future<void> _resolveAndPlay() async {
    setState(() => _searching = true);
    try {
      final movies = await ref.read(iptvVodMoviesProvider.future);
      final found = IptvService.findMatch(movies, widget.searchTitle!);
      if (found == null) {
        if (mounted) setState(() { _searching = false; _notFound = true; });
        return;
      }
      _entry = found;
      if (mounted) setState(() => _searching = false);
      await _initPlayer();
    } catch (_) {
      if (mounted) setState(() { _searching = false; _notFound = true; });
    }
  }

  Future<void> _initPlayer() async {
    if (_entry == null) return;
    setState(() { _loading = true; _hasError = false; });
    try {
      _videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(_entry!.streamUrl),
        httpHeaders: const {'User-Agent': 'OmniFlix/1.0', 'Accept': '*/*'},
      );
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        allowPlaybackSpeedChanging: true,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        errorBuilder: (_, msg) => _ErrorView(message: msg, onRetry: _retry),
        placeholder: _buildPlaceholder(),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _retry() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    _chewieCtrl = null;
    _videoCtrl = null;
    _initPlayer();
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: _entry?.logo != null
            ? CachedNetworkImage(
                imageUrl: _entry!.logo!,
                height: 80,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.movie_rounded, size: 64, color: AppColors.textMuted),
              )
            : const Icon(Icons.movie_rounded, size: 64, color: AppColors.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Video player area ──────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerArea(),
            ),

            // ── Info bar ───────────────────────────────────────────────
            _InfoBar(
              entry: _entry,
              searchTitle: widget.searchTitle,
              onBack: () => Navigator.pop(context),
              onRetry: _retry,
            ),

            // ── Details ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_entry != null) ...[
                      if (_entry!.group.isNotEmpty)
                        Text(
                          _entry!.group,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 16),
                      // Cast button
                      CastButton(
                        mediaUrl: _entry!.streamUrl,
                        mediaTitle: _entry!.displayTitle,
                        mediaThumbnail: _entry!.logo,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.textMuted, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contenu de votre abonnement IPTV. '
                              'Qualité selon votre connexion.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_searching) {
      return Container(
        color: Colors.black,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
            SizedBox(height: 12),
            Text('Recherche du flux…',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    if (_notFound) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              '"${widget.searchTitle}" non disponible',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ce titre n\'est pas dans votre abonnement IPTV',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_loading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
              ),
              SizedBox(height: 12),
              Text('Connexion au flux…',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_bad_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Flux indisponible',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Ce flux n\'est pas disponible pour le moment',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_chewieCtrl != null) return Chewie(controller: _chewieCtrl!);
    return const SizedBox.shrink();
  }
}

class _InfoBar extends StatelessWidget {
  final VodEntry? entry;
  final String? searchTitle;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _InfoBar({
    required this.entry,
    required this.searchTitle,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry?.displayTitle ?? searchTitle ?? '';
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: onBack,
          ),
          if (entry?.logo != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CachedNetworkImage(
                imageUrl: entry!.logo!,
                height: 32,
                width: 48,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry?.isSeries == true ? 'SÉRIE IPTV' : 'FILM IPTV',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: onRetry,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.secondary, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
