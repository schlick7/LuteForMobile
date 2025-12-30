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
  final int distinctTerms;
  final double unknownPct;
  final List<int> statusDistribution;

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
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final isCompleted = json['IsCompleted'];
    final distinctCount = json['DistinctCount'];
    final unknownPercent = json['UnknownPercent'];
    final statusDist = json['StatusDistribution'];

    return Book(
      id: json['BkID'] as int,
      title: json['BkTitle'] as String,
      language: json['LgName'] as String,
      langId: 0,
      totalPages: json['PageCount'] as int,
      currentPage: json['PageNum'] as int,
      percent: ((isCompleted is int ? isCompleted : 0) * 100),
      wordCount: json['WordCount'] as int,
      distinctTerms: (distinctCount is int) ? distinctCount : 0,
      unknownPct: (unknownPercent is num) ? unknownPercent.toDouble() : 0.0,
      statusDistribution: _parseStatusDist(
        (statusDist is String) ? statusDist : '',
      ),
    );
  }

  static List<int> _parseStatusDist(String dist) {
    if (dist.isEmpty) {
      return List.generate(6, (i) => 0);
    }

    try {
      final Map<String, dynamic> parsed = jsonDecode(dist);
      return [
        _getInt(parsed, '0'),
        _getInt(parsed, '1'),
        _getInt(parsed, '2'),
        _getInt(parsed, '3'),
        _getInt(parsed, '4'),
        _getInt(parsed, '5'),
      ];
    } catch (e) {
      return List.generate(6, (i) => 0);
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
    );
  }
}
