class ApiConstants {
  // TMDb - The Movie Database
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY'; // Get at developer.themoviedb.org
  static const String tmdbLanguage = 'fr-FR';

  // TMDb Image Sizes
  static const String imgPoster = '$tmdbImageBaseUrl/w342';
  static const String imgBackdrop = '$tmdbImageBaseUrl/w780';
  static const String imgOriginal = '$tmdbImageBaseUrl/original';

  // RAWG Games Database
  static const String rawgBaseUrl = 'https://api.rawg.io/api';
  static const String rawgApiKey = 'YOUR_RAWG_API_KEY'; // Get at rawg.io/apidocs

  // IPTV-org API
  static const String iptvApiBaseUrl = 'https://iptv-org.github.io/api';
  static const String iptvChannelsUrl = '$iptvApiBaseUrl/channels.json';
  static const String iptvStreamsUrl = '$iptvApiBaseUrl/streams.json';

  // French IPTV Playlist
  static const String frenchM3uUrl =
      'https://iptv-org.github.io/iptv/languages/fra.m3u';

  // Sports IPTV Playlist
  static const String sportsM3uUrl =
      'https://iptv-org.github.io/iptv/categories/sports.m3u';
}
