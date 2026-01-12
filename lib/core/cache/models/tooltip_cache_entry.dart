import 'package:hive_ce/hive.dart';

part 'tooltip_cache_entry.g.dart';

@HiveType(typeId: 0)
class TooltipCacheEntry extends HiveObject {
  @HiveField(0)
  final int wordId;

  @HiveField(1)
  final String tooltipHtml;

  @HiveField(2)
  final int timestamp;

  @HiveField(3)
  final int sizeInBytes;

  TooltipCacheEntry({
    required this.wordId,
    required this.tooltipHtml,
    required this.timestamp,
    required this.sizeInBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'tooltipHtml': tooltipHtml,
      'timestamp': timestamp,
      'sizeInBytes': sizeInBytes,
    };
  }

  factory TooltipCacheEntry.fromJson(Map<String, dynamic> json) {
    return TooltipCacheEntry(
      wordId: json['wordId'] as int,
      tooltipHtml: json['tooltipHtml'] as String,
      timestamp: json['timestamp'] as int,
      sizeInBytes: json['sizeInBytes'] as int,
    );
  }
}
