import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../term_cache_service.dart';

final termCacheServiceProvider = Provider<TermCacheService>((ref) {
  return TermCacheService();
});

final termCacheStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final cacheService = ref.watch(termCacheServiceProvider);
  return await cacheService.getCacheStats();
});

final termCacheCountProvider = FutureProvider<int>((ref) async {
  final cacheService = ref.watch(termCacheServiceProvider);
  return await cacheService.getTermCount();
});
