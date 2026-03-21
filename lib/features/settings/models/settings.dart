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
  final bool showKnownTermsCount;
  final bool showTermStatsCard;
  final bool autoLoadTermStatsCards;
  final bool showPageNumbers;
  final TTSProvider? ttsProvider;
  final AIProvider? aiProvider;
  final bool enableTripleTapToMarkKnown;
  final bool enablePagePreload;
  final bool termuxIntegrationEnabled;
  final int statsCalcSampleSize;
  final int stats500SampleSize;
  final int statsRefreshBatchSize;
  final int statsRefreshCooldownHours;
  final bool alwaysRefreshBookDetails;
  final int maxConcurrentTooltipFetches;
  final bool autoRefreshFullStats;
  final bool experimentalBookDetailsFullStatsEndpoint;

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
    this.showKnownTermsCount = false,
    this.showTermStatsCard = false,
    this.autoLoadTermStatsCards = false,
    this.showPageNumbers = true,
    this.ttsProvider,
    this.aiProvider,
    this.enableTripleTapToMarkKnown = false,
    this.enablePagePreload = false,
    this.termuxIntegrationEnabled = false,
    this.statsCalcSampleSize = 5,
    this.stats500SampleSize = 100,
    this.statsRefreshBatchSize = 1,
    this.statsRefreshCooldownHours = 96,
    this.alwaysRefreshBookDetails = true,
    this.maxConcurrentTooltipFetches = 4,
    this.autoRefreshFullStats = false,
    this.experimentalBookDetailsFullStatsEndpoint = false,
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
    bool? showKnownTermsCount,
    bool? showTermStatsCard,
    bool? autoLoadTermStatsCards,
    bool? showPageNumbers,
    TTSProvider? ttsProvider,
    AIProvider? aiProvider,
    bool? enableTripleTapToMarkKnown,
    bool? enablePagePreload,
    bool? termuxIntegrationEnabled,
    int? statsCalcSampleSize,
    int? stats500SampleSize,
    int? statsRefreshBatchSize,
    int? statsRefreshCooldownHours,
    bool? alwaysRefreshBookDetails,
    int? maxConcurrentTooltipFetches,
    bool? autoRefreshFullStats,
    bool? experimentalBookDetailsFullStatsEndpoint,
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
      showKnownTermsCount: showKnownTermsCount ?? this.showKnownTermsCount,
      showTermStatsCard: showTermStatsCard ?? this.showTermStatsCard,
      autoLoadTermStatsCards:
          autoLoadTermStatsCards ?? this.autoLoadTermStatsCards,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      aiProvider: aiProvider ?? this.aiProvider,
      enableTripleTapToMarkKnown:
          enableTripleTapToMarkKnown ?? this.enableTripleTapToMarkKnown,
      enablePagePreload: enablePagePreload ?? this.enablePagePreload,
      termuxIntegrationEnabled:
          termuxIntegrationEnabled ?? this.termuxIntegrationEnabled,
      statsCalcSampleSize: statsCalcSampleSize ?? this.statsCalcSampleSize,
      stats500SampleSize: stats500SampleSize ?? this.stats500SampleSize,
      statsRefreshBatchSize:
          statsRefreshBatchSize ?? this.statsRefreshBatchSize,
      statsRefreshCooldownHours:
          statsRefreshCooldownHours ?? this.statsRefreshCooldownHours,
      alwaysRefreshBookDetails:
          alwaysRefreshBookDetails ?? this.alwaysRefreshBookDetails,
      maxConcurrentTooltipFetches:
          maxConcurrentTooltipFetches ?? this.maxConcurrentTooltipFetches,
      autoRefreshFullStats: autoRefreshFullStats ?? this.autoRefreshFullStats,
      experimentalBookDetailsFullStatsEndpoint:
          experimentalBookDetailsFullStatsEndpoint ??
          this.experimentalBookDetailsFullStatsEndpoint,
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
      showKnownTermsCount: false,
      showTermStatsCard: false,
      autoLoadTermStatsCards: false,
      showPageNumbers: true,
      ttsProvider: TTSProvider.onDevice,
      aiProvider: AIProvider.none,
      enableTripleTapToMarkKnown: false,
      enablePagePreload: false,
      termuxIntegrationEnabled: false,
      statsCalcSampleSize: 5,
      stats500SampleSize: 100,
      statsRefreshBatchSize: 1,
      statsRefreshCooldownHours: 48,
      alwaysRefreshBookDetails: true,
      maxConcurrentTooltipFetches: 4,
      autoRefreshFullStats: false,
      experimentalBookDetailsFullStatsEndpoint: false,
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
        other.showKnownTermsCount == showKnownTermsCount &&
        other.showTermStatsCard == showTermStatsCard &&
        other.autoLoadTermStatsCards == autoLoadTermStatsCards &&
        other.showPageNumbers == showPageNumbers &&
        other.ttsProvider == ttsProvider &&
        other.aiProvider == aiProvider &&
        other.enableTripleTapToMarkKnown == enableTripleTapToMarkKnown &&
        other.enablePagePreload == enablePagePreload &&
        other.termuxIntegrationEnabled == termuxIntegrationEnabled &&
        other.statsCalcSampleSize == statsCalcSampleSize &&
        other.statsRefreshBatchSize == statsRefreshBatchSize &&
        other.statsRefreshCooldownHours == statsRefreshCooldownHours &&
        other.alwaysRefreshBookDetails == alwaysRefreshBookDetails &&
        other.maxConcurrentTooltipFetches == maxConcurrentTooltipFetches &&
        other.autoRefreshFullStats == autoRefreshFullStats &&
        other.experimentalBookDetailsFullStatsEndpoint ==
            experimentalBookDetailsFullStatsEndpoint;
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
    showKnownTermsCount,
    showTermStatsCard,
    autoLoadTermStatsCards,
    showPageNumbers,
    ttsProvider,
    aiProvider,
    enableTripleTapToMarkKnown,
    enablePagePreload,
    termuxIntegrationEnabled,
    statsCalcSampleSize,
    statsRefreshBatchSize,
    statsRefreshCooldownHours,
    alwaysRefreshBookDetails,
    maxConcurrentTooltipFetches,
    autoRefreshFullStats,
    experimentalBookDetailsFullStatsEndpoint,
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
class UserThemeDefinition {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AppThemeColorScheme colorScheme;
  final Map<int, StatusMode> statusModes;

  UserThemeDefinition({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.colorScheme,
    Map<int, StatusMode>? statusModes,
  }) : statusModes = Map.unmodifiable(statusModes ?? defaultStatusModes());

  UserThemeDefinition copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    AppThemeColorScheme? colorScheme,
    Map<int, StatusMode>? statusModes,
  }) {
    return UserThemeDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorScheme: colorScheme ?? this.colorScheme,
      statusModes: statusModes ?? this.statusModes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserThemeDefinition &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.colorScheme == colorScheme &&
        _statusModeMapEquals(other.statusModes, statusModes);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    updatedAt,
    colorScheme,
    Object.hashAll(statusModes.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

enum ThemeInitMode {
  fromDark,
  fromLight,
  fromBlackAndWhite,
  fromCurrent,
  blank,
}

@immutable
class ThemeSettings {
  final ThemeType themeType;
  final String? selectedThemeId;
  final List<UserThemeDefinition> userThemes;

  ThemeSettings({
    this.themeType = ThemeType.dark,
    this.selectedThemeId,
    List<UserThemeDefinition>? userThemes,
  }) : userThemes = List.unmodifiable(userThemes ?? const []);

  UserThemeDefinition? get selectedUserTheme {
    if (selectedThemeId == null) return null;
    for (final theme in userThemes) {
      if (theme.id == selectedThemeId) return theme;
    }
    return null;
  }

  ThemeSettings copyWith({
    ThemeType? themeType,
    String? selectedThemeId,
    bool clearSelectedThemeId = false,
    List<UserThemeDefinition>? userThemes,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      selectedThemeId: clearSelectedThemeId
          ? null
          : (selectedThemeId ?? this.selectedThemeId),
      userThemes: userThemes ?? this.userThemes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeType == themeType &&
        other.selectedThemeId == selectedThemeId &&
        _userThemeListEquals(other.userThemes, userThemes);
  }

  @override
  int get hashCode =>
      Object.hash(themeType, selectedThemeId, Object.hashAll(userThemes));

  static final ThemeSettings defaultSettings = ThemeSettings();
}

bool _userThemeListEquals(
  List<UserThemeDefinition> a,
  List<UserThemeDefinition> b,
) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _statusModeMapEquals(Map<int, StatusMode> a, Map<int, StatusMode> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
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
