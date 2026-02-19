import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache_manager.dart';
import 'books_cache_provider.dart';
import 'term_cache_provider.dart';
import 'tooltip_cache_provider.dart';
import 'page_cache_provider.dart';
import '../../../features/reader/providers/sentence_reader_provider.dart';

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(
    booksCache: ref.watch(booksCacheServiceProvider),
    termCache: ref.watch(termCacheServiceProvider),
    tooltipCache: ref.watch(tooltipCacheServiceProvider),
    pageCache: ref.watch(pageCacheServiceProvider),
    sentenceCache: ref.watch(sentenceCacheServiceProvider),
  );
});
