import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/movie.dart';
import '../screens/movies/movie_detail_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.bgCard),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.bgCard,
                        child: const Icon(Icons.movie_rounded,
                            color: AppColors.textMuted, size: 32),
                      ),
                    ),
                    // Type badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.isTV ? 'TV' : '🎬',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Title
            Text(
              movie.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Rating
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 10, color: AppColors.gold),
                const SizedBox(width: 2),
                Text(
                  Formatters.formatRating(movie.voteAverage),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
                if (movie.year.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    movie.year,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
