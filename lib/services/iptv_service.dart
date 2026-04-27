import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class IptvService {
  // Parse M3U playlist and return channels
  Future<List<TvChannel>> parseM3uPlaylist(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return [];

      final lines = response.body.split('\n');
      final channels = <TvChannel>[];
      String? currentName;
      String? currentLogo;
      String? currentGroup;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXTINF')) {
          currentName = _extractAttribute(trimmed, 'tvg-name') ??
              trimmed.split(',').last.trim();
          currentLogo = _extractAttribute(trimmed, 'tvg-logo');
          currentGroup = _extractAttribute(trimmed, 'group-title') ?? 'general';
        } else if (trimmed.isNotEmpty &&
            !trimmed.startsWith('#') &&
            currentName != null) {
          channels.add(TvChannel(
            id: trimmed.hashCode.toString(),
            name: currentName,
            logo: currentLogo,
            streamUrl: trimmed,
            category: _mapCategory(currentGroup ?? ''),
          ));
          currentName = null;
          currentLogo = null;
          currentGroup = null;
        }
      }

      return channels;
    } catch (_) {
      return [];
    }
  }

  // Fetch channels from IPTV-org JSON API
  Future<List<TvChannel>> fetchChannelsFromApi({
    String? language,
    String? country,
    String? category,
  }) async {
    try {
      const url = 'https://iptv-org.github.io/api/channels.json';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);
      return data
          .map((j) => TvChannel.fromJson(j))
          .where((ch) {
            bool matches = true;
            if (language != null) {
              matches = matches && ch.language == language;
            }
            if (country != null) {
              matches = matches && (ch.country == country);
            }
            if (category != null) {
              matches = matches && ch.category == category;
            }
            return matches;
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  String? _extractAttribute(String line, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"');
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  String _mapCategory(String group) {
    final lower = group.toLowerCase();
    if (lower.contains('sport') || lower.contains('foot') || lower.contains('football')) {
      return 'sports';
    } else if (lower.contains('music') || lower.contains('musique')) {
      return 'music';
    } else if (lower.contains('news') || lower.contains('info') || lower.contains('actualit')) {
      return 'news';
    } else if (lower.contains('film') || lower.contains('movie') || lower.contains('cinéma') ||
        lower.contains('serie')) {
      return 'movies';
    } else if (lower.contains('combat') || lower.contains('box') || lower.contains('mma')) {
      return 'combat';
    }
    return 'general';
  }

  // Get curated channels (returns immediately without API call)
  List<TvChannel> getCuratedChannels(String category) {
    switch (category) {
      case 'sports':
        return CuratedChannels.sportsChannels;
      case 'music':
        return CuratedChannels.musicChannels;
      case 'news':
        return CuratedChannels.newsChannels;
      case 'movies':
        return CuratedChannels.moviesChannels;
      case 'general':
        return CuratedChannels.generalChannels;
      default:
        return CuratedChannels.allChannels;
    }
  }
}
