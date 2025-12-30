import 'dart:convert';

class Book {
  final int id;
  final String title;
  final String language;
  final int langId;
  final int totalPages;
  final int currentPage;
  final int percent;
  final int wordCount;
  final int? distinctTerms;
  final double? unknownPct;
  final List<int>? statusDistribution;
  final List<String>? tags;
  final String? lastRead;
  final bool isCompleted;
  final String? audioFilename;

  bool get hasStats => distinctTerms != null && statusDistribution != null;
  bool get hasAudio => audioFilename != null && audioFilename!.isNotEmpty;

  Book({
    required this.id,
    required this.title,
    required this.language,
    this.langId = 0,
    required this.totalPages,
    required this.currentPage,
    required this.percent,
    required this.wordCount,
    required this.distinctTerms,
    required this.unknownPct,
    required this.statusDistribution,
    this.tags,
    this.lastRead,
    this.isCompleted = false,
    this.audioFilename,
  });

  String? get formattedLastRead {
    if (lastRead == null || lastRead!.isEmpty) return null;
    return _formatRelativeTime(lastRead!);
  }

  String _formatRelativeTime(String dateStr) {
    try {
      final now = DateTime.now();
      final date = DateTime.parse(dateStr).toLocal();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return '$mins minute${mins != 1 ? "s" : ""} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours hour${hours != 1 ? "s" : ""} ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days day${days != 1 ? "s" : ""} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks != 1 ? "s" : ""} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months != 1 ? "s" : ""} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years != 1 ? "s" : ""} ago';
      }
    } catch (e) {
      return '';
    }
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final isCompleted = json['IsCompleted'] == 1;
    final distinctCount = json['DistinctCount'];
    final unknownPercent = json['UnknownPercent'];
    final statusDist = json['StatusDistribution'];
    final tagList = json['TagList'];
    final lastOpened = json['LastOpenedDate'];
    final pageCount = json['PageCount'] as int;
    final pageNum = json['PageNum'] as int;
    final audioFilename = json['audio_filename'] as String?;

    List<int>? parsedStatusDist;
    if (statusDist is String && statusDist.isNotEmpty && statusDist != 'null') {
      parsedStatusDist = _parseStatusDist(statusDist);
    }

    List<String>? parsedTags;
    if (tagList is String && tagList.isNotEmpty && tagList != 'null') {
      parsedTags = tagList.split(',').map((t) => t.trim()).toList();
    }

    final percent = pageCount > 0 ? ((pageNum / pageCount) * 100).round() : 0;

    return Book(
      id: json['BkID'] as int,
      title: json['BkTitle'] as String,
      language: json['LgName'] as String,
      langId: 0,
      totalPages: pageCount,
      currentPage: pageNum,
      percent: percent,
      wordCount: json['WordCount'] as int,
      distinctTerms: (distinctCount is int) ? distinctCount : null,
      unknownPct: (unknownPercent is num) ? unknownPercent.toDouble() : null,
      statusDistribution: parsedStatusDist,
      tags: parsedTags,
      lastRead: (lastOpened is String && lastOpened.isNotEmpty)
          ? lastOpened
          : null,
      isCompleted: isCompleted,
      audioFilename: audioFilename,
    );
  }

  static List<int> _parseStatusDist(String dist) {
    if (dist.isEmpty || dist == 'null') {
      return List.generate(7, (i) => 0);
    }

    try {
      final dynamic parsed = jsonDecode(dist);
      if (parsed is! Map<String, dynamic>) {
        return List.generate(7, (i) => 0);
      }
      return [
        _getInt(parsed, '0'),
        _getInt(parsed, '1'),
        _getInt(parsed, '2'),
        _getInt(parsed, '3'),
        _getInt(parsed, '4'),
        _getInt(parsed, '5'),
        _getInt(parsed, '98'),
        _getInt(parsed, '99'),
      ];
    } catch (e) {
      return List.generate(7, (i) => 0);
    }
  }

  static int _getInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  String get pageProgress => '$currentPage/$totalPages';

  Book copyWith({
    int? id,
    String? title,
    String? language,
    int? langId,
    int? totalPages,
    int? currentPage,
    int? percent,
    int? wordCount,
    int? distinctTerms,
    double? unknownPct,
    List<int>? statusDistribution,
    List<String>? tags,
    String? lastRead,
    bool? isCompleted,
    String? audioFilename,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      langId: langId ?? this.langId,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      percent: percent ?? this.percent,
      wordCount: wordCount ?? this.wordCount,
      distinctTerms: distinctTerms ?? this.distinctTerms,
      unknownPct: unknownPct ?? this.unknownPct,
      statusDistribution: statusDistribution ?? this.statusDistribution,
      tags: tags ?? this.tags,
      lastRead: lastRead ?? this.lastRead,
      isCompleted: isCompleted ?? this.isCompleted,
      audioFilename: audioFilename ?? this.audioFilename,
    );
  }
}
