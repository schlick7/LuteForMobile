import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tooltip_cache_provider.dart';

// A simple provider that fetches cache stats
final cacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tooltipCacheService = ref.watch(tooltipCacheServiceProvider);
  return await tooltipCacheService.getCacheStats();
});
