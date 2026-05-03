import 'dart:io';
import 'package:flutter/services.dart';

class VpnService {
  static const _channel = MethodChannel('com.omniflix.app/vpn');

  // Detect if any VPN is currently active on the device
  static Future<bool> isVpnActive() async {
    try {
      // Check network interfaces for VPN tunnel
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        // VPN tunnel interface names
        if (name.contains('tun') ||
            name.contains('tap') ||
            name.contains('ppp') ||
            name.contains('ipsec') ||
            name.contains('vpn') ||
            name.contains('wg') || // WireGuard
            name.contains('utun')) {
          // utun = iOS VPN
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Get Lokke download URLs
  static const String lokkePlayStore =
      'https://play.google.com/store/apps/details?id=com.lokke.android';
  static const String lokkeAppStore =
      'https://apps.apple.com/app/lokke-no-log-vpn-browser/id1601909578';
  static const String lokkeWebsite = 'https://lokke.app';
  static const String lokkeApkDirect =
      'https://lokke.app/download/lokke-latest.apk';
}
