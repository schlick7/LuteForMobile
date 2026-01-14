import 'dart:convert';
import 'package:hive_ce/hive.dart';
import '../models/page_cache_entry.dart';

class PageCacheService {
  static const String _boxName = 'page_cache';
  static const Duration _ttl = Duration(days: 14);
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024;
  static const String _cachePrefix = 'page_cache_';

  Box<PageCacheEntry>? _box;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      Hive.registerAdapter(PageCacheEntryAdapter());
      await Hive.openBox<PageCacheEntry>(_boxName);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing page cache: $e');
      _isInitialized = true;
    }
  }

  Future<Box<PageCacheEntry>> _getBox() async {
    await _initialize();
    return Hive.openBox<PageCacheEntry>(_boxName);
  }

  String _getCacheKey(String serverUrl, int bookId, int pageNum) {
    return '$_cachePrefix${serverUrl.hashCode}_${bookId}_$pageNum';
  }

  Future<PageCacheEntry?> getFromCache(
    String serverUrl,
    int bookId,
    int pageNum,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(serverUrl, bookId, pageNum);
      final entry = box.get(cacheKey);

      if (entry == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - entry.timestamp;

      if (age > _ttl.inMilliseconds) {
        await box.delete(cacheKey);
        return null;
      }

      return entry;
    } catch (e) {
      print('Error getting from page cache: $e');
      return null;
    }
  }

  Future<void> saveToCache(
    String serverUrl,
    int bookId,
    int pageNum,
    String metadataHtml,
    String pageTextHtml,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(serverUrl, bookId, pageNum);

      final metadataBytes = utf8.encode(metadataHtml).length;
      final pageTextBytes = utf8.encode(pageTextHtml).length;
      final sizeInBytes = metadataBytes + pageTextBytes;

      final entry = PageCacheEntry(
        metadataHtml: metadataHtml,
        pageTextHtml: pageTextHtml,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sizeInBytes: sizeInBytes,
      );

      await _enforceSizeLimit(box);
      await box.put(cacheKey, entry);
    } catch (e) {
      print('Error saving to page cache: $e');
    }
  }

  Future<void> clearBookCache(String serverUrl, int bookId) async {
    try {
      final box = await _getBox();
      final serverHash = serverUrl.hashCode;
      final keysToDelete = <String>[];

      for (final key in box.keys) {
        final keyStr = key as String;
        if (keyStr.startsWith('$_cachePrefix${serverHash}_${bookId}_')) {
          keysToDelete.add(keyStr);
        }
      }

      await box.deleteAll(keysToDelete);
    } catch (e) {
      print('Error clearing book page cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      print('Error clearing all page cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final box = await _getBox();
      int totalSize = 0;
      int validEntries = 0;
      int expiredEntries = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in box.values) {
        totalSize += entry.sizeInBytes;
        final age = now - entry.timestamp;
        if (age > _ttl.inMilliseconds) {
          expiredEntries++;
        } else {
          validEntries++;
        }
      }

      return {
        'totalEntries': box.length,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'maxSizeMB': _maxCacheSizeBytes / (1024 * 1024),
        'ttlDays': _ttl.inDays,
        'isOverSizeLimit': totalSize > _maxCacheSizeBytes,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> _enforceSizeLimit(Box<PageCacheEntry> box) async {
    try {
      int currentSize = 0;
      final entriesWithTimestamps = <String, int>{};

      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry != null) {
          currentSize += entry.sizeInBytes;
          entriesWithTimestamps[key as String] = entry.timestamp;
        }
      }

      if (entriesWithTimestamps.isEmpty) return;

      while (currentSize > _maxCacheSizeBytes &&
          entriesWithTimestamps.isNotEmpty) {
        final oldestKey = entriesWithTimestamps.keys.reduce(
          (a, b) =>
              entriesWithTimestamps[a]! < entriesWithTimestamps[b]! ? a : b,
        );

        final oldestEntry = box.get(oldestKey);
        if (oldestEntry != null) {
          currentSize -= oldestEntry.sizeInBytes;
        }

        await box.delete(oldestKey);
        entriesWithTimestamps.remove(oldestKey);
      }
    } catch (e) {
      print('Error enforcing size limit: $e');
    }
  }
}
