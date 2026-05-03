import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../models/movie.dart';
import '../models/channel.dart';
import '../models/event.dart';
import '../providers/movies_provider.dart';
import '../providers/tv_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/movie_card.dart';
import '../widgets/channel_card.dart';
import '../widgets/event_card.dart';
import '../widgets/featured_carousel.dart';
import 'payment/payment_screen.dart';
import 'events/events_screen.dart' show EventDetailPage;
import 'main_nav_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingProvider);
    final featuredChannels = ref.watch(featuredChannelsProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);
    final liveEvents = ref.watch(liveEventsProvider);
    final upcomingEvents = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'OF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'OmniFlix',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                onPressed: () => _showSearch(context, ref),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'S\'abonner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Featured Carousel
          SliverToBoxAdapter(
            child: trendingAsync.when(
              data: (movies) => FeaturedCarousel(movies: movies),
              loading: () => const _CarouselSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Live Events Banner (if any live)
          if (liveEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: _LiveEventsBanner(events: liveEvents),
            ),

          // TV en Direct section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'TV en Direct',
                  icon: Icons.live_tv_rounded,
                  iconColor: AppColors.live,
                  onSeeAll: () =>
                      ref.read(navIndexProvider.notifier).state = 1,
                ),
                _ChannelRow(channels: featuredChannels),
              ],
            ),
          ),

          // Films à la Une
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Films à la Une',
                  icon: Icons.movie_creation_rounded,
                  iconColor: AppColors.secondary,
                  onSeeAll: () =>
                      ref.read(navIndexProvider.notifier).state = 2,
                ),
                popularMovies.when(
                  data: (movies) => _MovieRow(movies: movies),
                  loading: () => const _HorizontalSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Séries Populaires
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Séries Populaires',
                  icon: Icons.tv_rounded,
                  iconColor: AppColors.accent,
                  onSeeAll: () =>
                      ref.read(navIndexProvider.notifier).state = 2,
                ),
                popularTv.when(
                  data: (shows) => _MovieRow(movies: shows),
                  loading: () => const _HorizontalSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Événements Locaux section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Événements Locaux',
                  icon: Icons.event_rounded,
                  iconColor: AppColors.ppv,
                  badge: 'PPV',
                  onSeeAll: () =>
                      ref.read(navIndexProvider.notifier).state = 4,
                ),
                if (upcomingEvents.isNotEmpty)
                  _EventsRow(events: upcomingEvents),
              ],
            ),
          ),

          // Catégories de chaînes
          SliverToBoxAdapter(
            child: _CategoryGrid(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _OmniFlixSearchDelegate(ref),
    );
  }
}

// ------ Sub-widgets ------

class _LiveEventsBanner extends StatelessWidget {
  final List<LiveEvent> events;
  const _LiveEventsBanner({required this.events});

  @override
  Widget build(BuildContext context) {
    final event = events.first;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF2D1500)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ppv.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ppv,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'EN DIRECT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.viewersCount != null)
                    Text(
                      '${event.viewersCount} spectateurs',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ppv),
          ],
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final List<TvChannel> channels;
  const _ChannelRow({required this.channels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: channels.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChannelCard(channel: channels[i]),
        ),
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  final List<Movie> movies;
  const _MovieRow({required this.movies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.take(15).length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: MovieCard(movie: movies[i]),
        ),
      ),
    );
  }
}

class _EventsRow extends StatelessWidget {
  final List<LiveEvent> events;
  const _EventsRow({required this.events});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.take(6).length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: EventCard(event: events[i]),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.tvCategories;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Chaînes par Catégorie',
            icon: Icons.grid_view_rounded,
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final colors = [
                AppColors.sportColor,
                AppColors.combatColor,
                AppColors.musicColor,
                AppColors.moviesColor,
                AppColors.newsColor,
                AppColors.generalColor,
              ];
              final color = colors[i % colors.length];
              return GestureDetector(
                onTap: () {
                  // Navigate to TV tab and filter by category
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['icon'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Skeleton loaders
class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
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

// Search
class _OmniFlixSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _OmniFlixSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Rechercher films, séries, jeux...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.bgCard),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(query: query, ref: ref);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Rechercher du contenu',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return _SearchResults(query: query, ref: ref);
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final WidgetRef ref;

  const _SearchResults({required this.query, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    if (query.isEmpty) return const SizedBox.shrink();

    watchRef.read(movieSearchQueryProvider.notifier).state = query;
    final resultsAsync = watchRef.watch(movieSearchResultsProvider);

    return resultsAsync.when(
      data: (results) => results.isEmpty
          ? const Center(child: Text('Aucun résultat', style: TextStyle(color: AppColors.textSecondary)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: results.length,
              itemBuilder: (ctx, i) => MovieCard(movie: results[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de recherche')),
    );
  }
}

