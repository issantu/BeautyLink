class ApiConstants {
  // TMDb - The Movie Database
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbReadAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjZGE1Zjc2YjE3OGZiNzU5Njg1ZDA0ZGI0MDU2NjEzMyIsIm5iZiI6MTc3NzUxNTYzOC4zNywic3ViIjoiNjlmMmJjNzY0NmUyZWVhOWQxYjgyODJiIiwic2NvcGVzIjpbImFwaV9yZWFkIl0sInZlcnNpb24iOjF9.LASIsH5NPk7N6TWJNkIffrazzuLcRhLK4e0_gmF5PgI';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String tmdbApiKey = 'cda5f76b178fb759685d04db40566133';
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
