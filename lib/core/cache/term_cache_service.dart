import 'package:hive_ce/hive.dart';
import 'models/term_cache_entry.dart';
import 'cache_logger.dart';

class TermCacheService {
  static const String _boxName = 'term_cache';
  static const Duration _ttl = Duration(days: 7);
  static const int _maxCacheSizeBytes = 200 * 1024 * 1024;
  static const int _maxEntries = 500000;

  Box<TermCacheEntry>? _box;
  bool _isInitialized = false;

  TermCacheService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox<TermCacheEntry>(_boxName);
      _isInitialized = true;
      CacheLogger.log('initialized');
    } catch (e) {
      CacheLogger.logError('initialize', e);
      rethrow;
    }
  }

  Future<Box<TermCacheEntry>> _getBox() async {
    if (!_isInitialized) {
      await initialize();
    }
    return Hive.openBox<TermCacheEntry>(_boxName);
  }

  Future<TermCacheEntry?> getTerm(int termId) async {
    try {
      final box = await _getBox();
      final entry = box.get(termId);

      if (entry == null) {
        CacheLogger.logMiss(_boxName, termId);
        return null;
      }

      if (entry.isExpired(_ttl)) {
        await box.delete(termId);
        CacheLogger.logMiss(_boxName, termId);
        return null;
      }

      CacheLogger.logHit(_boxName, termId);
      return entry;
    } catch (e) {
      CacheLogger.logError('getTerm', e);
      return null;
    }
  }

  Future<List<TermCacheEntry>> getAllTerms() async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      final validEntries = <TermCacheEntry>[];

      for (final entry in box.values) {
        final age = now - entry.timestamp;
        if (age <= _ttl.inMilliseconds) {
          validEntries.add(entry);
        }
      }

      return validEntries;
    } catch (e) {
      CacheLogger.logError('getAllTerms', e);
      return [];
    }
  }

  Future<List<TermCacheEntry>> getTermsByLanguage(int languageId) async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      final validEntries = <TermCacheEntry>[];

      for (final entry in box.values) {
        final age = now - entry.timestamp;
        if (age <= _ttl.inMilliseconds && entry.languageId == languageId) {
          validEntries.add(entry);
        }
      }

      return validEntries;
    } catch (e) {
      CacheLogger.logError('getTermsByLanguage', e);
      return [];
    }
  }

  Future<List<TermCacheEntry>> searchTerms(String query) async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lowerQuery = query.toLowerCase();
      final validEntries = <TermCacheEntry>[];

      for (final entry in box.values) {
        final age = now - entry.timestamp;
        if (age <= _ttl.inMilliseconds) {
          if (entry.text.toLowerCase().contains(lowerQuery) ||
              (entry.translation?.toLowerCase().contains(lowerQuery) ??
                  false)) {
            validEntries.add(entry);
          }
        }
      }

      return validEntries;
    } catch (e) {
      CacheLogger.logError('searchTerms', e);
      return [];
    }
  }

  Future<bool> saveTerm(TermCacheEntry entry) async {
    try {
      final box = await _getBox();
      await _enforceSizeLimit(box);
      await box.put(entry.termId, entry);
      CacheLogger.logSave(_boxName, entry.termId);
      return true;
    } catch (e) {
      CacheLogger.logError('saveTerm', e);
      return false;
    }
  }

  Future<bool> saveTerms(List<TermCacheEntry> entries) async {
    try {
      if (entries.isEmpty) return true;

      final box = await _getBox();
      await _enforceSizeLimit(box);

      final entriesMap = {for (final e in entries) e.termId: e};
      await box.putAll(entriesMap);
      CacheLogger.log('bulk saved ${entries.length} terms');
      return true;
    } catch (e) {
      CacheLogger.logError('saveTerms', e);
      return false;
    }
  }

  Future<bool> removeTerm(int termId) async {
    try {
      final box = await _getBox();
      await box.delete(termId);
      return true;
    } catch (e) {
      CacheLogger.logError('removeTerm', e);
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
      CacheLogger.logClear(_boxName);
      return true;
    } catch (e) {
      CacheLogger.logError('clearAll', e);
      return false;
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
        'maxEntries': _maxEntries,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<int> getTermCount() async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      int count = 0;

      for (final entry in box.values) {
        final age = now - entry.timestamp;
        if (age <= _ttl.inMilliseconds) {
          count++;
        }
      }

      return count;
    } catch (e) {
      CacheLogger.logError('getTermCount', e);
      return 0;
    }
  }

  Future<void> _enforceSizeLimit(Box<TermCacheEntry> box) async {
    try {
      int currentSize = 0;
      final entriesWithTimestamps = <int, int>{};

      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry != null) {
          currentSize += entry.sizeInBytes;
          entriesWithTimestamps[key as int] = entry.timestamp;
        }
      }

      if (entriesWithTimestamps.isEmpty) return;

      while ((currentSize > _maxCacheSizeBytes || box.length > _maxEntries) &&
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
