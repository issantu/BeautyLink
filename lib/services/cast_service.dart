import 'package:cast/cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final castServiceProvider = Provider<CastService>((_) => CastService());

/// Wraps the `cast` package (Google Cast SDK v2) for streaming media URLs
/// to Chromecast / Google TV devices on the local network.
///
/// Uses the "Default Media Receiver" (App ID: CC1AD845) — supports
/// HLS, MP4, DASH, WebM without developer registration.
class CastService {
  CastSession? _session;
  List<CastDevice> _devices = [];
  bool _isDiscovering = false;

  CastSession? get session => _session;
  bool get isConnected => _session?.state == CastSessionState.connected;
  List<CastDevice> get devices => List.unmodifiable(_devices);

  // ── Discovery ───────────────────────────────────────────────────────────────

  Future<List<CastDevice>> discoverDevices({
    Duration duration = const Duration(seconds: 4),
  }) async {
    if (_isDiscovering) return _devices;
    _isDiscovering = true;
    _devices = [];
    try {
      _devices = await CastDiscoveryService().search(timeout: duration);
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
      // Wait briefly for connection to establish
      await Future.delayed(const Duration(milliseconds: 800));
      return _session?.state == CastSessionState.connected;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_session != null) {
      await CastSessionManager().endSession(_session!.sessionId);
      _session = null;
    }
  }

  // ── Media ───────────────────────────────────────────────────────────────────

  Future<bool> castMedia({
    required String url,
    required String title,
    String contentType = 'video/mp4',
    String? imageUrl,
  }) async {
    if (_session == null || !isConnected) return false;
    try {
      _session!.sendMessage(CastSession.kNamespaceMedia, {
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
            if (imageUrl != null) 'images': [{'url': imageUrl}],
          },
        },
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void pauseCast() =>
      _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'PAUSE'});

  void resumeCast() =>
      _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'PLAY'});

  void stopCast() =>
      _session?.sendMessage(CastSession.kNamespaceMedia, {'type': 'STOP'});

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
