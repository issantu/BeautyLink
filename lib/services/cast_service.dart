import 'dart:async';
import 'package:cast/cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final castServiceProvider = Provider<CastService>((_) => CastService());

/// Wraps the `cast` package (Google Cast SDK) for streaming media URLs
/// to Chromecast / Google TV devices on the local network.
///
/// Uses the "Default Media Receiver" (App ID: CC1AD845) — no developer
/// registration required, supports MP4, HLS, DASH, and WebM.
class CastService {
  static const _defaultReceiverAppId = 'CC1AD845';

  CastSession? _session;
  List<CastDevice> _devices = [];
  bool _isDiscovering = false;

  CastSession? get session => _session;
  bool get isConnected => _session?.state == CastSessionState.connected;
  List<CastDevice> get devices => List.unmodifiable(_devices);

  // ── Discovery ───────────────────────────────────────────────────────────────

  /// Scans for Cast devices on the local network for [duration].
  Future<List<CastDevice>> discoverDevices({
    Duration duration = const Duration(seconds: 4),
  }) async {
    if (_isDiscovering) return _devices;
    _isDiscovering = true;
    _devices = [];

    try {
      final service = CastDiscoveryService();
      _devices = await service.start(timeout: duration);
    } catch (_) {
      _devices = [];
    } finally {
      _isDiscovering = false;
    }
    return _devices;
  }

  // ── Session ─────────────────────────────────────────────────────────────────

  Future<bool> connectTo(CastDevice device) async {
    try {
      _session = await CastSessionManager().startSession(device);
      return _session?.state == CastSessionState.connected;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _session?.close();
    _session = null;
  }

  // ── Media ───────────────────────────────────────────────────────────────────

  /// Sends a media URL to the connected Cast device.
  /// [contentType] examples: 'video/mp4', 'application/x-mpegURL' (HLS)
  Future<bool> castMedia({
    required String url,
    required String title,
    String contentType = 'video/mp4',
    String? imageUrl,
  }) async {
    if (_session == null || !isConnected) return false;

    try {
      final message = {
        'type': 'LOAD',
        'autoplay': true,
        'currentTime': 0,
        'media': {
          'contentId': url,
          'contentType': _resolveContentType(url, contentType),
          'streamType': 'LIVE',
          'metadata': {
            'type': 0,
            'metadataType': 0,
            'title': title,
            if (imageUrl != null)
              'images': [{'url': imageUrl}],
          },
        },
      };
      _session!.sendMessage(CastSession.kNamespaceMedia, message);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> pauseCast() async {
    _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'PAUSE'});
  }

  Future<void> resumeCast() async {
    _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'PLAY'});
  }

  Future<void> stopCast() async {
    _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'STOP'});
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _resolveContentType(String url, String fallback) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8')) return 'application/x-mpegURL';
    if (lower.contains('.mp4'))  return 'video/mp4';
    if (lower.contains('.mkv'))  return 'video/x-matroska';
    if (lower.contains('.webm')) return 'video/webm';
    if (lower.contains('.ts'))   return 'video/mp2t';
    return fallback;
  }
}
