import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final bool isGrid;
  const GameCard({super.key, required this.game, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGameDetail(context),
      child: isGrid ? _buildGridCard() : _buildHorizontalCard(),
    );
  }

  Widget _buildHorizontalCard() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: CachedNetworkImage(
              imageUrl: game.coverImage,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(height: 110, color: AppColors.bgCardLight),
              errorWidget: (_, __, ___) => Container(
                height: 110,
                color: AppColors.bgCardLight,
                child: const Icon(Icons.sports_esports_rounded,
                    color: AppColors.textMuted, size: 36),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        game.ratingDisplay,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      if (game.year.isNotEmpty)
                        Text(
                          game.year,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Stack(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: CachedNetworkImage(
              imageUrl: game.coverImage,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.bgCardLight),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.bgCardLight,
                child: const Icon(Icons.sports_esports_rounded,
                    color: AppColors.textMuted, size: 36),
              ),
            ),
          ),
          // Gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.imageOverlay),
              child: SizedBox.expand(),
            ),
          ),
          // Info
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 10, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text(
                      game.ratingDisplay,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGameDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GameDetailSheet(game: game),
    );
  }
}

class _GameDetailSheet extends StatelessWidget {
  final Game game;
  const _GameDetailSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: game.coverImage,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 200, color: AppColors.bgCardLight),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.bgCardLight,
                    child: const Icon(Icons.sports_esports_rounded,
                        size: 64, color: AppColors.textMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating + year
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(game.ratingDisplay,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        if (game.year.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(game.year,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Platforms
                    if (game.platforms.isNotEmpty) ...[
                      Text(
                        game.platformsDisplay,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Genres
                    if (game.genres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: game.genres
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(g,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                      ),

                    if (game.description != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.description!.length > 400
                            ? '${game.description!.substring(0, 400)}...'
                            : game.description!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.sports_esports_rounded, size: 20),
                        label: const Text('Trouver le jeu',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
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
