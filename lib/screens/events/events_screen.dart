import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../payment/payment_screen.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveEvents = ref.watch(liveEventsProvider);
    final selectedCategory = ref.watch(eventCategoryProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Événements Locaux',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pay-Per-View • Diffusion en direct',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.ppv.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.ppv.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'PPV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ppv,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live events banner
            if (liveEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: _LiveNowBanner(event: liveEvents.first),
              ),

            // Category filters
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CatChip(
                      label: '🌐 Tout',
                      catId: 'all',
                      selected: selectedCategory == 'all',
                      onTap: () => ref
                          .read(eventCategoryProvider.notifier)
                          .state = 'all',
                    ),
                    _CatChip(
                      label: '⚽ Sport',
                      catId: 'sport',
                      selected: selectedCategory == 'sport',
                      onTap: () => ref
                          .read(eventCategoryProvider.notifier)
                          .state = 'sport',
                    ),
                    _CatChip(
                      label: '🎵 Musique',
                      catId: 'musique',
                      selected: selectedCategory == 'musique',
                      onTap: () => ref
                          .read(eventCategoryProvider.notifier)
                          .state = 'musique',
                    ),
                    _CatChip(
                      label: '🎭 Culture',
                      catId: 'culture',
                      selected: selectedCategory == 'culture',
                      onTap: () => ref
                          .read(eventCategoryProvider.notifier)
                          .state = 'culture',
                    ),
                    _CatChip(
                      label: '⛪ Religion',
                      catId: 'religion',
                      selected: selectedCategory == 'religion',
                      onTap: () => ref
                          .read(eventCategoryProvider.notifier)
                          .state = 'religion',
                    ),
                  ],
                ),
              ),
            ),

            // How PPV works info
            SliverToBoxAdapter(
              child: _PpvInfoCard(),
            ),

            // Events list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _EventListItem(event: filteredEvents[i]),
                childCount: filteredEvents.length,
              ),
            ),

            if (filteredEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy_rounded,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun événement dans cette catégorie',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Revenez bientôt pour les prochains événements!',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _LiveNowBanner extends StatelessWidget {
  final LiveEvent event;
  const _LiveNowBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.bgCard,
        ),
        child: Stack(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: event.thumbnailUrl ??
                    'https://picsum.photos/seed/event/800/450',
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.bgCard),
                errorWidget: (_, __, ___) => Container(color: AppColors.bgCard),
              ),
            ),
            // Gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.imageOverlay),
                child: SizedBox.expand(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LIVE badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (event.viewersCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.viewersCount} spectateurs',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Event info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (event.subtitle != null)
                        Text(
                          event.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _PriceBadge(event: event),
                          const SizedBox(width: 8),
                          _SourceBadge(event: event),
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
                                  ' Regarder',
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
    );
  }
}

class _EventListItem extends StatelessWidget {
  final LiveEvent event;
  const _EventListItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: event.isLive
              ? Border.all(color: AppColors.live.withOpacity(0.4), width: 1.5)
              : Border.all(color: AppColors.bgCardLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: event.thumbnailUrl ??
                        'https://picsum.photos/seed/${event.id}/800/450',
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        height: 160, color: AppColors.bgCardLight),
                    errorWidget: (_, __, ___) => Container(
                        height: 160, color: AppColors.bgCardLight),
                  ),
                  if (event.isLive)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SourceBadge(event: event),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        event.isLive
                            ? 'En cours'
                            : Formatters.formatEventDate(event.startTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          event.location!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PriceBadge(event: event),
                      const Spacer(),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EventDetailPage(event: event)),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            event.priceFc == 0 ? 'Regarder' : 'Acheter',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final LiveEvent event;
  const _PriceBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: event.priceFc == 0
            ? AppColors.live.withOpacity(0.2)
            : AppColors.ppv.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.priceFc == 0
              ? AppColors.live.withOpacity(0.4)
              : AppColors.ppv.withOpacity(0.4),
        ),
      ),
      child: Text(
        event.priceDisplay,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: event.priceFc == 0 ? AppColors.live : AppColors.ppv,
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final LiveEvent event;
  const _SourceBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (event.sourceType) {
      case EventSourceType.youtube:
        color = Colors.red;
        break;
      case EventSourceType.web:
        color = AppColors.primary;
        break;
      case EventSourceType.hls:
      case EventSourceType.rtmp:
        color = AppColors.accent;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        event.sourceBadge,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PpvInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le paiement PPV donne accès à un événement spécifique. '
              'Payez en mobile money et regardez en direct ou en rediffusion.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final String catId;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.catId,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ppv.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ppv : AppColors.bgCardLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.ppv : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Event detail page
class EventDetailPage extends ConsumerWidget {
  final LiveEvent event;
  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccessAsync = ref.watch(eventAccessProvider(event.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.thumbnailUrl ??
                        'https://picsum.photos/seed/${event.id}/800/450',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bgCard),
                    errorWidget: (_, __, ___) => Container(color: AppColors.bgCard),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.imageOverlay),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      if (event.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 4),
                              Text('EN DIRECT',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 11)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgCardLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('À VENIR',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ),
                      const SizedBox(width: 8),
                      _SourceBadge(event: event),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Details
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Date',
                    value: Formatters.formatEventDate(event.startTime),
                  ),
                  if (event.location != null)
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Lieu',
                      value: event.location!,
                    ),
                  if (event.organizer != null)
                    _DetailRow(
                      icon: Icons.business_rounded,
                      label: 'Organisateur',
                      value: event.organizer!,
                    ),

                  const SizedBox(height: 16),

                  if (event.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Price & purchase
                  hasAccessAsync.when(
                    data: (hasAccess) => hasAccess
                        ? _WatchButton(event: event)
                        : _PurchaseSection(event: event),
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, __) => _PurchaseSection(event: event),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _WatchButton extends StatelessWidget {
  final LiveEvent event;
  const _WatchButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.live.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.live.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.live, size: 20),
              SizedBox(width: 10),
              Text(
                'Accès débloqué',
                style: TextStyle(
                  color: AppColors.live,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {}, // Launch player
            icon: const Icon(Icons.play_circle_filled_rounded, size: 22),
            label: const Text('Regarder Maintenant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  final LiveEvent event;
  const _PurchaseSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accès à cet événement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                event.priceDisplay,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ppv,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'accès unique',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(ppvEvent: event),
                ),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 20),
              label: const Text('Payer et Regarder',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ppv,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '💳 Paiement via Mobile Money (Airtel, M-Pesa, Orange, Africell)',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
