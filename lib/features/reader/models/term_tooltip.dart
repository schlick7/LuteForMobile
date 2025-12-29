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
      default:
        return statusText ?? 'Unknown';
    }
  }
}

class TermParent {
  final String term;
  final String? translation;

  TermParent({required this.term, this.translation});
}

class TermChild {
  final String term;
  final String? translation;

  TermChild({required this.term, this.translation});
}
