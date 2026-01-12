import 'package:flutter/foundation.dart';

@immutable
class DailyReadingStats {
  final DateTime date;
  final int wordcount;
  final int runningTotal;

  const DailyReadingStats({
    required this.date,
    required this.wordcount,
    required this.runningTotal,
  });

  factory DailyReadingStats.fromJson(Map<String, dynamic> json) {
    return DailyReadingStats(
      date: DateTime.parse(json['readdate'] as String),
      wordcount: json['wordcount'] as int? ?? 0,
      runningTotal: json['runningTotal'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'readdate': date.toIso8601String().split('T').first,
      'wordcount': wordcount,
      'runningTotal': runningTotal,
    };
  }

  DailyReadingStats copyWith({
    DateTime? date,
    int? wordcount,
    int? runningTotal,
  }) {
    return DailyReadingStats(
      date: date ?? this.date,
      wordcount: wordcount ?? this.wordcount,
      runningTotal: runningTotal ?? this.runningTotal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyReadingStats &&
        other.date == date &&
        other.wordcount == wordcount &&
        other.runningTotal == runningTotal;
  }

  @override
  int get hashCode => Object.hash(date, wordcount, runningTotal);
}
