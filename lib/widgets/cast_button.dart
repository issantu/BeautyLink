import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../services/cast_service.dart';

/// A cast button that discovers Chromecast devices and lets the user
/// select one to stream [mediaUrl] to.
///
/// Usage (in any widget tree that has a ProviderScope ancestor):
/// ```dart
/// CastButton(
///   mediaUrl: 'https://example.com/stream.m3u8',
///   mediaTitle: 'Canal+ Sport',
///   mediaThumbnail: 'https://example.com/logo.jpg',
/// )
/// ```
class CastButton extends ConsumerWidget {
  final String mediaUrl;
  final String mediaTitle;
  final String? mediaThumbnail;
  final Color? iconColor;

  const CastButton({
    super.key,
    required this.mediaUrl,
    required this.mediaTitle,
    this.mediaThumbnail,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final castService = ref.watch(castServiceProvider);
    final connected = castService.isConnected;

    return IconButton(
      tooltip: connected ? 'Casting actif — Appuyer pour gérer' : 'Diffuser sur TV',
      icon: Icon(
        connected ? Icons.cast_connected_rounded : Icons.cast_rounded,
        size: 22,
        color: connected ? AppColors.live : (iconColor ?? AppColors.textSecondary),
      ),
      onPressed: () => _showCastDialog(context, castService),
    );
  }

  Future<void> _showCastDialog(BuildContext context, CastService castService) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CastSheet(
        castService: castService,
        mediaUrl: mediaUrl,
        mediaTitle: mediaTitle,
        mediaThumbnail: mediaThumbnail,
      ),
    );
  }
}

class _CastSheet extends StatefulWidget {
  final CastService castService;
  final String mediaUrl;
  final String mediaTitle;
  final String? mediaThumbnail;

  const _CastSheet({
    required this.castService,
    required this.mediaUrl,
    required this.mediaTitle,
    this.mediaThumbnail,
  });

  @override
  State<_CastSheet> createState() => _CastSheetState();
}

class _CastSheetState extends State<_CastSheet> {
  List<CastDevice> _devices = [];
  bool _scanning = true;
  CastDevice? _connecting;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() { _scanning = true; _devices = []; });
    final found = await widget.castService.discoverDevices();
    if (mounted) setState(() { _scanning = false; _devices = found; });
  }

  Future<void> _connect(CastDevice device) async {
    setState(() => _connecting = device);
    final ok = await widget.castService.connectTo(device);
    if (!ok || !mounted) {
      setState(() => _connecting = null);
      return;
    }
    await widget.castService.castMedia(
      url: widget.mediaUrl,
      title: widget.mediaTitle,
      imageUrl: widget.mediaThumbnail,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _stopCasting() async {
    widget.castService.stopCast();
    await widget.castService.disconnect();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.castService.isConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.cast_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text('Diffuser sur TV / Projecteur',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (!_scanning)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: _scan,
                  tooltip: 'Relancer la recherche',
                ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            widget.mediaTitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Connected state
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.live.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.live.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cast_connected_rounded,
                      color: AppColors.live, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Casting en cours…',
                        style: TextStyle(
                            color: AppColors.live, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: _stopCasting,
                    child: const Text('Arrêter',
                        style: TextStyle(color: AppColors.secondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scanning / device list
          if (_scanning) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                    ),
                    SizedBox(height: 12),
                    Text('Recherche d\'appareils Cast…',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ] else if (_devices.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cast_rounded, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text('Aucun appareil trouvé',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text(
                      'Assurez-vous d\'être sur le même WiFi\nque votre Chromecast / Google TV',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...(_devices.map((device) {
              final isConnecting = _connecting == device;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tv_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: Text(device.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                subtitle: const Text('Chromecast / Google TV',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                trailing: isConnecting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                      )
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                onTap: isConnecting ? null : () => _connect(device),
              );
            })),
          ],
        ],
      ),
    );
  }
}
