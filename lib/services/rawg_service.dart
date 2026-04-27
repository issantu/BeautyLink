import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/game.dart';

class RawgService {
  static const String _baseUrl = ApiConstants.rawgBaseUrl;
  static const String _apiKey = ApiConstants.rawgApiKey;

  String _buildUrl(String path, [Map<String, String>? extraParams]) {
    final params = {
      'key': _apiKey,
      'language': 'fra',
      ...?extraParams,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$_baseUrl$path?$query';
  }

  Future<List<Game>> getPopularGames() async {
    final url = _buildUrl('/games', {
      'ordering': '-rating',
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<List<Game>> getTrendingGames() async {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    final url = _buildUrl('/games', {
      'ordering': '-added',
      'dates': '${_formatDate(sixMonthsAgo)},${_formatDate(now)}',
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<List<Game>> getGamesByGenre(String genre) async {
    final url = _buildUrl('/games', {
      'genres': genre,
      'ordering': '-rating',
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<List<Game>> searchGames(String query) async {
    final url = _buildUrl('/games', {
      'search': query,
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<List<Game>> getFreeGames() async {
    final url = _buildUrl('/games', {
      'tags': 'free-to-play',
      'ordering': '-rating',
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<List<Game>> getMobileGames() async {
    final url = _buildUrl('/games', {
      'platforms': '21', // Android
      'ordering': '-rating',
      'page_size': '20',
    });
    return _fetchGames(url);
  }

  Future<Game?> getGameDetail(int gameId) async {
    final url = _buildUrl('/games/$gameId');
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return Game.fromJson(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<List<Game>> _fetchGames(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List?) ?? [];
        return results
            .map((j) => Game.fromJson(j))
            .where((g) => g.backgroundImage != null)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Fallback sample games when API key is not set
  List<Game> getSampleGames() {
    return [
      const Game(
        id: 1,
        name: 'FIFA 25',
        rating: 4.5,
        released: '2024-09-27',
        genres: ['Sport', 'Simulation'],
        platforms: ['PlayStation 5', 'Xbox Series X', 'PC'],
      ),
      const Game(
        id: 2,
        name: 'Call of Duty: Warzone',
        rating: 4.2,
        released: '2020-03-10',
        genres: ['Shooter', 'Action'],
        platforms: ['PlayStation 5', 'Xbox', 'PC'],
      ),
      const Game(
        id: 3,
        name: 'Tekken 8',
        rating: 4.4,
        released: '2024-01-26',
        genres: ['Combat', 'Action'],
        platforms: ['PlayStation 5', 'Xbox Series X', 'PC'],
      ),
    ];
  }
}
