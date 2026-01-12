import 'package:hive_ce/hive.dart';
import 'language_stats.dart';

part 'stats_cache_entry.g.dart';

@HiveType(typeId: 1)
class StatsCacheEntry extends HiveObject {
  @HiveField(0)
  final Map<String, LanguageReadingStats> stats;

  @HiveField(1)
  final int timestamp;

  StatsCacheEntry({required this.stats, required this.timestamp});

  StatsCacheEntry copyWith({
    Map<String, LanguageReadingStats>? stats,
    int? timestamp,
  }) {
    return StatsCacheEntry(
      stats: stats ?? this.stats,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
