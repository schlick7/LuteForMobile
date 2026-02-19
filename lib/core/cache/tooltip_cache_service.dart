import 'dart:async';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'models/tooltip_cache_entry.dart';
import 'cache_logger.dart';

class TooltipCacheService {
  static const String _boxName = 'tooltip_cache';
  static const Duration _ttl = Duration(days: 14);
  static const int _maxCacheSizeBytes = 200 * 1024 * 1024;
  static const int _maxEntries = 10000;

  Box<TooltipCacheEntry>? _box;
  bool _isInitialized = false;

  static TooltipCacheService? _instance;

  static TooltipCacheService getInstance() {
    _instance ??= TooltipCacheService._internal();
    return _instance!;
  }

  TooltipCacheService._internal();

  factory TooltipCacheService() {
    return getInstance();
  }

  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        _box = await Hive.openBox<TooltipCacheEntry>(_boxName);

        await _cleanupExpiredEntries();

        _isInitialized = true;
        CacheLogger.log('initialized (entries: ${_box!.length})');
      }
    } catch (e) {
      CacheLogger.logError('initialize', e);
      rethrow;
    }
  }

  Future<TooltipCacheEntry?> getFromCache(int wordId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        CacheLogger.log('not initialized');
        return null;
      }

      final entry = _box!.get(wordId);

      if (entry == null) {
        CacheLogger.logMiss(_boxName, wordId);
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - entry.timestamp;
      final maxAge = _ttl.inMilliseconds;

      if (age > maxAge) {
        await _box!.delete(wordId);
        CacheLogger.logMiss(_boxName, wordId);
        return null;
      }

      CacheLogger.logHit(_boxName, wordId);
      return entry;
    } catch (e) {
      CacheLogger.logError('getFromCache', e);
      return null;
    }
  }

  Future<bool> saveToCache(int wordId, String tooltipHtml) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        CacheLogger.log('not initialized');
        return false;
      }

      final sizeInBytes = utf8.encode(tooltipHtml).length;

      final entry = TooltipCacheEntry(
        wordId: wordId,
        tooltipHtml: tooltipHtml,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sizeInBytes: sizeInBytes,
      );

      await _enforceSizeLimits();

      await _box!.put(wordId, entry);

      CacheLogger.logSave(_boxName, wordId);
      return true;
    } catch (e) {
      CacheLogger.logError('saveToCache', e);
      return false;
    }
  }

  Future<bool> bulkSaveToCache(Map<int, String> tooltips) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        CacheLogger.log('not initialized');
        return false;
      }

      await _enforceSizeLimits();

      final entries = <int, TooltipCacheEntry>{};
      for (final entry in tooltips.entries) {
        final sizeInBytes = utf8.encode(entry.value).length;
        entries[entry.key] = TooltipCacheEntry(
          wordId: entry.key,
          tooltipHtml: entry.value,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          sizeInBytes: sizeInBytes,
        );
      }

      await _box!.putAll(entries);

      CacheLogger.log('bulk saved ${entries.length} entries');
      return true;
    } catch (e) {
      CacheLogger.logError('bulkSaveToCache', e);
      return false;
    }
  }

  Future<bool> removeFromCache(int wordId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        CacheLogger.log('not initialized');
        return false;
      }

      await _box!.delete(wordId);
      return true;
    } catch (e) {
      CacheLogger.logError('removeFromCache', e);
      return false;
    }
  }

  Future<bool> clearAllCache() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        CacheLogger.log('not initialized');
        return false;
      }

      await _box!.clear();
      CacheLogger.logClear(_boxName);
      return true;
    } catch (e) {
      CacheLogger.logError('clearAllCache', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        return {'error': 'Cache not initialized'};
      }

      final entries = _box!.values.toList();
      int totalSize = 0;
      int validEntries = 0;
      int expiredEntries = 0;
      int totalEntries = entries.length;

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = _ttl.inMilliseconds;

      for (final entry in entries) {
        totalSize += entry.sizeInBytes;
        final age = now - entry.timestamp;

        if (age > maxAge) {
          expiredEntries++;
        } else {
          validEntries++;
        }
      }

      return {
        'totalEntries': totalEntries,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'maxSizeMB': _maxCacheSizeBytes / (1024 * 1024),
        'ttlHours': _ttl.inHours,
        'isOverSizeLimit': totalSize > _maxCacheSizeBytes,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    try {
      if (_box == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = _ttl.inMilliseconds;
      final expiredKeys = <int>[];

      for (final key in _box!.keys) {
        final entry = _box!.get(key)!;
        final age = now - entry.timestamp;

        if (age > maxAge) {
          expiredKeys.add(key);
        }
      }

      if (expiredKeys.isNotEmpty) {
        await _box!.deleteAll(expiredKeys);
        CacheLogger.log('cleaned up ${expiredKeys.length} expired entries');
      }
    } catch (e) {
      CacheLogger.logError('cleanupExpiredEntries', e);
    }
  }

  Future<void> _enforceSizeLimits() async {
    try {
      if (_box == null) return;

      await _cleanupExpiredEntries();

      int currentSize = 0;
      final entriesWithTimestamps = <int, int>{};

      for (final key in _box!.keys) {
        final entry = _box!.get(key)!;
        currentSize += entry.sizeInBytes;
        entriesWithTimestamps[key] = entry.timestamp;
      }

      while (currentSize > _maxCacheSizeBytes || _box!.length > _maxEntries) {
        final oldestKey = entriesWithTimestamps.keys.reduce(
          (a, b) =>
              entriesWithTimestamps[a]! < entriesWithTimestamps[b]! ? a : b,
        );

        final oldestEntry = _box!.get(oldestKey);
        if (oldestEntry != null) {
          currentSize -= oldestEntry.sizeInBytes;
        }

        await _box!.delete(oldestKey);
        entriesWithTimestamps.remove(oldestKey);

        if (entriesWithTimestamps.isEmpty) break;
      }
    } catch (e) {
      CacheLogger.logError('enforceSizeLimits', e);
    }
  }

  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
      _isInitialized = false;
    } catch (e) {
      CacheLogger.logError('close', e);
    }
  }
}
