import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'live_tv/vavoo_screen.dart';
import 'movies/movies_screen.dart';
import 'games/games_screen.dart';
import 'events/events_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    final screens = [
      const HomeScreen(),
      const VavooScreen(),
      const MoviesScreen(),
      const GamesScreen(),
      const EventsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(
              color: AppColors.bgCardLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: () => ref.read(navIndexProvider.notifier).state = 0,
                ),
                _NavItem(
                  icon: Icons.live_tv_rounded,
                  label: 'TV Direct',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: () => ref.read(navIndexProvider.notifier).state = 1,
                  hasLiveBadge: true,
                ),
                _NavItem(
                  icon: Icons.movie_creation_rounded,
                  label: 'Films',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: () => ref.read(navIndexProvider.notifier).state = 2,
                ),
                _NavItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'Jeux',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: () => ref.read(navIndexProvider.notifier).state = 3,
                ),
                _NavItem(
                  icon: Icons.event_rounded,
                  label: 'Événements',
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: () => ref.read(navIndexProvider.notifier).state = 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool hasLiveBadge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.hasLiveBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                if (hasLiveBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.live,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
