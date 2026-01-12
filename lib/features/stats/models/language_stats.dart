import 'package:flutter/foundation.dart';
import 'stats_data.dart';

@immutable
class LanguageReadingStats {
  final String language;
  final List<DailyReadingStats> dailyStats;

  const LanguageReadingStats({
    required this.language,
    required this.dailyStats,
  });

  int get totalWords => dailyStats.isEmpty ? 0 : dailyStats.last.runningTotal;

  int get totalDays => dailyStats.length;

  DateTime? get firstDate => dailyStats.isEmpty ? null : dailyStats.first.date;

  DateTime? get lastDate => dailyStats.isEmpty ? null : dailyStats.last.date;

  factory LanguageReadingStats.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as String;
    final List<dynamic> statsList = json['dailyStats'] as List<dynamic>;
    final dailyStats = statsList
        .map((e) => DailyReadingStats.fromJson(e as Map<String, dynamic>))
        .toList();

    return LanguageReadingStats(language: language, dailyStats: dailyStats);
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
    };
  }

  LanguageReadingStats copyWith({
    String? language,
    List<DailyReadingStats>? dailyStats,
  }) {
    return LanguageReadingStats(
      language: language ?? this.language,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }
}
