class LanguageDictionarySetting {
  final String useFor;
  final String dictType;
  final String dictUri;
  final bool isActive;
  final int sortOrder;

  const LanguageDictionarySetting({
    required this.useFor,
    required this.dictType,
    required this.dictUri,
    required this.isActive,
    required this.sortOrder,
  });

  LanguageDictionarySetting copyWith({
    String? useFor,
    String? dictType,
    String? dictUri,
    bool? isActive,
    int? sortOrder,
  }) {
    return LanguageDictionarySetting(
      useFor: useFor ?? this.useFor,
      dictType: dictType ?? this.dictType,
      dictUri: dictUri ?? this.dictUri,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class LanguageCardSettings {
  final int languageId;
  final String name;
  final bool showRomanization;
  final bool rightToLeft;
  final String parserType;
  final List<String> parserTypeOptions;
  final String characterSubstitutions;
  final String regexpSplitSentences;
  final String exceptionsSplitSentences;
  final String wordCharacters;
  final List<LanguageDictionarySetting> dictionaries;

  const LanguageCardSettings({
    required this.languageId,
    required this.name,
    required this.showRomanization,
    required this.rightToLeft,
    required this.parserType,
    required this.parserTypeOptions,
    required this.characterSubstitutions,
    required this.regexpSplitSentences,
    required this.exceptionsSplitSentences,
    required this.wordCharacters,
    required this.dictionaries,
  });

  LanguageCardSettings copyWith({
    int? languageId,
    String? name,
    bool? showRomanization,
    bool? rightToLeft,
    String? parserType,
    List<String>? parserTypeOptions,
    String? characterSubstitutions,
    String? regexpSplitSentences,
    String? exceptionsSplitSentences,
    String? wordCharacters,
    List<LanguageDictionarySetting>? dictionaries,
  }) {
    return LanguageCardSettings(
      languageId: languageId ?? this.languageId,
      name: name ?? this.name,
      showRomanization: showRomanization ?? this.showRomanization,
      rightToLeft: rightToLeft ?? this.rightToLeft,
      parserType: parserType ?? this.parserType,
      parserTypeOptions: parserTypeOptions ?? this.parserTypeOptions,
      characterSubstitutions:
          characterSubstitutions ?? this.characterSubstitutions,
      regexpSplitSentences: regexpSplitSentences ?? this.regexpSplitSentences,
      exceptionsSplitSentences:
          exceptionsSplitSentences ?? this.exceptionsSplitSentences,
      wordCharacters: wordCharacters ?? this.wordCharacters,
      dictionaries: dictionaries ?? this.dictionaries,
    );
  }
}
