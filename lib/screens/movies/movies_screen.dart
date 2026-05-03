import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/movies_provider.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/section_header.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(movieFilterProvider);
    final selectedOrigin = ref.watch(movieOriginProvider);
    final searchQuery = ref.watch(movieSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Films & Séries',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'En français • Sous-titres français',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search bar
                    TextField(
                      onChanged: (v) =>
                          ref.read(movieSearchQueryProvider.notifier).state = v,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un film ou série...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textMuted, size: 18),
                                onPressed: () => ref
                                    .read(movieSearchQueryProvider.notifier)
                                    .state = '',
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Type filter (Films / Séries)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _TypeChip(
                      label: 'Tout',
                      selected: selectedFilter == 'all',
                      onTap: () =>
                          ref.read(movieFilterProvider.notifier).state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: '🎬 Films',
                      selected: selectedFilter == 'movie',
                      onTap: () => ref
                          .read(movieFilterProvider.notifier)
                          .state = 'movie',
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: '📺 Séries',
                      selected: selectedFilter == 'tv',
                      onTap: () =>
                          ref.read(movieFilterProvider.notifier).state = 'tv',
                    ),
                  ],
                ),
              ),
            ),

            // Origin filter (Hollywood, Nollywood, etc.)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    _OriginChip(
                      label: '🌍 Tous',
                      originId: 'all',
                      selected: selectedOrigin == 'all',
                      onTap: () =>
                          ref.read(movieOriginProvider.notifier).state = 'all',
                    ),
                    _OriginChip(
                      label: '🇫🇷 Français',
                      originId: 'french',
                      selected: selectedOrigin == 'french',
                      onTap: () => ref
                          .read(movieOriginProvider.notifier)
                          .state = 'french',
                    ),
                    _OriginChip(
                      label: '🇺🇸 Hollywood',
                      originId: 'hollywood',
                      selected: selectedOrigin == 'hollywood',
                      onTap: () => ref
                          .read(movieOriginProvider.notifier)
                          .state = 'hollywood',
                    ),
                    _OriginChip(
                      label: '🇳🇬 Nollywood',
                      originId: 'nollywood',
                      selected: selectedOrigin == 'nollywood',
                      onTap: () => ref
                          .read(movieOriginProvider.notifier)
                          .state = 'nollywood',
                    ),
                    _OriginChip(
                      label: '🇮🇳 Bollywood',
                      originId: 'bollywood',
                      selected: selectedOrigin == 'bollywood',
                      onTap: () => ref
                          .read(movieOriginProvider.notifier)
                          .state = 'bollywood',
                    ),
                  ],
                ),
              ),
            ),

            // Search results (if searching)
            if (searchQuery.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Résultats de recherche',
                  icon: Icons.search_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final results = r.watch(movieSearchResultsProvider);
                  return results.when(
                    data: (movies) => _MovieGrid(movies: _applyFilter(movies, selectedFilter)),
                    loading: () => const _GridSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),
            ] else ...[
              // Now Playing
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Au Cinéma',
                  icon: Icons.local_movies_rounded,
                  iconColor: AppColors.gold,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final movies = r.watch(nowPlayingProvider);
                  return movies.when(
                    data: (list) => _HorizontalMovies(movies: _applyFilter(list, selectedFilter)),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),

              // Popular (by origin)
              SliverToBoxAdapter(
                child: _OriginSection(
                  origin: selectedOrigin,
                  filter: selectedFilter,
                ),
              ),

              // Trending this week
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Tendances de la Semaine',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final trending = r.watch(trendingProvider);
                  return trending.when(
                    data: (list) => _MovieGrid(movies: _applyFilter(list, selectedFilter)),
                    loading: () => const _GridSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<Movie> _applyFilter(List<Movie> movies, String filter) {
    if (filter == 'all') return movies;
    return movies.where((m) => m.mediaType == filter).toList();
  }
}

class _OriginSection extends ConsumerWidget {
  final String origin;
  final String filter;

  const _OriginSection({required this.origin, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<Movie>> provider;
    String title;
    Color color;

    switch (origin) {
      case 'french':
        provider = ref.watch(frenchMoviesProvider);
        title = '🇫🇷 Cinéma Français';
        color = AppColors.accent;
        break;
      case 'nollywood':
        provider = ref.watch(nollywoodProvider);
        title = '🇳🇬 Nollywood';
        color = AppColors.gold;
        break;
      case 'bollywood':
        provider = ref.watch(bollywoodProvider);
        title = '🇮🇳 Bollywood';
        color = AppColors.ppv;
        break;
      default:
        provider = ref.watch(popularMoviesProvider);
        title = '🌟 Populaires';
        color = AppColors.secondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, iconColor: color),
        provider.when(
          data: (list) => _HorizontalMovies(
              movies: filter == 'all'
                  ? list
                  : list.where((m) => m.mediaType == filter).toList()),
          loading: () => const _HorizontalSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  final String label;
  final String originId;
  final bool selected;
  final VoidCallback onTap;

  const _OriginChip({
    required this.label,
    required this.originId,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.bgCardLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HorizontalMovies extends StatelessWidget {
  final List<Movie> movies;
  const _HorizontalMovies({required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.take(15).length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: MovieCard(movie: movies[i]),
        ),
      ),
    );
  }
}

class _MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  const _MovieGrid({required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aucun contenu trouvé',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: movies.take(15).length,
      itemBuilder: (ctx, i) => MovieCard(movie: movies[i]),
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
