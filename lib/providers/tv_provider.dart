import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../services/iptv_service.dart';

final iptvServiceProvider = Provider<IptvService>((ref) => IptvService());

// Selected TV category
final tvCategoryProvider = StateProvider<String>((ref) => 'all');

// TV search query
final tvSearchQueryProvider = StateProvider<String>((ref) => '');

// Dynamic channels loaded from M3U playlists (async)
final dynamicChannelsProvider =
    FutureProvider.family<List<TvChannel>, String>((ref, category) async {
  final service = ref.watch(iptvServiceProvider);
  final channels = await service.getAllChannels(category: category);
  if (channels.isEmpty) return service.getCuratedChannels(category);
  return channels;
});

// Channels for current selected category
final channelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final category = ref.watch(tvCategoryProvider);
  final service = ref.watch(iptvServiceProvider);
  final channels = await service.getAllChannels(category: category);
  if (channels.isEmpty) return service.getCuratedChannels(category);
  return channels;
});

// Filtered channels based on search + category
final filteredChannelsProvider = FutureProvider<List<TvChannel>>((ref) async {
  final query = ref.watch(tvSearchQueryProvider);
  final channels = await ref.watch(channelsProvider.future);
  if (query.isEmpty) return channels;
  return channels
      .where((ch) => ch.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

// Currently selected/playing channel
final selectedChannelProvider = StateProvider<TvChannel?>((ref) => null);

// Featured channels for home screen (curated, instant — no loading)
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
