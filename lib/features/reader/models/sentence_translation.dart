class SentenceTranslation {
  final String originalSentence;
  final String translatedSentence;
  final String provider;
  final DateTime? timestamp;

  SentenceTranslation({
    required this.originalSentence,
    required this.translatedSentence,
    this.provider = 'local',
    this.timestamp,
  });

  SentenceTranslation copyWith({
    String? originalSentence,
    String? translatedSentence,
    String? provider,
    DateTime? timestamp,
  }) {
    return SentenceTranslation(
      originalSentence: originalSentence ?? this.originalSentence,
      translatedSentence: translatedSentence ?? this.translatedSentence,
      provider: provider ?? this.provider,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isFromAI => provider == 'ai';
  bool get isFromLocal => provider == 'local';
}
