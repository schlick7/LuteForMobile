import 'dart:convert';
import 'package:hive_ce/hive.dart';

part 'term_cache_entry.g.dart';

@HiveType(typeId: 5)
class TermCacheEntry extends HiveObject {
  @HiveField(0)
  final int termId;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String? translation;

  @HiveField(3)
  final int statusId;

  @HiveField(4)
  final String statusText;

  @HiveField(5)
  final int languageId;

  @HiveField(6)
  final String languageName;

  @HiveField(7)
  final String? parentText;

  @HiveField(8)
  final String tags;

  @HiveField(9)
  final String createdAt;

  @HiveField(10)
  final String? romanization;

  @HiveField(11)
  final String? source;

  @HiveField(12)
  final int timestamp;

  @HiveField(13)
  final int sizeInBytes;

  TermCacheEntry({
    required this.termId,
    required this.text,
    this.translation,
    required this.statusId,
    required this.statusText,
    required this.languageId,
    required this.languageName,
    this.parentText,
    required this.tags,
    required this.createdAt,
    this.romanization,
    this.source,
    required this.timestamp,
    required this.sizeInBytes,
  });

  factory TermCacheEntry.fromServerJson(Map<String, dynamic> json) {
    final termJson = jsonEncode(json);
    final sizeInBytes = utf8.encode(termJson).length;

    return TermCacheEntry(
      termId: json['WoID'] as int,
      text: json['WoText'] as String,
      translation: json['WoTranslation'] as String?,
      statusId: json['StID'] as int,
      statusText: json['StText'] as String? ?? '',
      languageId: json['LgID'] as int,
      languageName: json['LgName'] as String? ?? '',
      parentText: json['ParentText'] as String?,
      tags: json['TagList'] as String? ?? '',
      createdAt: json['WoCreated'] as String? ?? '',
      romanization: json['WoRomanization'] as String?,
      source: json['WiSource'] as String?,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sizeInBytes: sizeInBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'termId': termId,
      'text': text,
      'translation': translation,
      'statusId': statusId,
      'statusText': statusText,
      'languageId': languageId,
      'languageName': languageName,
      'parentText': parentText,
      'tags': tags,
      'createdAt': createdAt,
      'romanization': romanization,
      'source': source,
      'cachedAt': DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      ).toIso8601String(),
    };
  }

  bool isExpired(Duration ttl) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    return age > ttl.inMilliseconds;
  }
}
