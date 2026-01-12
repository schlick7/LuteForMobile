import 'dart:async';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'models/tooltip_cache_entry.dart';

class TooltipCacheService {
  static const String _boxName = 'tooltip_cache';
  static const Duration _ttl = Duration(hours: 48); // 48 hours TTL
  static const int _maxCacheSizeBytes = 200 * 1024 * 1024; // 200MB limit
  static const int _maxEntries =
      10000; // Maximum number of entries to prevent unlimited growth

  Box<TooltipCacheEntry>? _box;

  /// Initialize the Hive box for tooltip caching
  Future<void> initialize() async {
    try {
      // Register the adapter
      Hive.registerAdapter(TooltipCacheEntryAdapter());

      // Initialize Hive with Flutter
      await Hive.initFlutter();

      // Open the box
      _box = await Hive.openBox<TooltipCacheEntry>(_boxName);

      // Clean up expired entries on initialization
      await _cleanupExpiredEntries();

      print('Tooltip cache initialized successfully');
    } catch (e) {
      print('Error initializing tooltip cache: $e');
      rethrow;
    }
  }

  /// Get a tooltip from cache if it exists and hasn't expired
  Future<TooltipCacheEntry?> getFromCache(int wordId) async {
    try {
      if (_box == null) {
        print('Warning: Tooltip cache not initialized');
        return null;
      }

      final entry = _box!.get(wordId);

      if (entry == null) {
        return null;
      }

      // Check if entry has expired
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - entry.timestamp;
      final maxAge = _ttl.inMilliseconds;

      if (age > maxAge) {
        // Remove expired entry
        await _box!.delete(wordId);
        return null;
      }

      return entry;
    } catch (e) {
      print('Error getting from tooltip cache: $e');
      return null;
    }
  }

  /// Save a tooltip to cache
  Future<bool> saveToCache(int wordId, String tooltipHtml) async {
    try {
      if (_box == null) {
        print('Warning: Tooltip cache not initialized');
        return false;
      }

      // Calculate size of the tooltip HTML in bytes
      final sizeInBytes = utf8.encode(tooltipHtml).length;

      // Create new cache entry
      final entry = TooltipCacheEntry(
        wordId: wordId,
        tooltipHtml: tooltipHtml,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sizeInBytes: sizeInBytes,
      );

      // Check if we need to enforce size limits before saving
      await _enforceSizeLimits();

      // Save to box
      await _box!.put(wordId, entry);

      return true;
    } catch (e) {
      print('Error saving to tooltip cache: $e');
      return false;
    }
  }

  /// Bulk save multiple tooltips to cache
  Future<bool> bulkSaveToCache(Map<int, String> tooltips) async {
    try {
      if (_box == null) {
        print('Warning: Tooltip cache not initialized');
        return false;
      }

      // Check if we need to enforce size limits before saving
      await _enforceSizeLimits();

      // Prepare entries
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

      // Batch put all entries
      await _box!.putAll(entries);

      return true;
    } catch (e) {
      print('Error bulk saving to tooltip cache: $e');
      return false;
    }
  }

  /// Remove a specific tooltip from cache
  Future<bool> removeFromCache(int wordId) async {
    try {
      if (_box == null) {
        print('Warning: Tooltip cache not initialized');
        return false;
      }

      await _box!.delete(wordId);
      return true;
    } catch (e) {
      print('Error removing from tooltip cache: $e');
      return false;
    }
  }

  /// Clear all entries from the cache
  Future<bool> clearAllCache() async {
    try {
      if (_box == null) {
        print('Warning: Tooltip cache not initialized');
        return false;
      }

      await _box!.clear();
      return true;
    } catch (e) {
      print('Error clearing tooltip cache: $e');
      return false;
    }
  }

  /// Get statistics about the cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
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

  /// Clean up expired entries
  Future<void> _cleanupExpiredEntries() async {
    try {
      if (_box == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = _ttl.inMilliseconds;
      final expiredKeys = <int>[];

      // Find expired entries
      for (final key in _box!.keys) {
        final entry = _box!.get(key)!;
        final age = now - entry.timestamp;

        if (age > maxAge) {
          expiredKeys.add(key);
        }
      }

      // Remove expired entries
      if (expiredKeys.isNotEmpty) {
        await _box!.deleteAll(expiredKeys);
        print('Cleaned up ${expiredKeys.length} expired entries');
      }
    } catch (e) {
      print('Error cleaning up expired entries: $e');
    }
  }

  /// Enforce size limits using LRU eviction
  Future<void> _enforceSizeLimits() async {
    try {
      if (_box == null) return;

      // First, clean up expired entries
      await _cleanupExpiredEntries();

      // Calculate current size
      int currentSize = 0;
      final entriesWithTimestamps = <int, int>{}; // wordId -> timestamp

      for (final key in _box!.keys) {
        final entry = _box!.get(key)!;
        currentSize += entry.sizeInBytes;
        entriesWithTimestamps[key] = entry.timestamp;
      }

      // If we're over the size limit, evict LRU entries
      while (currentSize > _maxCacheSizeBytes || _box!.length > _maxEntries) {
        // Find the oldest entry (LRU)
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

        if (entriesWithTimestamps.isEmpty) break; // Safety check
      }
    } catch (e) {
      print('Error enforcing size limits: $e');
    }
  }

  /// Close the cache box
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
    } catch (e) {
      print('Error closing tooltip cache: $e');
    }
  }
}
