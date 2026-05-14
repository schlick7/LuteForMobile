import 'books_cache_service.dart';
import 'term_cache_service.dart';
import 'tooltip_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/reader/services/page_cache_service.dart';
import '../../features/reader/services/sentence_cache_service.dart';
import '../../features/stats/repositories/stats_repository.dart';

class CacheManager {
  final BooksCacheService _booksCache;
  final TermCacheService _termCache;
  final TooltipCacheService _tooltipCache;
  final PageCacheService _pageCache;
  final SentenceCacheService _sentenceCache;
  final StatsRepository _statsRepository;

  CacheManager({
    required BooksCacheService booksCache,
    required TermCacheService termCache,
    required TooltipCacheService tooltipCache,
    required PageCacheService pageCache,
    required SentenceCacheService sentenceCache,
    required StatsRepository statsRepository,
  }) : _booksCache = booksCache,
       _termCache = termCache,
       _tooltipCache = tooltipCache,
       _pageCache = pageCache,
       _sentenceCache = sentenceCache,
       _statsRepository = statsRepository;

  Future<void> clearAllCaches() async {
    await Future.wait([
      _booksCache.clearAll(),
      _termCache.clearAll(),
      _tooltipCache.clearAllCache(),
      _pageCache.clearAllCache(),
      _sentenceCache.clearAllCache(),
      _statsRepository.clearCache(),
      clearDictionaryPreferences(),
    ]);
  }

  Future<void> clearServerDependentCaches() async {
    await Future.wait([
      _booksCache.clearAll(),
      _termCache.clearAll(),
      _tooltipCache.clearAllCache(),
      _pageCache.clearAllCache(),
      _sentenceCache.clearAllCache(),
      _statsRepository.clearCache(),
      clearDictionaryPreferences(),
    ]);
  }

  Future<void> clearDictionaryPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dictionaryKeys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('dictionaries_') ||
              key.startsWith('sentence_dictionaries_'),
        )
        .toList();

    await Future.wait(dictionaryKeys.map(prefs.remove));
  }
}
