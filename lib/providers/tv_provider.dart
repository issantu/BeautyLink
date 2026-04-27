import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../services/iptv_service.dart';

final iptvServiceProvider = Provider<IptvService>((ref) => IptvService());

// Selected TV category
final tvCategoryProvider = StateProvider<String>((ref) => 'all');

// Channels by category using curated list (fast, no API call)
final channelsProvider = Provider.family<List<TvChannel>, String>((ref, category) {
  final service = ref.watch(iptvServiceProvider);
  return service.getCuratedChannels(category);
});

// Currently selected/playing channel
final selectedChannelProvider = StateProvider<TvChannel?>((ref) => null);

// TV search query
final tvSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered channels based on search
final filteredChannelsProvider = Provider<List<TvChannel>>((ref) {
  final category = ref.watch(tvCategoryProvider);
  final query = ref.watch(tvSearchQueryProvider);
  final service = ref.watch(iptvServiceProvider);

  final channels = service.getCuratedChannels(category);

  if (query.isEmpty) return channels;
  return channels
      .where((ch) => ch.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

// All channels flat list
final allChannelsProvider = Provider<List<TvChannel>>((ref) {
  return CuratedChannels.allChannels;
});

// Featured channels (for home screen)
final featuredChannelsProvider = Provider<List<TvChannel>>((ref) {
  final all = CuratedChannels.allChannels;
  // Show sport channels first, then others
  final sports = all.where((c) => c.category == 'sports').take(4).toList();
  final others = all.where((c) => c.category != 'sports').take(4).toList();
  return [...sports, ...others];
});
