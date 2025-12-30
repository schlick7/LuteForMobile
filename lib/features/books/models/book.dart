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
    required this.langId,
    required this.totalPages,
    required this.currentPage,
    required this.percent,
    required this.wordCount,
    required this.distinctTerms,
    required this.unknownPct,
    required this.statusDistribution,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      language: json['language'] as String,
      langId: json['lang_id'] as int,
      totalPages: json['total_pages'] as int,
      currentPage: json['current_page'] as int,
      percent: json['percent'] as int,
      wordCount: json['word_count'] as int,
      distinctTerms: json['distinct_terms'] as int,
      unknownPct: (json['unknown_pct'] as num).toDouble(),
      statusDistribution: _parseStatusDist(json['status_dist'] as String),
    );
  }

  static List<int> _parseStatusDist(String dist) {
    return dist.split(',').map((s) => int.parse(s.trim())).toList();
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
