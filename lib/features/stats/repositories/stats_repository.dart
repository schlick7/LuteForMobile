import 'package:hive_ce/hive.dart';
import 'package:lute_for_mobile/core/network/content_service.dart';
import 'package:lute_for_mobile/features/stats/models/stats_cache_entry.dart';
import 'package:lute_for_mobile/features/stats/models/language_stats.dart';
import 'package:lute_for_mobile/features/stats/models/stats_data.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/cache/cache_logger.dart';

class StatsRepository {
  static const String _boxName = 'stats';
  static const String _cacheKey = 'all';

  static Box<StatsCacheEntry>? _box;

  static Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      final cacheDir = await getApplicationCacheDirectory();
      await Hive.initFlutter(cacheDir.path);

      _box = await Hive.openBox<StatsCacheEntry>(_boxName);
      CacheLogger.log('initialized');
    }
  }

  static Box<StatsCacheEntry> _getBox() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'StatsRepository not initialized. Call initialize() first.',
      );
    }
    return _box!;
  }

  static Future<StatsCacheEntry?> _getCachedStats() async {
    try {
      final entry = _getBox().get(_cacheKey);
      if (entry != null) {
        CacheLogger.logHit(_boxName, _cacheKey.hashCode);
      } else {
        CacheLogger.logMiss(_boxName, _cacheKey.hashCode);
      }
      return entry;
    } catch (e) {
      CacheLogger.logError('getCachedStats', e);
      return null;
    }
  }

  static Future<void> _saveToCache(StatsCacheEntry entry) async {
    try {
      await _getBox().put(_cacheKey, entry);
      CacheLogger.logSave(_boxName, _cacheKey.hashCode);
    } catch (e) {
      CacheLogger.logError('saveToCache', e);
    }
  }

  static Future<void> clearCache() async {
    try {
      await _getBox().clear();
      CacheLogger.logClear(_boxName);
    } catch (e) {
      CacheLogger.logError('clearCache', e);
    }
  }

  static Future<StatsCacheEntry> fetchAndProcessStats({
    required ContentService contentService,
  }) async {
    final serverData = await contentService.getStatsData();
    final cached = await _getCachedStats();

    final mergedStats = <String, LanguageReadingStats>{};

    final allLanguages = <String>{};
    for (final entry in serverData.entries) {
      allLanguages.add(entry.key);
    }
    if (cached != null) {
      allLanguages.addAll(cached.stats.keys);
    }

    for (final language in allLanguages) {
      final serverLanguageData =
          (serverData[language] as List<dynamic>?)
              ?.map(
                (e) => DailyReadingStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final cachedLanguageStats = cached?.stats[language];
      final cachedLanguageData = cachedLanguageStats?.dailyStats ?? [];

      final mergedLanguageData = <DailyReadingStats>{};
      final serverDates = <DateTime>{};
      for (final stat in serverLanguageData) {
        mergedLanguageData.add(stat);
        serverDates.add(stat.date);
      }
      for (final stat in cachedLanguageData) {
        if (!serverDates.contains(stat.date)) {
          mergedLanguageData.add(stat);
        }
      }

      final sortedMerged = mergedLanguageData.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final filledStats = _fillGaps(sortedMerged);

      mergedStats[language] = LanguageReadingStats(
        language: language,
        dailyStats: filledStats,
      );
    }

    final entry = StatsCacheEntry(
      stats: mergedStats,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _saveToCache(entry);

    return entry;
  }

  static List<DailyReadingStats> _fillGaps(List<DailyReadingStats> sortedData) {
    if (sortedData.isEmpty) return [];

    final firstDate = sortedData.first.date;
    final lastDate = DateTime.now();

    final filledStats = <DailyReadingStats>[];
    var previousRunningTotal = 0;

    var current = firstDate;
    var dataIndex = 0;

    while (!current.isAfter(lastDate)) {
      if (dataIndex < sortedData.length &&
          sortedData[dataIndex].date == current) {
        final stats = sortedData[dataIndex];
        previousRunningTotal = stats.runningTotal;
        filledStats.add(stats);
        dataIndex++;
      } else {
        filledStats.add(
          DailyReadingStats(
            date: current,
            wordcount: 0,
            runningTotal: previousRunningTotal,
          ),
        );
      }
      current = DateTime(current.year, current.month, current.day + 1);
    }

    return filledStats;
  }
}
