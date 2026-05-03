import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/subscription.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

// All events (from curated list + any remotely fetched)
final eventsProvider = Provider<List<LiveEvent>>((ref) {
  return SampleEvents.events;
});

// Live events only
final liveEventsProvider = Provider<List<LiveEvent>>((ref) {
  return ref.watch(eventsProvider).where((e) => e.isLive).toList();
});

// Upcoming events
final upcomingEventsProvider = Provider<List<LiveEvent>>((ref) {
  return ref.watch(eventsProvider).where((e) => e.isUpcoming).toList();
});

// Featured events
final featuredEventsProvider = Provider<List<LiveEvent>>((ref) {
  return ref.watch(eventsProvider).where((e) => e.isFeatured).toList();
});

// Selected event
final selectedEventProvider = StateProvider<LiveEvent?>((ref) => null);

// Event category filter
final eventCategoryProvider = StateProvider<String>((ref) => 'all');

// Filtered events by category
final filteredEventsProvider = Provider<List<LiveEvent>>((ref) {
  final category = ref.watch(eventCategoryProvider);
  final events = ref.watch(eventsProvider);
  if (category == 'all') return events;
  return events.where((e) => e.category == category).toList();
});

// Check if user has purchased a specific event
final eventAccessProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final service = ref.watch(paymentServiceProvider);
  return service.hasAccessToEvent(eventId);
});

// Subscription state
final subscriptionProvider = FutureProvider<Subscription>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getCurrentSubscription();
});

// Payment loading state
final paymentLoadingProvider = StateProvider<bool>((ref) => false);
