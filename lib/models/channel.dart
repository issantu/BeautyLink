class TvChannel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String category;
  final String language;
  final String? country;
  final bool isLive;
  final String? currentProgram;

  const TvChannel({
    required this.id,
    required this.name,
    this.logo,
    required this.streamUrl,
    required this.category,
    this.language = 'fr',
    this.country,
    this.isLive = true,
    this.currentProgram,
  });

  factory TvChannel.fromJson(Map<String, dynamic> json) {
    return TvChannel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'],
      streamUrl: json['url'] ?? '',
      category: json['categories']?.first ?? 'general',
      language: json['languages']?.first ?? 'fr',
      country: json['countries']?.first,
      isLive: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'url': streamUrl,
        'category': category,
        'language': language,
        'country': country,
      };
}

// Curated list of French channels with real IPTV-org stream IDs
class CuratedChannels {
  static List<TvChannel> get sportsChannels => [
        const TvChannel(
          id: 'bein_sports_1_fr',
          name: 'beIN Sports 1',
          logo: 'https://tv.iptv-org.github.io/logos/bein_sports_1_fr.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'sports',
          country: 'FR',
        ),
        const TvChannel(
          id: 'supersport_fr',
          name: 'SuperSport Football',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/supersport1.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
          category: 'sports',
          country: 'ZA',
        ),
        const TvChannel(
          id: 'eurosport1_fr',
          name: 'Eurosport 1',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/eurosport1.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
          category: 'sports',
          country: 'FR',
        ),
        const TvChannel(
          id: 'rmc_sport_1',
          name: 'RMC Sport 1',
          logo: 'https://tv.iptv-org.github.io/logos/rmcsport1.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
          category: 'sports',
          country: 'FR',
        ),
        const TvChannel(
          id: 'canal_sport',
          name: 'Canal+ Sport',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/canalsport.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
          category: 'sports',
          country: 'FR',
        ),
        const TvChannel(
          id: 'afrique_sport',
          name: 'Afrique Sport',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/afriquesport.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
          category: 'sports',
          country: 'CM',
        ),
      ];

  static List<TvChannel> get musicChannels => [
        const TvChannel(
          id: 'mcm_top',
          name: 'MCM Top',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/mcmtop.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/music.m3u',
          category: 'music',
          country: 'FR',
        ),
        const TvChannel(
          id: 'trace_urban',
          name: 'Trace Urban',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/traceurban.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/music.m3u',
          category: 'music',
          country: 'FR',
        ),
        const TvChannel(
          id: 'trace_africa',
          name: 'Trace Africa',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/traceafrica.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/music.m3u',
          category: 'music',
          country: 'ZA',
        ),
        const TvChannel(
          id: 'bet_africa',
          name: 'BET Africa',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/betafrica.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/music.m3u',
          category: 'music',
          country: 'ZA',
        ),
        const TvChannel(
          id: 'mtv_france',
          name: 'MTV France',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/mtvfr.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/music.m3u',
          category: 'music',
          country: 'FR',
        ),
      ];

  static List<TvChannel> get newsChannels => [
        const TvChannel(
          id: 'france24_fr',
          name: 'France 24',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/france24.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'news',
          country: 'FR',
        ),
        const TvChannel(
          id: 'bfm_tv',
          name: 'BFM TV',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/bfmtv.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'news',
          country: 'FR',
        ),
        const TvChannel(
          id: 'tv5_monde',
          name: 'TV5 Monde',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/tv5monde.png',
          streamUrl: 'https://iptv-org.github.io/iptv/languages/fra.m3u',
          category: 'news',
          country: 'FR',
        ),
        const TvChannel(
          id: 'rfi',
          name: 'RFI Planète Radio TV',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/rfi.png',
          streamUrl: 'https://iptv-org.github.io/iptv/languages/fra.m3u',
          category: 'news',
          country: 'FR',
        ),
        const TvChannel(
          id: 'africa24',
          name: 'Africa 24',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/africa24.png',
          streamUrl: 'https://iptv-org.github.io/iptv/languages/fra.m3u',
          category: 'news',
          country: 'GA',
        ),
        const TvChannel(
          id: 'congo_web_tv',
          name: 'Congo Web TV',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/congowebtv.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/cd.m3u',
          category: 'news',
          country: 'CD',
        ),
      ];

  static List<TvChannel> get generalChannels => [
        const TvChannel(
          id: 'france2',
          name: 'France 2',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/france2.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'general',
          country: 'FR',
        ),
        const TvChannel(
          id: 'tf1',
          name: 'TF1',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/tf1.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'general',
          country: 'FR',
        ),
        const TvChannel(
          id: 'france3',
          name: 'France 3',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/france3.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'general',
          country: 'FR',
        ),
        const TvChannel(
          id: 'm6',
          name: 'M6',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/m6.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
          category: 'general',
          country: 'FR',
        ),
        const TvChannel(
          id: 'rtv_congo',
          name: 'RTNC (RDC)',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/rtnc.png',
          streamUrl: 'https://iptv-org.github.io/iptv/countries/cd.m3u',
          category: 'general',
          country: 'CD',
        ),
      ];

  static List<TvChannel> get moviesChannels => [
        const TvChannel(
          id: 'cine_plus',
          name: 'Ciné+',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/cineplus.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
          category: 'movies',
          country: 'FR',
        ),
        const TvChannel(
          id: 'ocs_city',
          name: 'OCS City',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/ocscity.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
          category: 'movies',
          country: 'FR',
        ),
        const TvChannel(
          id: 'nollywood_fr',
          name: 'Nollywood TV',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/nollywoodtv.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
          category: 'movies',
          country: 'NG',
        ),
        const TvChannel(
          id: 'africa_magic',
          name: 'Africa Magic',
          logo: 'https://raw.githubusercontent.com/iptv-org/iptv/master/channels/logos/africamagic.png',
          streamUrl: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
          category: 'movies',
          country: 'NG',
        ),
      ];

  static List<TvChannel> get allChannels => [
        ...sportsChannels,
        ...musicChannels,
        ...newsChannels,
        ...generalChannels,
        ...moviesChannels,
      ];
}
