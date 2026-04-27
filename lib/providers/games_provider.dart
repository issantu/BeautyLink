import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/rawg_service.dart';

final rawgServiceProvider = Provider<RawgService>((ref) => RawgService());

final popularGamesProvider = FutureProvider<List<Game>>((ref) async {
  final service = ref.watch(rawgServiceProvider);
  final results = await service.getPopularGames();
  if (results.isEmpty) return service.getSampleGames();
  return results;
});

final trendingGamesProvider = FutureProvider<List<Game>>((ref) async {
  final service = ref.watch(rawgServiceProvider);
  final results = await service.getTrendingGames();
  if (results.isEmpty) return service.getSampleGames();
  return results;
});

final freeGamesProvider = FutureProvider<List<Game>>((ref) async {
  final service = ref.watch(rawgServiceProvider);
  final results = await service.getFreeGames();
  if (results.isEmpty) return service.getSampleGames();
  return results;
});

final mobileGamesProvider = FutureProvider<List<Game>>((ref) async {
  final service = ref.watch(rawgServiceProvider);
  final results = await service.getMobileGames();
  if (results.isEmpty) return service.getSampleGames();
  return results;
});

// Genre filter
final gameGenreProvider = StateProvider<String?>((ref) => null);

// Genre-filtered games
final genreGamesProvider = FutureProvider<List<Game>>((ref) async {
  final genre = ref.watch(gameGenreProvider);
  if (genre == null) return ref.watch(popularGamesProvider).value ?? [];
  final service = ref.watch(rawgServiceProvider);
  final results = await service.getGamesByGenre(genre);
  if (results.isEmpty) return service.getSampleGames();
  return results;
});

// Game search
final gameSearchQueryProvider = StateProvider<String>((ref) => '');

final gameSearchResultsProvider = FutureProvider<List<Game>>((ref) async {
  final query = ref.watch(gameSearchQueryProvider);
  if (query.isEmpty) return [];
  final service = ref.watch(rawgServiceProvider);
  return service.searchGames(query);
});

// Game genre list
const gameGenres = [
  {'id': 'action', 'name': 'Action', 'icon': '⚔️'},
  {'id': 'sports', 'name': 'Sport', 'icon': '⚽'},
  {'id': 'racing', 'name': 'Course', 'icon': '🏎️'},
  {'id': 'shooter', 'name': 'Tir', 'icon': '🔫'},
  {'id': 'role-playing-games-rpg', 'name': 'RPG', 'icon': '🧙'},
  {'id': 'strategy', 'name': 'Stratégie', 'icon': '♟️'},
  {'id': 'fighting', 'name': 'Combat', 'icon': '🥊'},
  {'id': 'adventure', 'name': 'Aventure', 'icon': '🗺️'},
  {'id': 'simulation', 'name': 'Simulation', 'icon': '🎮'},
  {'id': 'puzzle', 'name': 'Puzzle', 'icon': '🧩'},
];
