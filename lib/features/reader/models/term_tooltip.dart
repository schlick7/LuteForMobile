class TermTooltip {
  final String term;
  final String? translation;
  final int? termId;
  final String status;
  final String? statusText;
  final List<String> sentences;
  final String? language;
  final int? languageId;
  final List<TermParent> parents;
  final List<TermChild> children;

  TermTooltip({
    required this.term,
    this.translation,
    this.termId,
    required this.status,
    this.statusText,
    this.sentences = const [],
    this.language,
    this.languageId,
    this.parents = const [],
    this.children = const [],
  });

  bool get hasData {
    return term.isNotEmpty;
  }

  String get statusLabel {
    switch (status) {
      case '99':
        return 'Well Known';
      case '0':
        return 'Unknown';
      case '1':
        return 'Learning 1';
      case '2':
        return 'Learning 2';
      case '3':
        return 'Learning 3';
      case '4':
        return 'Learning 4';
      case '5':
        return 'Learning 5';
      case '98':
        return 'Ignored';
      default:
        return statusText ?? 'Unknown';
    }
  }

  TermTooltip copyWith({
    String? term,
    String? translation,
    int? termId,
    String? status,
    String? statusText,
    List<String>? sentences,
    String? language,
    int? languageId,
    List<TermParent>? parents,
    List<TermChild>? children,
  }) {
    return TermTooltip(
      term: term ?? this.term,
      translation: translation ?? this.translation,
      termId: termId ?? this.termId,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      sentences: sentences ?? this.sentences,
      language: language ?? this.language,
      languageId: languageId ?? this.languageId,
      parents: parents ?? this.parents,
      children: children ?? this.children,
    );
  }
}

class TermParent {
  final int? id;
  final String term;
  final String? translation;
  final int? status;
  final bool? syncStatus;

  TermParent({
    this.id,
    required this.term,
    this.translation,
    this.status,
    this.syncStatus,
  });
}

class TermChild {
  final String term;
  final String? translation;

  TermChild({required this.term, this.translation});
}
