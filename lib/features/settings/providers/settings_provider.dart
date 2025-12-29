import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsNotifier extends Notifier<Settings> {
  static const String _keyServerUrl = 'server_url';
  static const String _keyBookId = 'default_book_id';
  static const String _keyPageId = 'default_page_id';
  static const String _keyTranslationProvider = 'translation_provider';

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

    state = Settings(
      serverUrl: serverUrl,
      defaultBookId: bookId,
      defaultPageId: pageId,
      isUrlValid: _isValidUrl(serverUrl),
      translationProvider: translationProvider,
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

    state = Settings.defaultSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

class TermFormSettings {
  final bool showRomanization;
  final bool showTags;

  const TermFormSettings({this.showRomanization = true, this.showTags = true});

  TermFormSettings copyWith({bool? showRomanization, bool? showTags}) {
    return TermFormSettings(
      showRomanization: showRomanization ?? this.showRomanization,
      showTags: showTags ?? this.showTags,
    );
  }

  static const TermFormSettings defaultSettings = TermFormSettings();
}

class TermFormSettingsNotifier extends Notifier<TermFormSettings> {
  static const String _keyShowRomanization = 'show_romanization';
  static const String _keyShowTags = 'show_tags';

  @override
  TermFormSettings build() {
    _loadSettings();
    return TermFormSettings.defaultSettings;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final showRomanization = prefs.getBool(_keyShowRomanization) ?? true;
    final showTags = prefs.getBool(_keyShowTags) ?? true;

    state = TermFormSettings(
      showRomanization: showRomanization,
      showTags: showTags,
    );
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
}

final termFormSettingsProvider =
    NotifierProvider<TermFormSettingsNotifier, TermFormSettings>(() {
      return TermFormSettingsNotifier();
    });

class TextFormattingSettings {
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;

  const TextFormattingSettings({
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
  });

  TextFormattingSettings copyWith({
    double? textSize,
    double? lineSpacing,
    String? fontFamily,
    FontWeight? fontWeight,
    bool? isItalic,
  }) {
    return TextFormattingSettings(
      textSize: textSize ?? this.textSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      isItalic: isItalic ?? this.isItalic,
    );
  }

  static const TextFormattingSettings defaultSettings =
      TextFormattingSettings();
}

class TextFormattingSettingsNotifier extends Notifier<TextFormattingSettings> {
  static const String _keyTextSize = 'text_size';
  static const String _keyLineSpacing = 'line_spacing';
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontWeight = 'font_weight';
  static const String _keyIsItalic = 'is_italic';

  @override
  TextFormattingSettings build() {
    _loadSettings();
    return TextFormattingSettings.defaultSettings;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final textSize = prefs.getDouble(_keyTextSize) ?? 18.0;
    final lineSpacing = prefs.getDouble(_keyLineSpacing) ?? 1.5;
    final fontFamily = prefs.getString(_keyFontFamily) ?? 'Roboto';
    final fontWeightIndex = prefs.getInt(_keyFontWeight) ?? 0;
    final isItalic = prefs.getBool(_keyIsItalic) ?? false;

    final fontWeightMap = [
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.normal,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.bold,
      FontWeight.w800,
    ];

    state = TextFormattingSettings(
      textSize: textSize,
      lineSpacing: lineSpacing,
      fontFamily: fontFamily,
      fontWeight:
          fontWeightMap[fontWeightIndex.clamp(0, fontWeightMap.length - 1)],
      isItalic: isItalic,
    );
  }

  Future<void> updateTextSize(double size) async {
    state = state.copyWith(textSize: size);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextSize, size);
  }

  Future<void> updateLineSpacing(double spacing) async {
    state = state.copyWith(lineSpacing: spacing);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLineSpacing, spacing);
  }

  Future<void> updateFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontFamily, family);
  }

  Future<void> updateFontWeight(FontWeight weight) async {
    state = state.copyWith(fontWeight: weight);

    final prefs = await SharedPreferences.getInstance();
    final fontWeightMap = [
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.normal,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.bold,
      FontWeight.w800,
    ];
    final index = fontWeightMap.indexOf(weight);
    if (index >= 0) {
      await prefs.setInt(_keyFontWeight, index);
    }
  }

  Future<void> updateIsItalic(bool italic) async {
    state = state.copyWith(isItalic: italic);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsItalic, italic);
  }
}

final textFormattingSettingsProvider =
    NotifierProvider<TextFormattingSettingsNotifier, TextFormattingSettings>(
      () {
        return TextFormattingSettingsNotifier();
      },
    );

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const String _keyAccentLabelColor = 'accent_label_color';
  static const String _keyAccentButtonColor = 'accent_button_color';

  @override
  ThemeSettings build() {
    final initialSettings = ThemeSettings.defaultSettings;
    _loadSettingsInBackground(initialSettings);
    return initialSettings;
  }

  void _loadSettingsInBackground(ThemeSettings currentSettings) async {
    final prefs = await SharedPreferences.getInstance();
    final accentLabelColorValue = prefs.getInt(_keyAccentLabelColor);
    final accentButtonColorValue = prefs.getInt(_keyAccentButtonColor);

    final loadedSettings = ThemeSettings(
      accentLabelColor: accentLabelColorValue != null
          ? Color(accentLabelColorValue!)
          : ThemeSettings.defaultSettings.accentLabelColor,
      accentButtonColor: accentButtonColorValue != null
          ? Color(accentButtonColorValue!)
          : ThemeSettings.defaultSettings.accentButtonColor,
    );

    if (loadedSettings.accentLabelColor.value !=
            currentSettings.accentLabelColor.value ||
        loadedSettings.accentButtonColor.value !=
            currentSettings.accentButtonColor.value) {
      state = loadedSettings;
      print('DEBUG: Updated settings from storage: $loadedSettings');
    }
  }

  Future<void> updateAccentLabelColor(Color color) async {
    print('DEBUG: updateAccentLabelColor called with color: $color');
    state = state.copyWith(accentLabelColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentLabelColor, color.value);
    print('DEBUG: Saved accentLabelColor.value = ${color.value}');
  }

  Future<void> updateAccentButtonColor(Color color) async {
    print('DEBUG: updateAccentButtonColor called with color: $color');
    state = state.copyWith(accentButtonColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentButtonColor, color.value);
    print('DEBUG: Saved accentButtonColor.value = ${color.value}');
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
      return ThemeSettingsNotifier();
    });
