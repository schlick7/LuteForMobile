import 'package:meta/meta.dart';

@immutable
class LanguageSentenceSettings {
  final int languageId;
  final String stopChars;
  final List<String> sentenceExceptions;
  final String parserType;

  const LanguageSentenceSettings({
    required this.languageId,
    required this.stopChars,
    required this.sentenceExceptions,
    required this.parserType,
  });

  LanguageSentenceSettings copyWith({
    int? languageId,
    String? stopChars,
    List<String>? sentenceExceptions,
    String? parserType,
  }) {
    return LanguageSentenceSettings(
      languageId: languageId ?? this.languageId,
      stopChars: stopChars ?? this.stopChars,
      sentenceExceptions: sentenceExceptions ?? this.sentenceExceptions,
      parserType: parserType ?? this.parserType,
    );
  }
}
