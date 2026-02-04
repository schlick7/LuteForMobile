import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sentence_cache_entry.dart';
import '../utils/sentence_parser.dart';
import '../../../core/cache/cache_logger.dart';

class SentenceCacheService {
  static const String _boxName = 'sentence_cache';
  static const Duration _ttl = Duration(days: 14);
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024;
  static const String _cachePrefix = 'sentence_cache_';

  Box<SentenceCacheEntry>? _box;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final cacheDir = await getApplicationCacheDirectory();
      await Hive.initFlutter(cacheDir.path);

      await Hive.openBox<SentenceCacheEntry>(_boxName);
      _isInitialized = true;
      CacheLogger.log('initialized');
    } catch (e) {
      CacheLogger.logError('initialize', e);
      _isInitialized = true;
    }
  }

  Future<Box<SentenceCacheEntry>> _getBox() async {
    await _initialize();
    return Hive.openBox<SentenceCacheEntry>(_boxName);
  }

  String _getCacheKey(int bookId, int pageNum, int langId, int threshold) {
    return '$_cachePrefix${bookId}_${pageNum}_${langId}_$threshold';
  }

  Future<List<CustomSentence>?> getFromCache(
    int bookId,
    int pageNum,
    int langId,
    int threshold,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(bookId, pageNum, langId, threshold);
      final entry = box.get(cacheKey);

      if (entry == null) {
        CacheLogger.logMiss(_boxName, cacheKey.hashCode);
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - entry.timestamp;

      if (age > _ttl.inMilliseconds) {
        await box.delete(cacheKey);
        CacheLogger.logMiss(_boxName, cacheKey.hashCode);
        return null;
      }

      CacheLogger.logHit(_boxName, cacheKey.hashCode);
      return entry.sentences;
    } catch (e) {
      CacheLogger.logError('getFromCache', e);
      return null;
    }
  }

  Future<void> saveToCache(
    int bookId,
    int pageNum,
    int langId,
    int threshold,
    List<CustomSentence> sentences,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(bookId, pageNum, langId, threshold);

      final sentencesJson = json.encode(
        sentences.map((s) => s.toJson()).toList(),
      );
      final sizeInBytes = utf8.encode(sentencesJson).length;

      final entry = SentenceCacheEntry(
        sentences: sentences,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sizeInBytes: sizeInBytes,
      );

      await _enforceSizeLimit(box);
      await box.put(cacheKey, entry);
      CacheLogger.logSave(_boxName, cacheKey.hashCode);
    } catch (e) {
      CacheLogger.logError('saveToCache', e);
    }
  }

  Future<void> clearBookCache(int bookId) async {
    try {
      final box = await _getBox();
      final keysToDelete = <String>[];

      for (final key in box.keys) {
        final keyStr = key as String;
        if (keyStr.startsWith('$_cachePrefix${bookId}_')) {
          keysToDelete.add(keyStr);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        CacheLogger.log(
          'cleared ${keysToDelete.length} entries for book $bookId',
        );
      }
    } catch (e) {
      CacheLogger.logError('clearBookCache', e);
    }
  }

  Future<void> clearAllCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      CacheLogger.logClear(_boxName);
    } catch (e) {
      CacheLogger.logError('clearAllCache', e);
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

  Future<void> _enforceSizeLimit(Box<SentenceCacheEntry> box) async {
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
      CacheLogger.logError('enforceSizeLimit', e);
    }
  }
}
