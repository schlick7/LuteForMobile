import 'dart:convert';

class BookCreateRequest {
  final int languageId;
  final String title;
  final String text;
  final String sourceUri;
  final List<String> tags;
  final String splitBy;
  final int thresholdPageTokens;

  const BookCreateRequest({
    required this.languageId,
    required this.title,
    required this.text,
    this.sourceUri = '',
    this.tags = const [],
    this.splitBy = 'paragraphs',
    this.thresholdPageTokens = 250,
  });

  Map<String, dynamic> toFormData() {
    final encodedTags = jsonEncode(
      tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .map((tag) => {'value': tag})
          .toList(),
    );

    return {
      'language_id': languageId.toString(),
      'title': title,
      'text': text,
      'source_uri': sourceUri,
      'book_tags': encodedTags,
      'split_by': splitBy,
      'threshold_page_tokens': thresholdPageTokens.toString(),
    };
  }
}

class BookImportPreview {
  final String title;
  final String text;
  final String sourceUri;

  const BookImportPreview({
    required this.title,
    required this.text,
    required this.sourceUri,
  });
}
