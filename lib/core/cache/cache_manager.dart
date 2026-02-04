import 'books_cache_service.dart';
import 'term_cache_service.dart';
import 'tooltip_cache_service.dart';
import '../../features/reader/services/page_cache_service.dart';
import '../../features/reader/services/sentence_cache_service.dart';

class CacheManager {
  static CacheManager? _instance;
  final BooksCacheService _booksCache;
  final TermCacheService _termCache;
  final TooltipCacheService _tooltipCache;
  final PageCacheService _pageCache;
  final SentenceCacheService _sentenceCache;

  CacheManager._internal()
    : _booksCache = BooksCacheService.getInstance(),
      _termCache = TermCacheService.getInstance(),
      _tooltipCache = TooltipCacheService.getInstance(),
      _pageCache = PageCacheService(),
      _sentenceCache = SentenceCacheService();

  factory CacheManager() {
    _instance ??= CacheManager._internal();
    return _instance!;
  }

  Future<void> clearAllCaches() async {
    await Future.wait([
      _booksCache.clearAll(),
      _termCache.clearAll(),
      _tooltipCache.clearAllCache(),
      _pageCache.clearAllCache(),
      _sentenceCache.clearAllCache(),
    ]);
  }

  Future<void> clearServerDependentCaches() async {
    await Future.wait([
      _booksCache.clearAll(),
      _termCache.clearAll(),
      _tooltipCache.clearAllCache(),
      _pageCache.clearAllCache(),
      _sentenceCache.clearAllCache(),
    ]);
  }
}
