import 'dart:convert';

class BookCreateRequest {
  final int languageId;
  final String title;
  final String text;
  final String sourceUri;
  final List<String> tags;
  final String splitBy;
  final int thresholdPageTokens;
  final String? textFilePath;
  final String? audioFilePath;

  const BookCreateRequest({
    required this.languageId,
    required this.title,
    required this.text,
    this.sourceUri = '',
    this.tags = const [],
    this.splitBy = 'paragraphs',
    this.thresholdPageTokens = 250,
    this.textFilePath,
    this.audioFilePath,
  });

  Map<String, dynamic> toFormFields() {
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

  bool get hasTextFile => textFilePath != null && textFilePath!.isNotEmpty;
  bool get hasAudioFile => audioFilePath != null && audioFilePath!.isNotEmpty;
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

class BookEditFormData {
  final String title;
  final String sourceUri;
  final List<String> tags;
  final String audioFilename;

  const BookEditFormData({
    required this.title,
    required this.sourceUri,
    required this.tags,
    required this.audioFilename,
  });
}

class BookEditRequest {
  final int bookId;
  final String title;
  final String sourceUri;
  final List<String> tags;
  final String audioFilename;
  final String? audioFilePath;

  const BookEditRequest({
    required this.bookId,
    required this.title,
    required this.sourceUri,
    required this.tags,
    required this.audioFilename,
    this.audioFilePath,
  });

  bool get hasAudioFile => audioFilePath != null && audioFilePath!.isNotEmpty;

  Map<String, dynamic> toFormFields() {
    final encodedTags = jsonEncode(
      tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .map((tag) => {'value': tag})
          .toList(),
    );

    return {
      'title': title,
      'source_uri': sourceUri,
      'book_tags': encodedTags,
      'audio_filename': audioFilename,
    };
  }
}
