import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'html_parser.dart';

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
  final HtmlParser _htmlParser = HtmlParser();

  String buildUrl(String term, String urlTemplate) {
    final encodedTerm = Uri.encodeComponent(term);
    return urlTemplate
        .replaceAll('[LUTE]', encodedTerm)
        .replaceAll('{term}', encodedTerm);
  }

  Future<List<DictionarySource>> getDictionariesForLanguage(
    int languageId,
    String? serverUrl,
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

    if (serverUrl != null) {
      final dictionaries = await _fetchAndCacheDictionaries(
        languageId,
        serverUrl,
      );
      if (dictionaries.isNotEmpty) {
        return dictionaries;
      }
    }

    return [];
  }

  Future<List<DictionarySource>> _fetchAndCacheDictionaries(
    int languageId,
    String serverUrl,
  ) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: serverUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'text/html'},
        ),
      );

      final response = await dio.get<String>('/language/edit/$languageId');
      final htmlContent = response.data ?? '';

      final dictionaries = _htmlParser.parseLanguageDictionaries(htmlContent);

      if (dictionaries.isNotEmpty) {
        await setDictionariesForLanguage(languageId, dictionaries);
      }

      return dictionaries;
    } catch (e) {
      print('Error fetching dictionaries for language $languageId: $e');
      return [];
    }
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
