import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/channel.dart';

class IptvService {
  // French-related language codes and keywords
  static const _frenchLangs = {'fra', 'fre', 'fr'};
  static const _frenchCountries = {'FR', 'CD', 'CM', 'SN', 'CI', 'BJ', 'BF',
      'TG', 'GA', 'CG', 'RW', 'BI', 'MG', 'ML', 'NE', 'TD', 'CF', 'GN',
      'GQ', 'DJ', 'KM', 'MU', 'SC', 'MR', 'HT'};

  // Load channels from a specific M3U playlist URL
  Future<List<TvChannel>> loadFromM3u(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url),
              headers: {'User-Agent': 'OmniFlix/1.0'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return [];
      return _parseM3u(response.body);
    } catch (_) {
      return [];
    }
  }

  // Load and filter french channels from master playlist
  Future<List<TvChannel>> loadFrenchChannels() async {
    final results = await Future.wait([
      loadFromM3u(ApiConstants.frenchM3uUrl),
      loadFromM3u(ApiConstants.franceM3uUrl),
      loadFromM3u(ApiConstants.congoM3uUrl),
      loadFromM3u(ApiConstants.camerounM3uUrl),
      loadFromM3u(ApiConstants.senegalM3uUrl),
      loadFromM3u(ApiConstants.coteIvoireM3uUrl),
    ]);

    final seen = <String>{};
    final channels = <TvChannel>[];
    for (final list in results) {
      for (final ch in list) {
        if (seen.add(ch.name.toLowerCase())) {
          channels.add(ch);
        }
      }
    }
    return channels;
  }

  // Load channels by category from IPTV-org category playlists
  Future<List<TvChannel>> loadByCategory(String category) async {
    String url;
    switch (category) {
      case 'sports':
      case 'combat':
        url = ApiConstants.sportsM3uUrl;
        break;
      case 'music':
        url = ApiConstants.musicM3uUrl;
        break;
      case 'news':
        url = ApiConstants.newsM3uUrl;
        break;
      case 'movies':
        url = ApiConstants.moviesM3uUrl;
        break;
      default:
        url = ApiConstants.generalM3uUrl;
    }

    final channels = await loadFromM3u(url);
    // Prefer french/african channels but include all
    return _prioritizeFrench(channels);
  }

  // Load subscribed playlist (highest priority)
  Future<List<TvChannel>> loadSubscribed() async {
    if (ApiConstants.subscribedM3uUrl.isEmpty) return [];
    return loadFromM3u(ApiConstants.subscribedM3uUrl);
  }

  // Get channels: subscribed playlist is the ONLY source (fast).
  // Falls back to curated list only if subscribed fails.
  Future<List<TvChannel>> getAllChannels({String category = 'all'}) async {
    // 1. Try subscribed playlist first (stable, VPN-enabled)
    final subscribed = await loadSubscribed();

    if (subscribed.isNotEmpty) {
      if (category == 'all') return subscribed;
      // Filter by category
      final filtered = subscribed
          .where((c) => c.category == category)
          .toList();
      // If no match in category, return all subscribed channels
      return filtered.isNotEmpty ? filtered : subscribed;
    }

    // 2. Fallback: curated list (instant, no network needed)
    return getCuratedChannels(category);
  }

  // Get curated channels immediately (no async, for home screen)
  List<TvChannel> getCuratedChannels(String category) {
    if (category == 'all') return CuratedChannels.allChannels;
    return CuratedChannels.allChannels
        .where((c) => c.category == category)
        .toList();
  }

  // Parse M3U playlist text into TvChannel list
  List<TvChannel> _parseM3u(String content) {
    final channels = <TvChannel>[];
    final lines = content.split('\n');

    String? name;
    String? logo;
    String? group;
    String? language;
    String? country;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF')) {
        name = _attr(line, 'tvg-name') ??
            _attr(line, 'tvg-id') ??
            (line.contains(',') ? line.split(',').last.trim() : null);
        logo = _attr(line, 'tvg-logo');
        group = _attr(line, 'group-title') ?? '';
        language = _attr(line, 'tvg-language') ?? '';
        country = _attr(line, 'tvg-country') ?? '';
      } else if (line.isNotEmpty &&
          !line.startsWith('#') &&
          name != null &&
          name.isNotEmpty) {
        channels.add(TvChannel(
          id: '${name.toLowerCase().replaceAll(' ', '_')}_$i',
          name: name,
          logo: logo,
          streamUrl: line,
          category: _mapCategory(group ?? '', name),
          language: language?.toLowerCase() ?? 'fr',
          country: country?.isNotEmpty == true ? country : null,
          isLive: true,
        ));
        name = null;
        logo = null;
        group = null;
        language = null;
        country = null;
      }
    }
    return channels;
  }

  // Prioritize french/african channels in a list
  List<TvChannel> _prioritizeFrench(List<TvChannel> channels) {
    final french = <TvChannel>[];
    final others = <TvChannel>[];

    for (final ch in channels) {
      if (_frenchLangs.contains(ch.language.toLowerCase()) ||
          _frenchCountries.contains(ch.country?.toUpperCase())) {
        french.add(ch);
      } else {
        others.add(ch);
      }
    }
    return [...french, ...others];
  }

  String? _attr(String line, String key) {
    final regex = RegExp('$key="([^"]*)"', caseSensitive: false);
    return regex.firstMatch(line)?.group(1)?.trim().isNotEmpty == true
        ? regex.firstMatch(line)!.group(1)!.trim()
        : null;
  }

  String _mapCategory(String group, String name) {
    final g = group.toLowerCase();
    final n = name.toLowerCase();
    final combined = '$g $n';

    if (combined.contains('sport') || combined.contains('foot') ||
        combined.contains('soccer') || combined.contains('football') ||
        combined.contains('rugby') || combined.contains('basket')) {
      return 'sports';
    }
    if (combined.contains('box') || combined.contains('mma') ||
        combined.contains('combat') || combined.contains('fight') ||
        combined.contains('wrestling') || combined.contains('ufc')) {
      return 'combat';
    }
    if (combined.contains('music') || combined.contains('musique') ||
        combined.contains('mtv') || combined.contains('trace') ||
        combined.contains('bet') || combined.contains('mcm')) {
      return 'music';
    }
    if (combined.contains('news') || combined.contains('info') ||
        combined.contains('actualit') || combined.contains('bfm') ||
        combined.contains('france 24') || combined.contains('africa 24') ||
        combined.contains('rfi') || combined.contains('al jazeera') ||
        combined.contains('cnn') || combined.contains('bbc')) {
      return 'news';
    }
    if (combined.contains('film') || combined.contains('movie') ||
        combined.contains('cinema') || combined.contains('cinéma') ||
        combined.contains('serie') || combined.contains('nollywood') ||
        combined.contains('cine') || combined.contains('ocs')) {
      return 'movies';
    }
    return 'general';
  }
}
