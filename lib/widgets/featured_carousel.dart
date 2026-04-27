import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/movie.dart';
import '../screens/movies/movie_detail_screen.dart';

class FeaturedCarousel extends StatefulWidget {
  final List<Movie> movies;
  const FeaturedCarousel({super.key, required this.movies});

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final featured = widget.movies.take(8).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: featured.length,
          options: CarouselOptions(
            height: 230,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.08,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            onPageChanged: (i, _) => setState(() => _currentIndex = i),
          ),
          itemBuilder: (context, i, _) => _CarouselItem(movie: featured[i]),
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: featured.length,
          effect: ExpandingDotsEffect(
            dotWidth: 6,
            dotHeight: 6,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.bgCardLight,
            spacing: 4,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final Movie movie;
  const _CarouselItem({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop image
              CachedNetworkImage(
                imageUrl: movie.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.bgCard),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.bgCard,
                  child: const Icon(Icons.movie_rounded,
                      size: 64, color: AppColors.textMuted),
                ),
              ),

              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.imageOverlay),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: movie.isTV
                                ? AppColors.accent.withOpacity(0.8)
                                : AppColors.secondary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            movie.isTV ? '📺 SÉRIE' : '🎬 FILM',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Movie info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8)
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatRating(movie.voteAverage),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (movie.year.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                movie.year,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      size: 16, color: Colors.black),
                                  Text(
                                    ' Voir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
