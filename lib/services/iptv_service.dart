import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/channel.dart';
import '../models/vod_entry.dart';

class IptvService {
  static const _frenchLangs = {'fra', 'fre', 'fr'};
  static const _frenchCountries = {
    'FR', 'CD', 'CM', 'SN', 'CI', 'BJ', 'BF',
    'TG', 'GA', 'CG', 'RW', 'BI', 'MG', 'ML', 'NE', 'TD', 'CF', 'GN',
    'GQ', 'DJ', 'KM', 'MU', 'SC', 'MR', 'HT',
  };

  // Cache the raw subscribed M3U content to avoid fetching twice
  Future<String>? _subscribedContentFuture;

  Future<String> _getSubscribedContent() {
    _subscribedContentFuture ??= _fetchRaw(ApiConstants.subscribedM3uUrl, timeout: 45);
    return _subscribedContentFuture!;
  }

  Future<String> _fetchRaw(String url, {int timeout = 30}) async {
    if (url.isEmpty) return '';
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'OmniFlix/1.0'})
          .timeout(Duration(seconds: timeout));
      return response.statusCode == 200 ? response.body : '';
    } catch (_) {
      return '';
    }
  }

  // ── Public channel methods ────────────────────────────────────────────────

  Future<List<TvChannel>> loadFromM3u(String url) async {
    final content = await _fetchRaw(url);
    if (content.isEmpty) return [];
    return _parseChannels(content);
  }

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
        if (seen.add(ch.name.toLowerCase())) channels.add(ch);
      }
    }
    return channels;
  }

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
    return _prioritizeFrench(await loadFromM3u(url));
  }

  Future<List<TvChannel>> loadSubscribed() async {
    final content = await _getSubscribedContent();
    if (content.isEmpty) return [];
    return _parseChannels(content);
  }

  Future<List<TvChannel>> getAllChannels({String category = 'all'}) async {
    final subscribed = await loadSubscribed();

    if (subscribed.isNotEmpty) {
      if (category == 'all') return subscribed;
      final filtered = subscribed.where((c) => c.category == category).toList();
      return filtered.isNotEmpty ? filtered : subscribed;
    }

    return getCuratedChannels(category);
  }

  List<TvChannel> getCuratedChannels(String category) {
    if (category == 'all') return CuratedChannels.allChannels;
    return CuratedChannels.allChannels.where((c) => c.category == category).toList();
  }

  // ── VOD methods ───────────────────────────────────────────────────────────

  Future<List<VodEntry>> loadVodMovies() async {
    final content = await _getSubscribedContent();
    if (content.isEmpty) return [];
    return _parseVod(content).where((e) => !e.isSeries).toList();
  }

  Future<List<VodEntry>> loadVodSeries() async {
    final content = await _getSubscribedContent();
    if (content.isEmpty) return [];
    return _parseVod(content).where((e) => e.isSeries).toList();
  }

  // Find the best IPTV VOD match for a TMDb movie title
  static VodEntry? findMatch(List<VodEntry> entries, String title) {
    final q = _normalize(title);
    if (q.isEmpty) return null;

    // 1. Exact normalized match
    for (final e in entries) {
      if (_normalize(e.title) == q) return e;
    }
    // 2. VOD title contains query
    for (final e in entries) {
      if (_normalize(e.title).contains(q)) return e;
    }
    // 3. Query contains VOD title (short title within longer query)
    for (final e in entries) {
      final et = _normalize(e.title);
      if (et.length > 4 && q.contains(et)) return e;
    }
    return null;
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]\s*'), ' ')
      .replaceAll(RegExp(r"[^\w\s']"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ── Parsing ───────────────────────────────────────────────────────────────

  List<TvChannel> _parseChannels(String content) {
    final channels = <TvChannel>[];
    final lines = content.split('\n');
    String? name, logo, group, language, country;

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
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null && name.isNotEmpty) {
        // Exclude Xtream Codes VOD entries — they live in /movie/ and /series/
        if (!line.contains('/movie/') && !line.contains('/series/')) {
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
        }
        name = null; logo = null; group = null; language = null; country = null;
      }
    }
    return channels;
  }

  List<VodEntry> _parseVod(String content) {
    final entries = <VodEntry>[];
    final lines = content.split('\n');
    String? name, logo, group;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF')) {
        name = _attr(line, 'tvg-name') ??
            (line.contains(',') ? line.split(',').last.trim() : null);
        logo = _attr(line, 'tvg-logo');
        group = _attr(line, 'group-title') ?? '';
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null && name.isNotEmpty) {
        final isMovie = line.contains('/movie/');
        final isSer = line.contains('/series/');
        if (isMovie || isSer) {
          entries.add(VodEntry(
            id: 'vod_${entries.length}',
            title: name,
            logo: logo,
            streamUrl: line,
            group: group ?? '',
            isSeries: isSer,
          ));
        }
        name = null; logo = null; group = null;
      }
    }
    return entries;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
    final m = regex.firstMatch(line);
    final v = m?.group(1)?.trim();
    return (v != null && v.isNotEmpty) ? v : null;
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
