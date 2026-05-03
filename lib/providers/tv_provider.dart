import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../services/iptv_service.dart';

final iptvServiceProvider = Provider<IptvService>((ref) => IptvService());

// Selected TV category
final tvCategoryProvider = StateProvider<String>((ref) => 'all');

// TV search query
final tvSearchQueryProvider = StateProvider<String>((ref) => '');

// Load ALL channels from subscribed playlist ONCE and cache them
// This runs only once when the TV tab is first opened
final allSubscribedChannelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final service = ref.watch(iptvServiceProvider);
  final channels = await service.getAllChannels(category: 'all');
  return channels;
});

// Filter cached channels by selected category (instant, no extra network call)
final channelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final category = ref.watch(tvCategoryProvider);
  final allAsync = await ref.watch(allSubscribedChannelsProvider.future);

  if (category == 'all') return allAsync;

  final filtered = allAsync.where((c) => c.category == category).toList();
  return filtered.isNotEmpty ? filtered : allAsync;
});

// Filtered by search query on top of category filter
final filteredChannelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final query = ref.watch(tvSearchQueryProvider);
  final channels = await ref.watch(channelsProvider.future);

  if (query.isEmpty) return channels;
  return channels
      .where((ch) => ch.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

// Currently playing channel
final selectedChannelProvider = StateProvider<TvChannel?>((ref) => null);

// Featured channels for home screen (instant — curated, no loading)
final featuredChannelsProvider = Provider<List<TvChannel>>((ref) {
  final all = CuratedChannels.allChannels;
  final sports = all.where((c) => c.category == 'sports').take(4).toList();
  final others = all.where((c) => c.category != 'sports').take(4).toList();
  return [...sports, ...others];
});

// All curated channels (instant fallback)
final allChannelsProvider = Provider<List<TvChannel>>((ref) {
  return CuratedChannels.allChannels;
});
