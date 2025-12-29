import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DictionarySource {
  final String name;
  final String urlTemplate;

  const DictionarySource({required this.name, required this.urlTemplate});

  factory DictionarySource.fromJson(Map<String, dynamic> json) {
    return DictionarySource(
      name: json['name'] as String? ?? '',
      urlTemplate: json['urlTemplate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'urlTemplate': urlTemplate};
  }
}

class DictionaryService {
  final Map<int, List<DictionarySource>> _dictionariesCache = {};
  final Map<String, InAppWebViewController> _webviewCache = {};

  String buildUrl(String term, String urlTemplate) {
    final encodedTerm = Uri.encodeComponent(term);
    return urlTemplate.replaceAll('{term}', encodedTerm);
  }

  Future<List<DictionarySource>> getDictionariesForLanguage(
    int languageId,
  ) async {
    if (_dictionariesCache.containsKey(languageId)) {
      return _dictionariesCache[languageId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final dictionariesJson = prefs.getString('dictionaries_$languageId');

    if (dictionariesJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(dictionariesJson);
    final dictionaries = decoded
        .map((json) => DictionarySource.fromJson(json as Map<String, dynamic>))
        .toList();

    _dictionariesCache[languageId] = dictionaries;
    return dictionaries;
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

  Future<String?> getLastUsedDictionary(int languageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_dictionary_$languageId');
  }

  Future<void> rememberLastUsedDictionary(
    int languageId,
    String dictionaryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_dictionary_$languageId', dictionaryName);
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
