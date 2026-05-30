import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/vod_entry.dart';
import '../services/tmdb_service.dart';
import 'tv_provider.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());

// Trending content (movies + shows)
final trendingProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getTrending();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Popular movies
final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getPopularMovies();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Popular TV shows
final popularTvProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getPopularTvShows();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// French movies
final frenchMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getFrenchMovies();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Nollywood
final nollywoodProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getNollywoodMovies();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Bollywood
final bollywoodProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getBollywoodMovies();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Now Playing
final nowPlayingProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = await service.getNowPlayingMovies();
  if (results.isEmpty) return service.getSampleMovies();
  return results;
});

// Search provider
final movieSearchQueryProvider = StateProvider<String>((ref) => '');

final movieSearchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(movieSearchQueryProvider);
  if (query.isEmpty) return [];
  final service = ref.watch(tmdbServiceProvider);
  return service.searchMovies(query);
});

// Selected filter: 'all', 'movie', 'tv'
final movieFilterProvider = StateProvider<String>((ref) => 'all');

// Selected origin: 'all', 'hollywood', 'nollywood', 'bollywood', 'french'
final movieOriginProvider = StateProvider<String>((ref) => 'all');

// ── IPTV VOD providers ────────────────────────────────────────────────────

final iptvVodMoviesProvider = FutureProvider<List<VodEntry>>((ref) async {
  final service = ref.watch(iptvServiceProvider);
  return service.loadVodMovies();
});

final iptvVodSeriesProvider = FutureProvider<List<VodEntry>>((ref) async {
  final service = ref.watch(iptvServiceProvider);
  return service.loadVodSeries();
});

// IPTV search results (reacts to movieSearchQueryProvider)
final iptvVodSearchProvider = FutureProvider<List<VodEntry>>((ref) async {
  final query = ref.watch(movieSearchQueryProvider);
  if (query.length < 2) return [];
  final movies = await ref.watch(iptvVodMoviesProvider.future);
  final series = await ref.watch(iptvVodSeriesProvider.future);
  final q = query.toLowerCase();
  return [...movies, ...series]
      .where((e) => e.searchKey.contains(q))
      .take(20)
      .toList();
});
