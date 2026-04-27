import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game.dart';
import '../../providers/games_provider.dart';
import '../../widgets/game_card.dart';
import '../../widgets/section_header.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGenre = ref.watch(gameGenreProvider);
    final searchQuery = ref.watch(gameSearchQueryProvider);

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
                      'Jeux Vidéo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Découvrez, jouez et partagez',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search
                    TextField(
                      onChanged: (v) =>
                          ref.read(gameSearchQueryProvider.notifier).state = v,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un jeu...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textMuted, size: 18),
                                onPressed: () => ref
                                    .read(gameSearchQueryProvider.notifier)
                                    .state = '',
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Genre chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _GenreChip(
                        label: '🎮 Tous',
                        selected: selectedGenre == null,
                        onTap: () =>
                            ref.read(gameGenreProvider.notifier).state = null,
                      ),
                      ...gameGenres.map((g) => _GenreChip(
                            label: '${g['icon']} ${g['name']}',
                            selected: selectedGenre == g['id'],
                            onTap: () => ref
                                .read(gameGenreProvider.notifier)
                                .state = g['id'],
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Search results
            if (searchQuery.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Résultats',
                  icon: Icons.search_rounded,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final results = r.watch(gameSearchResultsProvider);
                  return results.when(
                    data: (games) => _GamesGrid(games: games),
                    loading: () => const _GridSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),
            ] else ...[
              // Trending new releases
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: '🔥 Sorties Récentes',
                  icon: Icons.new_releases_rounded,
                  iconColor: AppColors.secondary,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final games = r.watch(trendingGamesProvider);
                  return games.when(
                    data: (list) => _HorizontalGames(games: list),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),

              // Popular by genre (or all popular)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: selectedGenre == null
                          ? '⭐ Jeux Populaires'
                          : '⭐ ${gameGenres.firstWhere((g) => g['id'] == selectedGenre, orElse: () => {'name': 'Populaires'})['name']} Populaires',
                      iconColor: AppColors.gold,
                    ),
                    Consumer(builder: (ctx, r, _) {
                      final games = r.watch(genreGamesProvider);
                      return games.when(
                        data: (list) => _GamesGrid(games: list),
                        loading: () => const _GridSkeleton(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    }),
                  ],
                ),
              ),

              // Free to play
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: '🆓 Gratuits',
                  icon: Icons.card_giftcard_rounded,
                  iconColor: AppColors.live,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final games = r.watch(freeGamesProvider);
                  return games.when(
                    data: (list) => _HorizontalGames(games: list),
                    loading: () => const _HorizontalSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ),

              // Mobile games
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: '📱 Jeux Mobile',
                  iconColor: AppColors.primary,
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(builder: (ctx, r, _) {
                  final games = r.watch(mobileGamesProvider);
                  return games.when(
                    data: (list) => _HorizontalGames(games: list),
                    loading: () => const _HorizontalSkeleton(),
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
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.bgCardLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HorizontalGames extends StatelessWidget {
  final List<Game> games;
  const _HorizontalGames({required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.take(12).length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GameCard(game: games[i]),
        ),
      ),
    );
  }
}

class _GamesGrid extends StatelessWidget {
  final List<Game> games;
  const _GamesGrid({required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aucun jeu trouvé',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: games.take(12).length,
      itemBuilder: (ctx, i) => GameCard(game: games[i], isGrid: true),
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          width: 260,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
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
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
