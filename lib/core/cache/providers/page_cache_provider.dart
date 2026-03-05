import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/reader/services/page_cache_service.dart';

final pageCacheServiceProvider = Provider<PageCacheService>((ref) {
  return PageCacheService();
});
