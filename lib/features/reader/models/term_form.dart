import 'term_tooltip.dart';

class SearchResultTerm {
  final int? id;
  final String text;
  final String? translation;
  final int? status;
  final int? langId;

  SearchResultTerm({
    this.id,
    required this.text,
    this.translation,
    this.status,
    this.langId,
  });

  factory SearchResultTerm.fromJson(Map<String, dynamic> json) {
    return SearchResultTerm(
      id: json['id'] as int?,
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String?,
      status: json['status'] as int?,
      langId: json['lang_id'] as int?,
    );
  }

  String get statusString => status?.toString() ?? '';
}

class TermForm {
  final String term;
  final String? translation;
  final int? termId;
  final int languageId;
  final String status;
  final List<String>? tags;
  final String? romanization;
  final List<String> dictionaries;
  final List<TermParent> parents;

  TermForm({
    required this.term,
    this.translation,
    this.termId,
    required this.languageId,
    this.status = '99',
    this.tags,
    this.romanization,
    this.dictionaries = const [],
    this.parents = const [],
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
    List<TermParent>? parents,
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
      parents: parents ?? this.parents,
    );
  }

  Map<String, dynamic> toFormData() {
    final data = {
      'text': term,
      'translation': translation ?? '',
      'status': status,
      'tags': tags?.join(',') ?? '',
      'romanization': romanization ?? '',
    };

    if (parents.isNotEmpty) {
      final existingParentIds = parents
          .where((p) => p.id != null)
          .map((p) => p.id)
          .join(',');

      final newParentTerms = parents
          .where((p) => p.id == null)
          .map((p) => p.term)
          .join(',');

      if (existingParentIds.isNotEmpty) {
        data['parent_ids'] = existingParentIds;
      }

      if (newParentTerms.isNotEmpty) {
        data['parent_texts'] = newParentTerms;
      }
    }

    return data;
  }
}
