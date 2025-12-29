import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsNotifier extends Notifier<Settings> {
  static const String _keyServerUrl = 'server_url';
  static const String _keyBookId = 'default_book_id';
  static const String _keyPageId = 'default_page_id';
  static const String _keyTranslationProvider = 'translation_provider';
  static const String _keyShowRomanization = 'show_romanization';
  static const String _keyShowTags = 'show_tags';

  @override
  Settings build() {
    _loadSettings();
    return Settings.defaultSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_keyServerUrl) ?? 'http://localhost:5001';
    final bookId = prefs.getInt(_keyBookId) ?? 18;
    final pageId = prefs.getInt(_keyPageId) ?? 1;
    final translationProvider =
        prefs.getString(_keyTranslationProvider) ?? 'local';
    final showRomanization = prefs.getBool(_keyShowRomanization) ?? true;
    final showTags = prefs.getBool(_keyShowTags) ?? true;

    state = Settings(
      serverUrl: serverUrl,
      defaultBookId: bookId,
      defaultPageId: pageId,
      isUrlValid: _isValidUrl(serverUrl),
      translationProvider: translationProvider,
      showRomanization: showRomanization,
      showTags: showTags,
    );
  }

  Future<void> updateServerUrl(String url) async {
    final isValid = _isValidUrl(url);
    state = state.copyWith(serverUrl: url, isUrlValid: isValid);

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerUrl, url);
    }
  }

  Future<void> updateBookId(int bookId) async {
    state = state.copyWith(defaultBookId: bookId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBookId, bookId);
  }

  Future<void> updatePageId(int pageId) async {
    state = state.copyWith(defaultPageId: pageId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPageId, pageId);
  }

  Future<void> updateTranslationProvider(String provider) async {
    state = state.copyWith(translationProvider: provider);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTranslationProvider, provider);
  }

  Future<void> updateShowRomanization(bool show) async {
    state = state.copyWith(showRomanization: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowRomanization, show);
  }

  Future<void> updateShowTags(bool show) async {
    state = state.copyWith(showTags: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTags, show);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyBookId);
    await prefs.remove(_keyPageId);
    await prefs.remove(_keyTranslationProvider);
    await prefs.remove(_keyShowRomanization);
    await prefs.remove(_keyShowTags);

    state = Settings.defaultSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});
