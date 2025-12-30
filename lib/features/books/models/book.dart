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
    this.distinctTerms,
    required this.unknownPct,
    required this.statusDistribution,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['BkID'] as int,
      title: json['BkTitle'] as String,
      language: json['LgName'] as String,
      langId: json['LgID'] as int? ?? 0,
      totalPages: json['PageCount'] as int,
      currentPage: json['PageNum'] as int,
      percent: ((json['IsCompleted'] as int? ?? 0) * 100),
      wordCount: json['WordCount'] as int,
      distinctTerms: json['DistinctCount'] as int?,
      unknownPct: (json['UnknownPercent'] as num?)?.toDouble() ?? 0.0,
      statusDistribution: _parseStatusDist(
        json['StatusDistribution'] as String? ?? '',
      ),
    );
  }

  static List<int> _parseStatusDist(String dist) {
    if (dist.isEmpty) {
      return List.generate(6, (i) => 0);
    }

    try {
      final Map<String, dynamic> parsed = json.decode(dist);
      return [
        parsed['0'] as int? ?? 0,
        parsed['1'] as int? ?? 0,
        parsed['2'] as int? ?? 0,
        parsed['3'] as int? ?? 0,
        parsed['4'] as int? ?? 0,
        parsed['5'] as int? ?? 0,
      ];
    } catch (e) {
      return List.generate(6, (i) => 0);
    }
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
