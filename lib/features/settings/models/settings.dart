import 'package:flutter/material.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';

@immutable
class Settings {
  final String localUrl;
  final String serverUrl;
  final String? aiServerUrl;
  final String? ttsServerUrl;
  final bool isUrlValid;
  final String translationProvider;
  final bool showTags;
  final bool showLastRead;
  final String? languageFilter;
  final bool showAudioPlayer;
  final int? currentBookId;
  final int? currentBookLangId;
  final int? currentBookPage;
  final int? currentBookSentenceIndex;
  final int? combineShortSentences;
  final bool showKnownTermsInSentenceReader;
  final int doubleTapTimeout;
  final bool pageTurnAnimations;
  final bool enableTooltipCaching;
  final bool showStatsBar;
  final bool showPageNumbers;
  final TTSProvider? ttsProvider;
  final AIProvider? aiProvider;
  final bool enableTripleTapToMarkKnown;
  final bool termuxIntegrationEnabled;
  final bool termuxAutoLaunchEnabled;

  static const String termuxUrl = 'http://127.0.0.1:5001';

  const Settings({
    required this.localUrl,
    required this.serverUrl,
    this.aiServerUrl,
    this.ttsServerUrl,
    this.isUrlValid = true,
    this.translationProvider = 'local',
    this.showTags = true,
    this.showLastRead = true,
    this.languageFilter,
    this.showAudioPlayer = true,
    this.currentBookId,
    this.currentBookLangId,
    this.currentBookPage,
    this.currentBookSentenceIndex,
    this.combineShortSentences,
    this.showKnownTermsInSentenceReader = true,
    this.doubleTapTimeout = 300,
    this.pageTurnAnimations = true,
    this.enableTooltipCaching = false,
    this.showStatsBar = true,
    this.showPageNumbers = true,
    this.ttsProvider,
    this.aiProvider,
    this.enableTripleTapToMarkKnown = false,
    this.termuxIntegrationEnabled = false,
    this.termuxAutoLaunchEnabled = false,
  });

  Settings copyWith({
    String? localUrl,
    String? serverUrl,
    String? aiServerUrl,
    String? ttsServerUrl,
    bool? isUrlValid,
    String? translationProvider,
    bool? showTags,
    bool? showLastRead,
    String? languageFilter,
    bool clearLanguageFilter = false,
    bool? showAudioPlayer,
    int? currentBookId,
    int? currentBookLangId,
    int? currentBookPage,
    bool clearCurrentBook = false,
    int? currentBookSentenceIndex,
    int? combineShortSentences,
    bool? showKnownTermsInSentenceReader,
    int? doubleTapTimeout,
    bool? pageTurnAnimations,
    bool? enableTooltipCaching,
    bool? showStatsBar,
    bool? showPageNumbers,
    TTSProvider? ttsProvider,
    AIProvider? aiProvider,
    bool? enableTripleTapToMarkKnown,
    bool? termuxIntegrationEnabled,
    bool? termuxAutoLaunchEnabled,
  }) {
    return Settings(
      localUrl: localUrl ?? this.localUrl,
      serverUrl: serverUrl ?? this.serverUrl,
      aiServerUrl: aiServerUrl ?? this.aiServerUrl,
      ttsServerUrl: ttsServerUrl ?? this.ttsServerUrl,
      isUrlValid: isUrlValid ?? this.isUrlValid,
      translationProvider: translationProvider ?? this.translationProvider,
      showTags: showTags ?? this.showTags,
      showLastRead: showLastRead ?? this.showLastRead,
      languageFilter: clearLanguageFilter
          ? null
          : (languageFilter ?? this.languageFilter),
      showAudioPlayer: showAudioPlayer ?? this.showAudioPlayer,
      currentBookId: clearCurrentBook
          ? null
          : (currentBookId ?? this.currentBookId),
      currentBookLangId: clearCurrentBook
          ? null
          : (currentBookLangId ?? this.currentBookLangId),
      currentBookPage: clearCurrentBook
          ? null
          : (currentBookPage ?? this.currentBookPage),
      currentBookSentenceIndex:
          currentBookSentenceIndex ?? this.currentBookSentenceIndex,
      combineShortSentences:
          combineShortSentences ?? this.combineShortSentences,
      showKnownTermsInSentenceReader:
          showKnownTermsInSentenceReader ?? this.showKnownTermsInSentenceReader,
      doubleTapTimeout: doubleTapTimeout ?? this.doubleTapTimeout,
      pageTurnAnimations: pageTurnAnimations ?? this.pageTurnAnimations,
      enableTooltipCaching: enableTooltipCaching ?? this.enableTooltipCaching,
      showStatsBar: showStatsBar ?? this.showStatsBar,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      aiProvider: aiProvider ?? this.aiProvider,
      enableTripleTapToMarkKnown:
          enableTripleTapToMarkKnown ?? this.enableTripleTapToMarkKnown,
      termuxIntegrationEnabled:
          termuxIntegrationEnabled ?? this.termuxIntegrationEnabled,
      termuxAutoLaunchEnabled:
          termuxAutoLaunchEnabled ?? this.termuxAutoLaunchEnabled,
    );
  }

  factory Settings.defaultSettings() {
    return const Settings(
      localUrl: '',
      serverUrl: '',
      aiServerUrl: null,
      ttsServerUrl: null,
      isUrlValid: true,
      translationProvider: 'local',
      showTags: true,
      showLastRead: true,
      languageFilter: null,
      showAudioPlayer: true,
      currentBookId: null,
      currentBookLangId: null,
      currentBookPage: null,
      currentBookSentenceIndex: null,
      combineShortSentences: 3,
      showKnownTermsInSentenceReader: true,
      doubleTapTimeout: 300,
      pageTurnAnimations: true,
      enableTooltipCaching: false,
      showStatsBar: true,
      showPageNumbers: true,
      ttsProvider: TTSProvider.onDevice,
      aiProvider: AIProvider.none,
      enableTripleTapToMarkKnown: false,
      termuxIntegrationEnabled: false,
      termuxAutoLaunchEnabled: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settings &&
        other.localUrl == localUrl &&
        other.serverUrl == serverUrl &&
        other.aiServerUrl == aiServerUrl &&
        other.ttsServerUrl == ttsServerUrl &&
        other.isUrlValid == isUrlValid &&
        other.translationProvider == translationProvider &&
        other.showTags == showTags &&
        other.showLastRead == showLastRead &&
        other.languageFilter == languageFilter &&
        other.showAudioPlayer == showAudioPlayer &&
        other.currentBookId == currentBookId &&
        other.currentBookLangId == currentBookLangId &&
        other.currentBookPage == currentBookPage &&
        other.currentBookSentenceIndex == currentBookSentenceIndex &&
        other.combineShortSentences == combineShortSentences &&
        other.showKnownTermsInSentenceReader ==
            showKnownTermsInSentenceReader &&
        other.doubleTapTimeout == doubleTapTimeout &&
        other.pageTurnAnimations == pageTurnAnimations &&
        other.enableTooltipCaching == enableTooltipCaching &&
        other.showStatsBar == showStatsBar &&
        other.showPageNumbers == showPageNumbers &&
        other.ttsProvider == ttsProvider &&
        other.aiProvider == aiProvider &&
        other.enableTripleTapToMarkKnown == enableTripleTapToMarkKnown &&
        other.termuxIntegrationEnabled == termuxIntegrationEnabled &&
        other.termuxAutoLaunchEnabled == termuxAutoLaunchEnabled;
  }

  @override
  int get hashCode => Object.hashAll([
    localUrl,
    serverUrl,
    aiServerUrl,
    ttsServerUrl,
    isUrlValid,
    translationProvider,
    showTags,
    showLastRead,
    languageFilter,
    showAudioPlayer,
    currentBookId,
    currentBookLangId,
    currentBookPage,
    currentBookSentenceIndex,
    combineShortSentences,
    showKnownTermsInSentenceReader,
    doubleTapTimeout,
    pageTurnAnimations,
    enableTooltipCaching,
    showStatsBar,
    showPageNumbers,
    ttsProvider,
    aiProvider,
    enableTripleTapToMarkKnown,
    termuxIntegrationEnabled,
    termuxAutoLaunchEnabled,
  ]);

  bool isValidServerUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

@immutable
class ThemeSettings {
  final ThemeType themeType;
  final Color accentLabelColor;
  final Color accentButtonColor;
  final Color? customAccentLabelColor;
  final Color? customAccentButtonColor;

  const ThemeSettings({
    this.themeType = ThemeType.dark,
    this.accentLabelColor = const Color(0xFF1976D2),
    this.accentButtonColor = const Color(0xFF6750A4),
    this.customAccentLabelColor,
    this.customAccentButtonColor,
  });

  ThemeSettings copyWith({
    ThemeType? themeType,
    Color? accentLabelColor,
    Color? accentButtonColor,
    Color? customAccentLabelColor,
    Color? customAccentButtonColor,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      accentLabelColor: accentLabelColor ?? this.accentLabelColor,
      accentButtonColor: accentButtonColor ?? this.accentButtonColor,
      customAccentLabelColor:
          customAccentLabelColor ?? this.customAccentLabelColor,
      customAccentButtonColor:
          customAccentButtonColor ?? this.customAccentButtonColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeType == themeType &&
        other.accentLabelColor.hashCode == accentLabelColor.hashCode &&
        other.accentButtonColor.hashCode == accentButtonColor.hashCode &&
        other.customAccentLabelColor?.hashCode ==
            customAccentLabelColor?.hashCode &&
        other.customAccentButtonColor?.hashCode ==
            customAccentButtonColor?.hashCode;
  }

  @override
  int get hashCode => Object.hash(
    themeType,
    accentLabelColor.hashCode,
    accentButtonColor.hashCode,
    customAccentLabelColor?.hashCode,
    customAccentButtonColor?.hashCode,
  );

  static const ThemeSettings defaultSettings = ThemeSettings();
}

@immutable
class BookDisplaySettings {
  final bool showTags;
  final bool showLastRead;

  const BookDisplaySettings({
    required this.showTags,
    required this.showLastRead,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookDisplaySettings &&
        other.showTags == showTags &&
        other.showLastRead == showLastRead;
  }

  @override
  int get hashCode => showTags.hashCode ^ showLastRead.hashCode;
}
