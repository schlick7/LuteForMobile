import 'dart:convert';
import 'package:hive_ce/hive.dart';
import '../models/sentence_cache_entry.dart';
import '../utils/sentence_parser.dart';

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
      await Hive.openBox<SentenceCacheEntry>(_boxName);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing sentence cache: $e');
      _isInitialized = true;
    }
  }

  Future<Box<SentenceCacheEntry>> _getBox() async {
    await _initialize();
    return Hive.openBox<SentenceCacheEntry>(_boxName);
  }

  String _getCacheKey(
    String serverUrl,
    int bookId,
    int pageNum,
    int langId,
    int threshold,
  ) {
    return '$_cachePrefix${serverUrl.hashCode}_${bookId}_${pageNum}_${langId}_$threshold';
  }

  Future<List<CustomSentence>?> getFromCache(
    String serverUrl,
    int bookId,
    int pageNum,
    int langId,
    int threshold,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(
        serverUrl,
        bookId,
        pageNum,
        langId,
        threshold,
      );
      final entry = box.get(cacheKey);

      if (entry == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - entry.timestamp;

      if (age > _ttl.inMilliseconds) {
        await box.delete(cacheKey);
        return null;
      }

      return entry.sentences;
    } catch (e) {
      print('Error getting from sentence cache: $e');
      return null;
    }
  }

  Future<void> saveToCache(
    String serverUrl,
    int bookId,
    int pageNum,
    int langId,
    int threshold,
    List<CustomSentence> sentences,
  ) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(
        serverUrl,
        bookId,
        pageNum,
        langId,
        threshold,
      );

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
    } catch (e) {
      print('Error saving to sentence cache: $e');
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
      print('Error clearing book sentence cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      print('Error clearing all sentence cache: $e');
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
      print('Error enforcing size limit: $e');
    }
  }
}
