import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

typedef DrawerSettingsBuilder =
    Widget Function(BuildContext context, WidgetRef ref);

class ViewDrawerSettings {
  final Widget? settingsContent;

  const ViewDrawerSettings({this.settingsContent});

  const ViewDrawerSettings.none() : settingsContent = null;
}

class SettingsNotifier extends Notifier<Settings> {
  static const String _keyServerUrl = 'server_url';
  static const String _keyTranslationProvider = 'translation_provider';
  static const String _keyShowTags = 'show_tags';
  static const String _keyShowLastRead = 'show_last_read';
  static const String _keyLanguageFilter = 'language_filter';
  static const String _keyShowAudioPlayer = 'show_audio_player';
  static const String _keyCurrentBookId = 'current_book_id';
  static const String _keyCurrentBookPage = 'current_book_page';
  static const String _keyCurrentBookSentenceIndex =
      'current_book_sentence_index';
  static const String _keyCombineShortSentences = 'combine_short_sentences';
  static const String _keyShowKnownTermsInSentenceReader =
      'show_known_terms_in_sentence_reader';

  @override
  Settings build() {
    _loadSettings();
    return Settings.defaultSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_keyServerUrl) ?? '';
    final translationProvider =
        prefs.getString(_keyTranslationProvider) ?? 'local';
    final showTags = prefs.getBool(_keyShowTags) ?? true;
    final showLastRead = prefs.getBool(_keyShowLastRead) ?? true;
    final languageFilter = prefs.getString(_keyLanguageFilter);
    final showAudioPlayer = prefs.getBool(_keyShowAudioPlayer) ?? true;
    final currentBookId = prefs.getInt(_keyCurrentBookId);
    final currentBookPage = prefs.getInt(_keyCurrentBookPage);
    final currentBookSentenceIndex = prefs.getInt(_keyCurrentBookSentenceIndex);
    final combineShortSentences = prefs.getInt(_keyCombineShortSentences) ?? 3;
    final showKnownTermsInSentenceReader =
        prefs.getBool(_keyShowKnownTermsInSentenceReader) ?? true;

    state = Settings(
      serverUrl: serverUrl,
      isUrlValid: _isValidUrl(serverUrl),
      isInitialized: true,
      translationProvider: translationProvider,
      showTags: showTags,
      showLastRead: showLastRead,
      languageFilter: languageFilter,
      showAudioPlayer: showAudioPlayer,
      currentBookId: currentBookId,
      currentBookPage: currentBookPage,
      currentBookSentenceIndex: currentBookSentenceIndex,
      combineShortSentences: combineShortSentences,
      showKnownTermsInSentenceReader: showKnownTermsInSentenceReader,
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

  Future<void> updateTranslationProvider(String provider) async {
    state = state.copyWith(translationProvider: provider);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTranslationProvider, provider);
  }

  Future<void> updateShowTags(bool show) async {
    state = state.copyWith(showTags: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTags, show);
  }

  Future<void> updateShowLastRead(bool show) async {
    state = state.copyWith(showLastRead: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowLastRead, show);
  }

  Future<void> updateLanguageFilter(String? language) async {
    if (language == null) {
      state = state.copyWith(clearLanguageFilter: true);
    } else {
      state = state.copyWith(languageFilter: language);
    }

    final prefs = await SharedPreferences.getInstance();
    if (language == null) {
      await prefs.remove(_keyLanguageFilter);
    } else {
      await prefs.setString(_keyLanguageFilter, language);
    }
  }

  Future<void> updateShowAudioPlayer(bool show) async {
    print(
      'DEBUG: updateShowAudioPlayer($show) called, currentBookId=${state.currentBookId}, currentBookPage=${state.currentBookPage}',
    );
    final newState = state.copyWith(showAudioPlayer: show);
    print(
      'DEBUG: After copyWith, newBookId=${newState.currentBookId}, newBookPage=${newState.currentBookPage}',
    );
    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAudioPlayer, show);
  }

  Future<void> updateShowKnownTermsInSentenceReader(bool show) async {
    state = state.copyWith(showKnownTermsInSentenceReader: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowKnownTermsInSentenceReader, show);
  }

  Future<void> updateCurrentBook(int bookId, int page) async {
    state = state.copyWith(
      currentBookId: bookId,
      currentBookPage: page,
      currentBookSentenceIndex: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentBookId, bookId);
    await prefs.setInt(_keyCurrentBookPage, page);
    await prefs.remove(_keyCurrentBookSentenceIndex);
  }

  Future<void> clearCurrentBook() async {
    state = state.copyWith(
      currentBookId: null,
      currentBookPage: null,
      currentBookSentenceIndex: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentBookId);
    await prefs.remove(_keyCurrentBookPage);
    await prefs.remove(_keyCurrentBookSentenceIndex);
  }

  Future<void> updateCurrentBookSentenceIndex(int? sentenceIndex) async {
    state = state.copyWith(currentBookSentenceIndex: sentenceIndex);
    final prefs = await SharedPreferences.getInstance();
    if (sentenceIndex == null) {
      await prefs.remove(_keyCurrentBookSentenceIndex);
    } else {
      await prefs.setInt(_keyCurrentBookSentenceIndex, sentenceIndex);
    }
  }

  Future<void> updateCombineShortSentences(int threshold) async {
    state = state.copyWith(combineShortSentences: threshold);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCombineShortSentences, threshold);
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
    await prefs.remove(_keyTranslationProvider);
    await prefs.remove(_keyShowTags);
    await prefs.remove(_keyShowLastRead);
    await prefs.remove(_keyLanguageFilter);
    await prefs.remove(_keyShowAudioPlayer);
    await prefs.remove(_keyCurrentBookId);
    await prefs.remove(_keyCurrentBookPage);
    await prefs.remove(_keyCurrentBookSentenceIndex);
    await prefs.remove(_keyCombineShortSentences);

    state = Settings.defaultSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

@immutable
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TermFormSettings &&
        other.showRomanization == showRomanization &&
        other.showTags == showTags;
  }

  @override
  int get hashCode => showRomanization.hashCode ^ showTags.hashCode;

  static const TermFormSettings defaultSettings = TermFormSettings();
}

class TermFormSettingsNotifier extends Notifier<TermFormSettings> {
  static const String _keyShowRomanization = 'show_romanization';
  static const String _keyShowTags = 'show_tags';
  bool _isInitialized = false;

  @override
  TermFormSettings build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSettings();
    }
    return TermFormSettings.defaultSettings;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final showRomanization = prefs.getBool(_keyShowRomanization) ?? true;
    final showTags = prefs.getBool(_keyShowTags) ?? true;

    final loadedSettings = TermFormSettings(
      showRomanization: showRomanization,
      showTags: showTags,
    );
    if (state != loadedSettings) {
      state = loadedSettings;
    }
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

@immutable
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextFormattingSettings &&
        other.textSize == textSize &&
        other.lineSpacing == lineSpacing &&
        other.fontFamily == fontFamily &&
        other.fontWeight == fontWeight &&
        other.isItalic == isItalic;
  }

  @override
  int get hashCode =>
      Object.hash(textSize, lineSpacing, fontFamily, fontWeight, isItalic);

  static const TextFormattingSettings defaultSettings =
      TextFormattingSettings();
}

class TextFormattingSettingsNotifier extends Notifier<TextFormattingSettings> {
  static const String _keyTextSize = 'text_size';
  static const String _keyLineSpacing = 'line_spacing';
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontWeight = 'font_weight';
  static const String _keyIsItalic = 'is_italic';
  bool _isInitialized = false;

  @override
  TextFormattingSettings build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSettings();
    }
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

    final loadedSettings = TextFormattingSettings(
      textSize: textSize,
      lineSpacing: lineSpacing,
      fontFamily: fontFamily,
      fontWeight:
          fontWeightMap[fontWeightIndex.clamp(0, fontWeightMap.length - 1)],
      isItalic: isItalic,
    );
    if (state != loadedSettings) {
      state = loadedSettings;
    }
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
  static const String _keyCustomAccentLabelColor = 'custom_accent_label_color';
  static const String _keyCustomAccentButtonColor =
      'custom_accent_button_color';
  bool _isInitialized = false;

  @override
  ThemeSettings build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSettingsInBackground();
    }
    return ThemeSettings.defaultSettings;
  }

  void _loadSettingsInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final accentLabelColorValue = prefs.getInt(_keyAccentLabelColor);
    final accentButtonColorValue = prefs.getInt(_keyAccentButtonColor);
    final customAccentLabelColorValue = prefs.getInt(
      _keyCustomAccentLabelColor,
    );
    final customAccentButtonColorValue = prefs.getInt(
      _keyCustomAccentButtonColor,
    );

    final loadedSettings = ThemeSettings(
      accentLabelColor: accentLabelColorValue != null
          ? Color(accentLabelColorValue!)
          : ThemeSettings.defaultSettings.accentLabelColor,
      accentButtonColor: accentButtonColorValue != null
          ? Color(accentButtonColorValue!)
          : ThemeSettings.defaultSettings.accentButtonColor,
      customAccentLabelColor: customAccentLabelColorValue != null
          ? Color(customAccentLabelColorValue!)
          : null,
      customAccentButtonColor: customAccentButtonColorValue != null
          ? Color(customAccentButtonColorValue!)
          : null,
    );

    if (state != loadedSettings) {
      state = loadedSettings;
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

  Future<void> updateCustomAccentLabelColor(Color color) async {
    print('DEBUG: updateCustomAccentLabelColor called with color: $color');
    state = state.copyWith(
      customAccentLabelColor: color,
      accentLabelColor: color,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCustomAccentLabelColor, color.value);
    await prefs.setInt(_keyAccentLabelColor, color.value);
    print('DEBUG: Saved customAccentLabelColor.value = ${color.value}');
  }

  Future<void> updateCustomAccentButtonColor(Color color) async {
    print('DEBUG: updateCustomAccentButtonColor called with color: $color');
    state = state.copyWith(
      customAccentButtonColor: color,
      accentButtonColor: color,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCustomAccentButtonColor, color.value);
    await prefs.setInt(_keyAccentButtonColor, color.value);
    print('DEBUG: Saved customAccentButtonColor.value = ${color.value}');
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
      return ThemeSettingsNotifier();
    });

class CurrentViewDrawerSettingsNotifier extends Notifier<Widget?> {
  @override
  Widget? build() => null;

  void updateSettings(Widget? settingsWidget) {
    state = settingsWidget;
  }
}

final currentViewDrawerSettingsProvider =
    NotifierProvider<CurrentViewDrawerSettingsNotifier, Widget?>(() {
      return CurrentViewDrawerSettingsNotifier();
    });

final bookDisplaySettingsProvider = Provider<BookDisplaySettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return BookDisplaySettings(
    showTags: settings.showTags,
    showLastRead: settings.showLastRead,
  );
});
