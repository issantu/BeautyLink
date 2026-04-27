import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/event.dart';
import '../screens/events/events_screen.dart';

class EventCard extends StatelessWidget {
  final LiveEvent event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
      ),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: event.isLive
              ? Border.all(color: AppColors.live.withOpacity(0.5), width: 1.5)
              : Border.all(color: AppColors.bgCardLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: event.thumbnailUrl ??
                        'https://picsum.photos/seed/${event.id}/400/200',
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 100, color: AppColors.bgCardLight),
                    errorWidget: (_, __, ___) =>
                        Container(height: 100, color: AppColors.bgCardLight),
                  ),
                  if (event.isLive)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: event.priceFc == 0
                            ? AppColors.live.withOpacity(0.85)
                            : AppColors.ppv.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        event.priceDisplay,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
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
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.isLive
                                ? 'En cours'
                                : Formatters.formatShortDate(event.startTime),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
