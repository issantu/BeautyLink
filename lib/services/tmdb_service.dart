import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/movie.dart';

class TmdbService {
  static const String _baseUrl = ApiConstants.tmdbBaseUrl;
  static const String _apiKey = ApiConstants.tmdbApiKey;
  static const String _lang = ApiConstants.tmdbLanguage;

  static final Map<String, String> _headers = {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${ApiConstants.tmdbReadAccessToken}',
  };

  String _buildUrl(String path, [Map<String, String>? extraParams]) {
    final params = {
      'api_key': _apiKey,
      'language': _lang,
      ...?extraParams,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$_baseUrl$path?$query';
  }

  Future<List<Movie>> getTrending({String timeWindow = 'week'}) async {
    final url = _buildUrl('/trending/all/$timeWindow');
    return _fetchMovieList(url);
  }

  Future<List<Movie>> getPopularMovies() async {
    final url = _buildUrl('/movie/popular');
    return _fetchMovieList(url, mediaType: 'movie');
  }

  Future<List<Movie>> getPopularTvShows() async {
    final url = _buildUrl('/tv/popular');
    return _fetchMovieList(url, mediaType: 'tv');
  }

  Future<List<Movie>> getNowPlayingMovies() async {
    final url = _buildUrl('/movie/now_playing');
    return _fetchMovieList(url, mediaType: 'movie');
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final url = _buildUrl('/movie/top_rated');
    return _fetchMovieList(url, mediaType: 'movie');
  }

  Future<List<Movie>> getTopRatedTv() async {
    final url = _buildUrl('/tv/top_rated');
    return _fetchMovieList(url, mediaType: 'tv');
  }

  // French-dubbed / French-language content specifically
  Future<List<Movie>> getFrenchMovies() async {
    final url = _buildUrl('/discover/movie', {
      'with_original_language': 'fr',
      'sort_by': 'popularity.desc',
    });
    return _fetchMovieList(url, mediaType: 'movie');
  }

  // African / Nollywood content
  Future<List<Movie>> getNollywoodMovies() async {
    final url = _buildUrl('/discover/movie', {
      'region': 'NG',
      'sort_by': 'popularity.desc',
    });
    return _fetchMovieList(url, mediaType: 'movie');
  }

  // Bollywood content in French
  Future<List<Movie>> getBollywoodMovies() async {
    final url = _buildUrl('/discover/movie', {
      'with_original_language': 'hi',
      'sort_by': 'popularity.desc',
    });
    return _fetchMovieList(url, mediaType: 'movie');
  }

  Future<List<Movie>> searchMovies(String query) async {
    final url = _buildUrl('/search/multi', {'query': query});
    return _fetchMovieList(url);
  }

  Future<Movie?> getMovieDetail(int movieId) async {
    final url = _buildUrl('/movie/$movieId', {
      'append_to_response': 'credits,videos,similar',
    });
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data, mediaType: 'movie');
      }
    } catch (_) {}
    return null;
  }

  Future<Movie?> getTvDetail(int tvId) async {
    final url = _buildUrl('/tv/$tvId', {
      'append_to_response': 'credits,videos,similar',
    });
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data, mediaType: 'tv');
      }
    } catch (_) {}
    return null;
  }

  Future<List<Movie>> _fetchMovieList(String url, {String? mediaType}) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List?) ?? [];
        return results
            .map((json) => Movie.fromJson(
                  json,
                  mediaType: mediaType ?? (json['media_type'] ?? 'movie'),
                ))
            .where((m) => m.posterPath != null)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // Fallback sample movies when API key is not set
  List<Movie> getSampleMovies() {
    return [
      Movie(
        id: 1,
        title: 'Le Roi Lion',
        originalTitle: 'The Lion King',
        posterPath: null,
        backdropPath: null,
        overview: 'L\'histoire épique de Simba, un jeune lion destiné à régner sur le Royaume des Lions.',
        releaseDate: '2019-07-12',
        voteAverage: 7.1,
        voteCount: 9500,
        genreIds: [16, 18, 10751],
        mediaType: 'movie',
      ),
      Movie(
        id: 2,
        title: 'Lupin',
        originalTitle: 'Lupin',
        posterPath: null,
        backdropPath: null,
        overview: 'Arsène Lupin, gentleman-cambrioleur dans le Paris moderne, vole et escroque les riches.',
        releaseDate: '2021-01-08',
        voteAverage: 7.7,
        voteCount: 4300,
        genreIds: [80, 9648, 35],
        mediaType: 'tv',
      ),
    ];
  }
}
