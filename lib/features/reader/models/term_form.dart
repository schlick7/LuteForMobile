import 'dart:convert';
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
  final bool? syncStatus;

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
    required this.syncStatus,
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
    bool? syncStatus,
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
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toFormData() {
    print('Converting term form to form data');
    print('Parents count: ${parents.length}');
    print('Sync status: $syncStatus');
    for (final p in parents) {
      print('Parent: id=${p.id}, term=${p.term}, translation=${p.translation}');
    }
    final data = {
      'text': term,
      'translation': translation ?? '',
      'status': status,
      'tags': tags?.join(',') ?? '',
      'romanization': romanization ?? '',
    };

    if (syncStatus == true) {
      data['sync_status'] = 'y';
    }

    if (parents.isNotEmpty) {
      final parentsList = parents.map((p) => {'value': p.term}).toList();
      final parentsListJson = jsonEncode(parentsList);
      data['parentslist'] = parentsListJson;
      print('Sending parentslist: $parentsListJson');
    }

    return data;
  }
}
