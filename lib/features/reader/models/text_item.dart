class TextItem {
  final String text;
  final String statusClass;
  final int? wordId;
  final int sentenceId;
  final int paragraphId;
  final bool isStartOfSentence;
  final int order;
  final int? langId;

  TextItem({
    required this.text,
    required this.statusClass,
    this.wordId,
    required this.sentenceId,
    required this.paragraphId,
    required this.isStartOfSentence,
    required this.order,
    this.langId,
  });

  TextItem copyWith({
    String? text,
    String? statusClass,
    int? wordId,
    int? sentenceId,
    int? paragraphId,
    bool? isStartOfSentence,
    int? order,
    int? langId,
  }) {
    return TextItem(
      text: text ?? this.text,
      statusClass: statusClass ?? this.statusClass,
      wordId: wordId ?? this.wordId,
      sentenceId: sentenceId ?? this.sentenceId,
      paragraphId: paragraphId ?? this.paragraphId,
      isStartOfSentence: isStartOfSentence ?? this.isStartOfSentence,
      order: order ?? this.order,
      langId: langId ?? this.langId,
    );
  }

  bool get isKnown => statusClass == 'status99';
  bool get isUnknown => statusClass == 'status0';
  bool get isWord => wordId != null;
  bool get isSpace => text.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'statusClass': statusClass,
      'wordId': wordId,
      'sentenceId': sentenceId,
      'paragraphId': paragraphId,
      'isStartOfSentence': isStartOfSentence,
      'order': order,
      'langId': langId,
    };
  }

  factory TextItem.fromJson(Map<String, dynamic> json) {
    return TextItem(
      text: json['text'] as String,
      statusClass: json['statusClass'] as String,
      wordId: json['wordId'] as int?,
      sentenceId: json['sentenceId'] as int,
      paragraphId: json['paragraphId'] as int,
      isStartOfSentence: json['isStartOfSentence'] as bool,
      order: json['order'] as int,
      langId: json['langId'] as int?,
    );
  }
}
