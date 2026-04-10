import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'html_parser.dart';

enum AIType { translation, virtualDictionary }

class DictionarySource {
  final String name;
  final String urlTemplate;
  final bool isAI;
  final AIType? aiType;

  const DictionarySource({
    required this.name,
    required this.urlTemplate,
    this.isAI = false,
    this.aiType,
  });

  factory DictionarySource.fromJson(Map<String, dynamic> json) {
    return DictionarySource(
      name: json['name'] as String? ?? '',
      urlTemplate: json['urlTemplate'] as String? ?? '',
      isAI: json['isAI'] as bool? ?? false,
      aiType: json['aiType'] != null
          ? AIType.values.firstWhere(
              (e) => e.toString() == json['aiType'],
              orElse: () => AIType.translation,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'urlTemplate': urlTemplate,
      'isAI': isAI,
      'aiType': aiType?.toString(),
    };
  }
}

class DictionaryService {
  final Map<int, List<DictionarySource>> _dictionariesCache = {};
  final Map<int, List<DictionarySource>> _sentenceDictionariesCache = {};
  final Map<String, InAppWebViewController> _webviewCache = {};
  final HtmlParser _htmlParser;
  final Future<String?> Function(int) _fetchLanguageSettingsHtml;

  DictionaryService({
    required Future<String?> Function(int) fetchLanguageSettingsHtml,
  }) : _htmlParser = HtmlParser(),
       _fetchLanguageSettingsHtml = fetchLanguageSettingsHtml;

  String buildUrl(String term, String urlTemplate) {
    final encodedTerm = Uri.encodeComponent(term);
    return urlTemplate
        .replaceAll('[LUTE]', encodedTerm)
        .replaceAll('{term}', encodedTerm)
        .replaceAll('{sentence}', encodedTerm);
  }

  Future<List<DictionarySource>> getDictionariesForLanguage(
    int languageId,
  ) async {
    if (_dictionariesCache.containsKey(languageId)) {
      return _dictionariesCache[languageId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final dictionariesJson = prefs.getString('dictionaries_$languageId');

    if (dictionariesJson != null) {
      final List<dynamic> decoded = jsonDecode(dictionariesJson);
      final dictionaries = decoded
          .map(
            (json) => DictionarySource.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      _dictionariesCache[languageId] = dictionaries;
      return dictionaries;
    }

    final htmlContent = await _fetchLanguageSettingsHtml(languageId) ?? '';
    if (htmlContent.isNotEmpty) {
      final dictionaries = _htmlParser.parseLanguageDictionaries(htmlContent);
      if (dictionaries.isNotEmpty) {
        await setDictionariesForLanguage(languageId, dictionaries);
        return dictionaries;
      }
    }

    return [];
  }

  Future<List<DictionarySource>> getSentenceDictionariesForLanguage(
    int languageId,
  ) async {
    if (_sentenceDictionariesCache.containsKey(languageId)) {
      return _sentenceDictionariesCache[languageId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final dictionariesJson = prefs.getString(
      'sentence_dictionaries_$languageId',
    );

    if (dictionariesJson != null) {
      final List<dynamic> decoded = jsonDecode(dictionariesJson);
      final dictionaries = decoded
          .map(
            (json) => DictionarySource.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      _sentenceDictionariesCache[languageId] = dictionaries;
      return dictionaries;
    }

    final htmlContent = await _fetchLanguageSettingsHtml(languageId) ?? '';
    if (htmlContent.isNotEmpty) {
      final dictionaries = _htmlParser.parseSentenceDictionaries(htmlContent);
      if (dictionaries.isNotEmpty) {
        await setSentenceDictionariesForLanguage(languageId, dictionaries);
        return dictionaries;
      }
    }

    return [];
  }

  Future<void> setDictionariesForLanguage(
    int languageId,
    List<DictionarySource> dictionaries,
  ) async {
    _dictionariesCache[languageId] = dictionaries;
    final prefs = await SharedPreferences.getInstance();
    final dictionariesJson = jsonEncode(
      dictionaries.map((d) => d.toJson()).toList(),
    );
    await prefs.setString('dictionaries_$languageId', dictionariesJson);
  }

  Future<void> setSentenceDictionariesForLanguage(
    int languageId,
    List<DictionarySource> dictionaries,
  ) async {
    _sentenceDictionariesCache[languageId] = dictionaries;
    final prefs = await SharedPreferences.getInstance();
    final dictionariesJson = jsonEncode(
      dictionaries.map((d) => d.toJson()).toList(),
    );
    await prefs.setString(
      'sentence_dictionaries_$languageId',
      dictionariesJson,
    );
  }

  Future<String?> getLastUsedDictionary(int languageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_dictionary_$languageId');
  }

  Future<String?> getLastUsedSentenceDictionary(int languageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sentence_dictionary_$languageId');
  }

  Future<void> rememberLastUsedDictionary(
    int languageId,
    String dictionaryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_dictionary_$languageId', dictionaryName);
  }

  Future<void> rememberLastUsedSentenceDictionary(
    int languageId,
    String dictionaryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_sentence_dictionary_$languageId',
      dictionaryName,
    );
  }

  static const int defaultPopupHeight = 300;
  static const int minPopupHeight = 150;
  static const int maxPopupHeight = 600;
  static const int popupHeightStep = 50;

  Future<int> getSentenceTranslationPopupHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sentence_translation_popup_height') ??
        defaultPopupHeight;
  }

  Future<void> setSentenceTranslationPopupHeight(int height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sentence_translation_popup_height', height);
  }

  Future<bool> getSentenceTranslationStartCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sentence_translation_start_collapsed') ?? true;
  }

  Future<void> setSentenceTranslationStartCollapsed(bool collapsed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sentence_translation_start_collapsed', collapsed);
  }

  static const int defaultSplitRatio = 7;
  static const int minSplitRatio = 5;
  static const int maxSplitRatio = 8;

  Future<int> getSentenceReaderSplitRatio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sentence_reader_split_ratio') ?? defaultSplitRatio;
  }

  Future<void> setSentenceReaderSplitRatio(int ratio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sentence_reader_split_ratio', ratio);
  }

  String getWebviewCacheKey(String dictionaryName, String term) {
    return '${dictionaryName}_${term.hashCode}';
  }

  InAppWebViewController? getCachedWebview(String cacheKey) {
    return _webviewCache[cacheKey];
  }

  void cacheWebview(String cacheKey, InAppWebViewController controller) {
    _webviewCache[cacheKey] = controller;
  }

  void clearCache() {
    _webviewCache.clear();
  }
}
