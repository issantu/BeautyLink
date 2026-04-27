import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/channel.dart';
import '../screens/live_tv/tv_player_screen.dart';

class ChannelCard extends StatelessWidget {
  final TvChannel channel;
  const ChannelCard({super.key, required this.channel});

  Color get _categoryColor {
    switch (channel.category) {
      case 'sports':
        return AppColors.sportColor;
      case 'music':
        return AppColors.musicColor;
      case 'news':
        return AppColors.newsColor;
      case 'movies':
        return AppColors.moviesColor;
      case 'combat':
        return AppColors.combatColor;
      default:
        return AppColors.generalColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TvPlayerScreen(channel: channel)),
      ),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bgCardLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                shape: BoxShape.circle,
              ),
              child: channel.logo != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: channel.logo!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const Icon(Icons.tv_rounded, color: AppColors.textMuted, size: 20),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.tv_rounded, color: AppColors.textMuted, size: 20),
                      ),
                    )
                  : const Icon(Icons.tv_rounded, color: AppColors.textMuted, size: 20),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 3),
            // Live dot
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.live,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
