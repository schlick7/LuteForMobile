class TermForm {
  final String term;
  final String? translation;
  final int? termId;
  final int languageId;
  final String status;
  final List<String>? tags;
  final String? romanization;
  final List<String> dictionaries;

  TermForm({
    required this.term,
    this.translation,
    this.termId,
    required this.languageId,
    this.status = '99',
    this.tags,
    this.romanization,
    this.dictionaries = const [],
  });

  TermForm copyWith({
    String? term,
    String? translation,
    int? termId,
    int? languageId,
    String? status,
    List<String>? tags,
    String? romanization,
    List<String>? dictionaries,
  }) {
    return TermForm(
      term: term ?? this.term,
      translation: translation ?? this.translation,
      termId: termId ?? this.termId,
      languageId: languageId ?? this.languageId,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      romanization: romanization ?? this.romanization,
      dictionaries: dictionaries ?? this.dictionaries,
    );
  }

  Map<String, dynamic> toFormData() {
    return {
      'text': term,
      'translation': translation ?? '',
      'status': status,
      'tags': tags?.join(',') ?? '',
      'romanization': romanization ?? '',
    };
  }
}
