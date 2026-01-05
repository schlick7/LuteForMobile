import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CachedPageHtml {
  final String metadataHtml;
  final String pageTextHtml;
  final int timestamp;

  CachedPageHtml({
    required this.metadataHtml,
    required this.pageTextHtml,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'metadataHtml': metadataHtml,
      'pageTextHtml': pageTextHtml,
      'timestamp': timestamp,
    };
  }

  factory CachedPageHtml.fromJson(Map<String, dynamic> json) {
    return CachedPageHtml(
      metadataHtml: json['metadataHtml'] as String,
      pageTextHtml: json['pageTextHtml'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

class PageCacheService {
  static const int _cacheExpirationHours = 24;
  static const int _maxCacheSize = 20;
  static const String _cachePrefix = 'page_cache_';
  static const String _lruKey = 'page_cache_lru';

  Future<CachedPageHtml?> getFromCache(int bookId, int pageNum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(bookId, pageNum);
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final cacheData = json.decode(cachedJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      final maxAge = _cacheExpirationHours * 60 * 60 * 1000;

      if (age > maxAge) {
        await _removeFromCache(bookId, pageNum);
        return null;
      }

      return CachedPageHtml.fromJson(cacheData);
    } catch (e) {
      print('Error getting from page cache: $e');
      return null;
    }
  }

  Future<void> saveToCache(
    int bookId,
    int pageNum,
    String metadataHtml,
    String pageTextHtml,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _enforceCacheLimit(prefs);

      final cacheKey = _getCacheKey(bookId, pageNum);
      final cachedPage = CachedPageHtml(
        metadataHtml: metadataHtml,
        pageTextHtml: pageTextHtml,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await prefs.setString(cacheKey, json.encode(cachedPage.toJson()));
      await _updateLru(prefs, cacheKey);
    } catch (e) {
      print('Error saving to page cache: $e');
    }
  }

  Future<void> clearBookCache(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lruList = prefs.getStringList(_lruKey) ?? [];

      for (final cacheKey in List.from(lruList)) {
        if (cacheKey.startsWith('$_cachePrefix${bookId}_')) {
          await prefs.remove(cacheKey);
          lruList.remove(cacheKey);
        }
      }

      await prefs.setStringList(_lruKey, lruList);
    } catch (e) {
      print('Error clearing book page cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      await prefs.remove(_lruKey);
    } catch (e) {
      print('Error clearing all page cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lruList = prefs.getStringList(_lruKey) ?? [];

      int validEntries = 0;
      int expiredEntries = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = _cacheExpirationHours * 60 * 60 * 1000;

      for (final cacheKey in lruList) {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          try {
            final cacheData = json.decode(cachedJson) as Map<String, dynamic>;
            final timestamp = cacheData['timestamp'] as int;
            final age = now - timestamp;

            if (age > maxAge) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }

      return {
        'totalEntries': lruList.length,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'maxSize': _maxCacheSize,
        'expirationHours': _cacheExpirationHours,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  String _getCacheKey(int bookId, int pageNum) {
    return '$_cachePrefix${bookId}_$pageNum';
  }

  Future<void> _updateLru(SharedPreferences prefs, String cacheKey) async {
    final lruList = prefs.getStringList(_lruKey) ?? [];
    lruList.remove(cacheKey);
    lruList.add(cacheKey);
    await prefs.setStringList(_lruKey, lruList);
  }

  Future<void> _removeFromCache(int bookId, int pageNum) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getCacheKey(bookId, pageNum);
    await prefs.remove(cacheKey);

    final lruList = prefs.getStringList(_lruKey) ?? [];
    lruList.remove(cacheKey);
    await prefs.setStringList(_lruKey, lruList);
  }

  Future<void> _enforceCacheLimit(SharedPreferences prefs) async {
    final lruList = prefs.getStringList(_lruKey) ?? [];

    while (lruList.length >= _maxCacheSize) {
      final oldestKey = lruList.removeAt(0);
      await prefs.remove(oldestKey);
    }

    await prefs.setStringList(_lruKey, lruList);
  }
}
