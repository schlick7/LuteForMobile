class Term {
  final int id;
  final String text;
  final String? translation;
  final String status;
  final int langId;
  final String language;
  final List<String>? tags;
  final int? parentCount;
  final DateTime? createdDate;

  Term({
    required this.id,
    required this.text,
    this.translation,
    required this.status,
    required this.langId,
    required this.language,
    this.tags,
    this.parentCount,
    this.createdDate,
  });

  String get statusLabel {
    switch (status) {
      case '99':
        return 'Well Known';
      case '0':
        return 'Ignored';
      case '1':
        return 'Learning 1';
      case '2':
        return 'Learning 2';
      case '3':
        return 'Learning 3';
      case '4':
        return 'Learning 4';
      case '5':
        return 'Ignored (dotted)';
      case '98':
        return 'Ignored (dotted)';
      default:
        return 'Unknown';
    }
  }

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['WoID'] as int,
      text: json['WoText'] as String,
      translation: json['WoTranslation'] as String?,
      status: (json['StID'] as int?).toString() ?? '99',
      langId: json['LgID'] as int? ?? 0,
      language: json['LgName'] as String? ?? '',
      tags: (json['Tags'] as String?)
          ?.split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      parentCount: json['ParentCount'] as int?,
      createdDate: DateTime.tryParse(json['CreatedDate'] as String? ?? ''),
    );
  }
}
