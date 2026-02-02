import 'package:hive_ce/hive.dart';
import 'dart:convert';
import 'language_stats.dart';

part 'stats_cache_entry.g.dart';

@HiveType(typeId: 1)
class StatsCacheEntry extends HiveObject {
  @HiveField(0)
  String statsJson;

  @HiveField(1)
  int timestamp;

  Map<String, LanguageReadingStats> get stats {
    try {
      final Map<String, dynamic> jsonMap =
          jsonDecode(statsJson) as Map<String, dynamic>;
      return jsonMap.map(
        (key, value) => MapEntry(
          key,
          LanguageReadingStats.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return {};
    }
  }

  StatsCacheEntry({
    required Map<String, LanguageReadingStats> stats,
    required this.timestamp,
  }) : statsJson = jsonEncode(
         stats.map((key, value) => MapEntry(key, value.toJson())),
       );

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
