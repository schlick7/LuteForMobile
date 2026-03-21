import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';
import '../../../shared/theme/theme_definitions.dart';
import '../../../shared/theme/theme_presets.dart';
import '../../../shared/theme/theme_serialization.dart';
import '../../../core/cache/providers/cache_manager_provider.dart';
import '../../../features/reader/providers/reader_provider.dart';
import '../../../core/services/termux_service.dart';
import '../../../core/services/server_health_service.dart';
import '../../../shared/providers/server_status_provider.dart';

typedef DrawerSettingsBuilder =
    Widget Function(BuildContext context, WidgetRef ref);

class ViewDrawerSettings {
  final Widget? settingsContent;

  const ViewDrawerSettings({this.settingsContent});

  const ViewDrawerSettings.none() : settingsContent = null;
}

class SettingsNotifier extends Notifier<Settings> {
  static const String _keyLocalUrl = 'local_url';
  static const String _keyUseTermux = 'use_termux';
  static const String _keyTranslationProvider = 'translation_provider';
  static const String _keyShowTags = 'show_tags';
  static const String _keyShowLastRead = 'show_last_read';
  static const String _keyLanguageFilter = 'language_filter';
  static const String _keyShowAudioPlayer = 'show_audio_player';
  static const String _keyCurrentBookId = 'current_book_id';
  static const String _keyCurrentBookLangId = 'current_book_lang_id';
  static const String _keyCurrentBookPage = 'current_book_page';
  static const String _keyCurrentBookSentenceIndex =
      'current_book_sentence_index';
  static const String _keyCombineShortSentences = 'combine_short_sentences';
  static const String _keyShowKnownTermsInSentenceReader =
      'show_known_terms_in_sentence_reader';
  static const String _keyDoubleTapTimeout = 'double_tap_timeout';
  static const String _keyPageTurnAnimations = 'page_turn_animations';
  static const String _keyEnableTooltipCaching = 'enable_tooltip_caching';
  static const String _keyShowStatsBar = 'show_stats_bar';
  static const String _keyShowKnownTermsCount = 'show_known_terms_count';
  static const String _keyShowTermStatsCard = 'show_term_stats_card';
  static const String _keyAutoLoadTermStatsCards = 'auto_load_term_stats_cards';
  static const String _keyShowPageNumbers = 'show_page_numbers';
  static const String _keyEnableTripleTapToMarkKnown =
      'enable_triple_tap_to_mark_known';
  static const String _keyEnablePagePreload = 'enable_page_preload';
  static const String _keyTermuxIntegrationEnabled =
      'termux_integration_enabled';
  static const String _keyStatsCalcSampleSize = 'stats_calc_sample_size';
  static const String _keyStats500SampleSize = 'stats_500_sample_size';
  static const String _keyStatsRefreshBatchSize = 'stats_refresh_batch_size';
  static const String _keyStatsRefreshCooldownHours =
      'stats_refresh_cooldown_hours';
  static const String _keyAlwaysRefreshBookDetails =
      'always_refresh_book_details';
  static const String _keyMaxConcurrentTooltipFetches =
      'max_concurrent_tooltip_fetches';
  static const String _keyAutoRefreshFullStats = 'auto_refresh_full_stats';
  static const String _keyExperimentalBookDetailsFullStatsEndpoint =
      'experimental_book_details_full_stats_endpoint';

  @override
  Settings build() {
    _loadSettings();
    return state;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localUrl = prefs.getString(_keyLocalUrl) ?? '';
    final useTermux = prefs.getBool(_keyUseTermux) ?? false;
    final serverUrl = useTermux ? Settings.termuxUrl : localUrl;

    state = Settings.defaultSettings().copyWith(
      localUrl: localUrl,
      serverUrl: serverUrl,
      isUrlValid: _isValidUrl(serverUrl),
    );

    _loadOtherSettings(prefs);
  }

  Future<void> _loadOtherSettings(SharedPreferences prefs) async {
    final translationProvider =
        prefs.getString(_keyTranslationProvider) ?? 'local';
    final showTags = prefs.getBool(_keyShowTags) ?? true;
    final showLastRead = prefs.getBool(_keyShowLastRead) ?? true;
    final languageFilter = prefs.getString(_keyLanguageFilter);
    final showAudioPlayer = prefs.getBool(_keyShowAudioPlayer) ?? true;
    final combineShortSentences = prefs.getInt(_keyCombineShortSentences) ?? 3;
    final showKnownTermsInSentenceReader =
        prefs.getBool(_keyShowKnownTermsInSentenceReader) ?? true;
    final doubleTapTimeout = prefs.getInt(_keyDoubleTapTimeout) ?? 300;
    final pageTurnAnimations = prefs.getBool(_keyPageTurnAnimations) ?? true;
    final enableTooltipCaching =
        prefs.getBool(_keyEnableTooltipCaching) ?? false;
    final showStatsBar = prefs.getBool(_keyShowStatsBar) ?? true;
    final showKnownTermsCount = prefs.getBool(_keyShowKnownTermsCount) ?? false;
    final showTermStatsCard = prefs.getBool(_keyShowTermStatsCard) ?? false;
    final autoLoadTermStatsCards =
        prefs.getBool(_keyAutoLoadTermStatsCards) ?? false;
    final showPageNumbers = prefs.getBool(_keyShowPageNumbers) ?? true;
    final enableTripleTapToMarkKnown =
        prefs.getBool(_keyEnableTripleTapToMarkKnown) ?? false;
    final enablePagePreload = prefs.getBool(_keyEnablePagePreload) ?? false;
    final termuxIntegrationEnabled =
        prefs.getBool(_keyTermuxIntegrationEnabled) ?? false;
    final statsCalcSampleSize = prefs.getInt(_keyStatsCalcSampleSize) ?? 5;
    final stats500SampleSize = prefs.getInt(_keyStats500SampleSize) ?? 100;
    final statsRefreshBatchSize = prefs.getInt(_keyStatsRefreshBatchSize) ?? 1;
    final statsRefreshCooldownHours =
        prefs.getInt(_keyStatsRefreshCooldownHours) ?? 48;
    final alwaysRefreshBookDetails =
        prefs.getBool(_keyAlwaysRefreshBookDetails) ?? true;
    final maxConcurrentTooltipFetches =
        prefs.getInt(_keyMaxConcurrentTooltipFetches) ?? 4;
    final autoRefreshFullStats =
        prefs.getBool(_keyAutoRefreshFullStats) ?? false;
    final experimentalBookDetailsFullStatsEndpoint =
        prefs.getBool(_keyExperimentalBookDetailsFullStatsEndpoint) ?? false;

    final currentBookId = prefs.getInt(_keyCurrentBookId);
    final currentBookLangId = prefs.getInt(_keyCurrentBookLangId);
    final currentBookPage = prefs.getInt(_keyCurrentBookPage);
    final currentBookSentenceIndex = prefs.getInt(_keyCurrentBookSentenceIndex);

    print(
      'DEBUG: _loadOtherSettings - SharedPreferences currentBookId=$currentBookId, page=$currentBookPage, langId=$currentBookLangId',
    );

    state = state.copyWith(
      translationProvider: translationProvider,
      showTags: showTags,
      showLastRead: showLastRead,
      languageFilter: languageFilter,
      showAudioPlayer: showAudioPlayer,
      currentBookId: currentBookId,
      currentBookLangId: currentBookLangId,
      currentBookPage: currentBookPage,
      currentBookSentenceIndex: currentBookSentenceIndex,
      combineShortSentences: combineShortSentences,
      showKnownTermsInSentenceReader: showKnownTermsInSentenceReader,
      doubleTapTimeout: doubleTapTimeout,
      pageTurnAnimations: pageTurnAnimations,
      enableTooltipCaching: enableTooltipCaching,
      showStatsBar: showStatsBar,
      showKnownTermsCount: showKnownTermsCount,
      showTermStatsCard: showTermStatsCard,
      autoLoadTermStatsCards: autoLoadTermStatsCards,
      showPageNumbers: showPageNumbers,
      enableTripleTapToMarkKnown: enableTripleTapToMarkKnown,
      enablePagePreload: enablePagePreload,
      termuxIntegrationEnabled: termuxIntegrationEnabled,
      statsCalcSampleSize: statsCalcSampleSize,
      stats500SampleSize: stats500SampleSize,
      statsRefreshBatchSize: statsRefreshBatchSize,
      statsRefreshCooldownHours: statsRefreshCooldownHours,
      alwaysRefreshBookDetails: alwaysRefreshBookDetails,
      maxConcurrentTooltipFetches: maxConcurrentTooltipFetches,
      autoRefreshFullStats: autoRefreshFullStats,
      experimentalBookDetailsFullStatsEndpoint:
          experimentalBookDetailsFullStatsEndpoint,
    );
  }

  Future<void> updateLocalUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final previousServerUrl = state.serverUrl;
    await prefs.setString(_keyLocalUrl, url);
    final isValid = _isValidUrl(url);
    final serverUrl = prefs.getBool(_keyUseTermux) ?? false
        ? Settings.termuxUrl
        : url;
    state = state.copyWith(
      localUrl: url,
      serverUrl: serverUrl,
      isUrlValid: isValid,
    );

    if (previousServerUrl != state.serverUrl) {
      await ref.read(cacheManagerProvider).clearServerDependentCaches();
      await clearCurrentBook();
      ref.read(readerProvider.notifier).clearPageData();
    }
  }

  Future<void> setServerSelection(bool useTermux) async {
    final prefs = await SharedPreferences.getInstance();
    final previousServerUrl = state.serverUrl;
    await prefs.setBool(_keyUseTermux, useTermux);

    if (useTermux) {
      state = state.copyWith(serverUrl: Settings.termuxUrl, isUrlValid: true);
      await TermuxService.startServer();
    } else {
      final localUrl = prefs.getString(_keyLocalUrl) ?? '';
      final isValid = _isValidUrl(localUrl);
      state = state.copyWith(serverUrl: localUrl, isUrlValid: isValid);
    }

    if (previousServerUrl != state.serverUrl) {
      await ref.read(cacheManagerProvider).clearServerDependentCaches();
      await clearCurrentBook();
      ref.read(readerProvider.notifier).clearPageData();
    }

    final isReachable = await ServerHealthService.isReachable(state.serverUrl);
    ServerStatusManager.setReachable(isReachable);
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

  Future<void> updateCurrentBook(int bookId, [int? page, int? langId]) async {
    print(
      'DEBUG: updateCurrentBook - saving bookId=$bookId, page=$page, langId=$langId',
    );
    state = state.copyWith(
      currentBookId: bookId,
      currentBookLangId: langId,
      currentBookPage: page,
      currentBookSentenceIndex: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentBookId, bookId);
    if (langId != null) {
      await prefs.setInt(_keyCurrentBookLangId, langId);
    }
    if (page != null) {
      await prefs.setInt(_keyCurrentBookPage, page);
    }
    await prefs.remove(_keyCurrentBookSentenceIndex);
    print(
      'DEBUG: updateCurrentBook - saved to SharedPreferences: bookId=$bookId, page=$page, langId=$langId',
    );
  }

  Future<void> clearCurrentBook() async {
    state = state.copyWith(
      currentBookId: null,
      currentBookLangId: null,
      currentBookPage: null,
      currentBookSentenceIndex: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentBookId);
    await prefs.remove(_keyCurrentBookLangId);
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

  Future<void> updateCurrentBookPage(int page) async {
    state = state.copyWith(
      currentBookPage: page,
      currentBookSentenceIndex: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentBookPage, page);
    await prefs.remove(_keyCurrentBookSentenceIndex);
  }

  Future<void> updateCombineShortSentences(int threshold) async {
    state = state.copyWith(combineShortSentences: threshold);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCombineShortSentences, threshold);
  }

  Future<void> updateDoubleTapTimeout(int timeout) async {
    state = state.copyWith(doubleTapTimeout: timeout);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDoubleTapTimeout, timeout);
  }

  Future<void> updatePageTurnAnimations(bool enabled) async {
    state = state.copyWith(pageTurnAnimations: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPageTurnAnimations, enabled);
  }

  Future<void> updateEnableTooltipCaching(bool enabled) async {
    state = state.copyWith(enableTooltipCaching: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableTooltipCaching, enabled);
  }

  Future<void> updateShowStatsBar(bool show) async {
    state = state.copyWith(showStatsBar: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowStatsBar, show);
  }

  Future<void> updateShowKnownTermsCount(bool show) async {
    state = state.copyWith(showKnownTermsCount: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowKnownTermsCount, show);
  }

  Future<void> updateShowTermStatsCard(bool show) async {
    state = state.copyWith(showTermStatsCard: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTermStatsCard, show);
  }

  Future<void> updateAutoLoadTermStatsCards(bool enabled) async {
    state = state.copyWith(autoLoadTermStatsCards: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoLoadTermStatsCards, enabled);
  }

  Future<void> updateShowPageNumbers(bool show) async {
    state = state.copyWith(showPageNumbers: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPageNumbers, show);
  }

  Future<void> updateEnableTripleTapToMarkKnown(bool enabled) async {
    state = state.copyWith(enableTripleTapToMarkKnown: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableTripleTapToMarkKnown, enabled);
  }

  Future<void> updateEnablePagePreload(bool enabled) async {
    state = state.copyWith(enablePagePreload: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnablePagePreload, enabled);
  }

  Future<void> updateTermuxIntegrationEnabled(bool enabled) async {
    state = state.copyWith(termuxIntegrationEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTermuxIntegrationEnabled, enabled);
  }

  Future<void> updateStatsCalcSampleSize(int value) async {
    state = state.copyWith(statsCalcSampleSize: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStatsCalcSampleSize, value);
  }

  Future<void> updateStats500SampleSize(int value) async {
    state = state.copyWith(stats500SampleSize: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStats500SampleSize, value);
  }

  Future<void> updateStatsRefreshBatchSize(int value) async {
    state = state.copyWith(statsRefreshBatchSize: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStatsRefreshBatchSize, value);
  }

  Future<void> updateStatsRefreshCooldownHours(int value) async {
    state = state.copyWith(statsRefreshCooldownHours: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStatsRefreshCooldownHours, value);
  }

  Future<void> updateAlwaysRefreshBookDetails(bool value) async {
    state = state.copyWith(alwaysRefreshBookDetails: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlwaysRefreshBookDetails, value);
  }

  Future<void> updateMaxConcurrentTooltipFetches(int value) async {
    state = state.copyWith(maxConcurrentTooltipFetches: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxConcurrentTooltipFetches, value);
  }

  Future<void> updateAutoRefreshFullStats(bool value) async {
    state = state.copyWith(autoRefreshFullStats: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoRefreshFullStats, value);
  }

  Future<void> updateExperimentalBookDetailsFullStatsEndpoint(
    bool value,
  ) async {
    state = state.copyWith(experimentalBookDetailsFullStatsEndpoint: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExperimentalBookDetailsFullStatsEndpoint, value);
    state = state.copyWith(alwaysRefreshBookDetails: value);
    await prefs.setBool(_keyAlwaysRefreshBookDetails, value);
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
    await prefs.remove(_keyLocalUrl);
    await prefs.remove(_keyUseTermux);
    await prefs.remove(_keyTranslationProvider);
    await prefs.remove(_keyShowTags);
    await prefs.remove(_keyShowLastRead);
    await prefs.remove(_keyLanguageFilter);
    await prefs.remove(_keyShowAudioPlayer);
    await prefs.remove(_keyCurrentBookId);
    await prefs.remove(_keyCurrentBookPage);
    await prefs.remove(_keyCurrentBookSentenceIndex);
    await prefs.remove(_keyCombineShortSentences);
    await prefs.remove(_keyDoubleTapTimeout);
    await prefs.remove(_keyPageTurnAnimations);
    await prefs.remove(_keyEnableTooltipCaching);
    await prefs.remove(_keyShowStatsBar);
    await prefs.remove(_keyShowKnownTermsCount);
    await prefs.remove(_keyShowTermStatsCard);
    await prefs.remove(_keyAutoLoadTermStatsCards);
    await prefs.remove(_keyShowPageNumbers);
    await prefs.remove(_keyEnableTripleTapToMarkKnown);
    await prefs.remove(_keyStatsCalcSampleSize);
    await prefs.remove(_keyStatsRefreshBatchSize);
    await prefs.remove(_keyStatsRefreshCooldownHours);
    await prefs.remove(_keyAlwaysRefreshBookDetails);
    await prefs.remove(_keyAutoRefreshFullStats);
    await prefs.remove(_keyExperimentalBookDetailsFullStatsEndpoint);

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
  final bool autoSave;
  final bool showParentsInDictionary;
  final bool wordGlowEnabled;
  final bool autoAddAITranslations;
  final bool autoFetchAITranslationsForStatus0;

  const TermFormSettings({
    this.showRomanization = true,
    this.showTags = false,
    this.autoSave = true,
    this.showParentsInDictionary = true,
    this.wordGlowEnabled = true,
    this.autoAddAITranslations = false,
    this.autoFetchAITranslationsForStatus0 = true,
  });

  TermFormSettings copyWith({
    bool? showRomanization,
    bool? showTags,
    bool? autoSave,
    bool? showParentsInDictionary,
    bool? wordGlowEnabled,
    bool? autoAddAITranslations,
    bool? autoFetchAITranslationsForStatus0,
  }) {
    return TermFormSettings(
      showRomanization: showRomanization ?? this.showRomanization,
      showTags: showTags ?? this.showTags,
      autoSave: autoSave ?? this.autoSave,
      showParentsInDictionary:
          showParentsInDictionary ?? this.showParentsInDictionary,
      wordGlowEnabled: wordGlowEnabled ?? this.wordGlowEnabled,
      autoAddAITranslations:
          autoAddAITranslations ?? this.autoAddAITranslations,
      autoFetchAITranslationsForStatus0:
          autoFetchAITranslationsForStatus0 ??
          this.autoFetchAITranslationsForStatus0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TermFormSettings &&
        other.showRomanization == showRomanization &&
        other.showTags == showTags &&
        other.autoSave == autoSave &&
        other.showParentsInDictionary == showParentsInDictionary &&
        other.wordGlowEnabled == wordGlowEnabled &&
        other.autoAddAITranslations == autoAddAITranslations &&
        other.autoFetchAITranslationsForStatus0 ==
            autoFetchAITranslationsForStatus0;
  }

  @override
  int get hashCode =>
      showRomanization.hashCode ^
      showTags.hashCode ^
      autoSave.hashCode ^
      showParentsInDictionary.hashCode ^
      wordGlowEnabled.hashCode ^
      autoAddAITranslations.hashCode ^
      autoFetchAITranslationsForStatus0.hashCode;

  static const TermFormSettings defaultSettings = TermFormSettings();
}

class TermFormSettingsNotifier extends Notifier<TermFormSettings> {
  static const String _keyShowRomanization = 'show_romanization';
  static const String _keyShowTags = 'show_tags';
  static const String _keyAutoSave = 'auto_save';
  static const String _keyShowParentsInDictionary =
      'show_parents_in_dictionary';
  static const String _keyWordGlowEnabled = 'word_glow_enabled';
  static const String _keyAutoAddAITranslations = 'auto_add_ai_translations';
  static const String _keyAutoFetchAITranslationsForStatus0 =
      'auto_fetch_ai_translations_for_status0';
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
    final showTags = prefs.getBool(_keyShowTags) ?? false;
    final autoSave = prefs.getBool(_keyAutoSave) ?? true;
    final showParentsInDictionary =
        prefs.getBool(_keyShowParentsInDictionary) ?? true;
    final wordGlowEnabled = prefs.getBool(_keyWordGlowEnabled) ?? true;
    final autoAddAITranslations =
        prefs.getBool(_keyAutoAddAITranslations) ?? false;
    final autoFetchAITranslationsForStatus0 =
        prefs.getBool(_keyAutoFetchAITranslationsForStatus0) ?? true;

    final loadedSettings = TermFormSettings(
      showRomanization: showRomanization,
      showTags: showTags,
      autoSave: autoSave,
      showParentsInDictionary: showParentsInDictionary,
      wordGlowEnabled: wordGlowEnabled,
      autoAddAITranslations: autoAddAITranslations,
      autoFetchAITranslationsForStatus0: autoFetchAITranslationsForStatus0,
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

  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSave, autoSave);
  }

  Future<void> updateShowParentsInDictionary(bool show) async {
    state = state.copyWith(showParentsInDictionary: show);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowParentsInDictionary, show);
  }

  Future<void> updateWordGlowEnabled(bool enabled) async {
    state = state.copyWith(wordGlowEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWordGlowEnabled, enabled);
  }

  Future<void> updateAutoAddAITranslations(bool enabled) async {
    state = state.copyWith(autoAddAITranslations: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoAddAITranslations, enabled);
  }

  Future<void> updateAutoFetchAITranslationsForStatus0(bool enabled) async {
    state = state.copyWith(autoFetchAITranslationsForStatus0: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoFetchAITranslationsForStatus0, enabled);
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
  final bool fullscreenMode;
  final bool swipeNavigationEnabled;
  final bool swipeMarksRead;

  const TextFormattingSettings({
    this.textSize = 20.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'LinBiolinum',
    this.fontWeight = FontWeight.w500,
    this.isItalic = false,
    this.fullscreenMode = false,
    this.swipeNavigationEnabled = false,
    this.swipeMarksRead = true,
  });

  TextFormattingSettings copyWith({
    double? textSize,
    double? lineSpacing,
    String? fontFamily,
    FontWeight? fontWeight,
    bool? isItalic,
    bool? fullscreenMode,
    bool? swipeNavigationEnabled,
    bool? swipeMarksRead,
  }) {
    return TextFormattingSettings(
      textSize: textSize ?? this.textSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      isItalic: isItalic ?? this.isItalic,
      fullscreenMode: fullscreenMode ?? this.fullscreenMode,
      swipeNavigationEnabled:
          swipeNavigationEnabled ?? this.swipeNavigationEnabled,
      swipeMarksRead: swipeMarksRead ?? this.swipeMarksRead,
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
        other.isItalic == isItalic &&
        other.fullscreenMode == fullscreenMode &&
        other.swipeNavigationEnabled == swipeNavigationEnabled &&
        other.swipeMarksRead == swipeMarksRead;
  }

  @override
  int get hashCode => Object.hash(
    textSize,
    lineSpacing,
    fontFamily,
    fontWeight,
    isItalic,
    fullscreenMode,
    swipeNavigationEnabled,
    swipeMarksRead,
  );

  static const TextFormattingSettings defaultSettings =
      TextFormattingSettings();
}

class TextFormattingSettingsNotifier extends Notifier<TextFormattingSettings> {
  static const String _keyTextSize = 'text_size';
  static const String _keyLineSpacing = 'line_spacing';
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontWeight = 'font_weight';
  static const String _keyIsItalic = 'is_italic';
  static const String _keyFullscreenMode = 'fullscreen_mode';
  static const String _keySwipeNavigationEnabled = 'swipe_navigation_enabled';
  static const String _keySwipeMarksRead = 'swipe_marks_read';
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
    final textSize = prefs.getDouble(_keyTextSize) ?? 20.0;
    final lineSpacing = prefs.getDouble(_keyLineSpacing) ?? 1.5;
    final fontFamily = prefs.getString(_keyFontFamily) ?? 'LinBiolinum';
    final fontWeightIndex = prefs.getInt(_keyFontWeight) ?? 3;
    final isItalic = prefs.getBool(_keyIsItalic) ?? false;
    final fullscreenMode = prefs.getBool(_keyFullscreenMode) ?? false;
    final swipeNavigationEnabled =
        prefs.getBool(_keySwipeNavigationEnabled) ?? false;
    final swipeMarksRead = prefs.getBool(_keySwipeMarksRead) ?? true;

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
      fullscreenMode: fullscreenMode,
      swipeNavigationEnabled: swipeNavigationEnabled,
      swipeMarksRead: swipeMarksRead,
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

  Future<void> updateFullscreenMode(bool fullscreen) async {
    state = state.copyWith(fullscreenMode: fullscreen);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFullscreenMode, fullscreen);
  }

  Future<void> updateSwipeMarksRead(bool value) async {
    state = state.copyWith(swipeMarksRead: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySwipeMarksRead, value);
  }

  Future<void> updateSwipeNavigationEnabled(bool value) async {
    state = state.copyWith(swipeNavigationEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySwipeNavigationEnabled, value);
  }
}

final textFormattingSettingsProvider =
    NotifierProvider<TextFormattingSettingsNotifier, TextFormattingSettings>(
      () {
        return TextFormattingSettingsNotifier();
      },
    );

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const String _themeTypeKey = 'themeType'; // legacy key
  static const String _keyThemeBuiltInType = 'themeBuiltInType';
  static const String _keySelectedThemeId = 'selectedThemeId';
  static const String _keyUserThemesJson = 'userThemesJson';
  static const String _keyThemeDataVersion = 'themeDataVersion';
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
    final themeTypeValue =
        prefs.getString(_keyThemeBuiltInType) ?? prefs.getString(_themeTypeKey);
    final themeType = themeTypeValue != null
        ? ThemeType.values.firstWhere(
            (e) => e.name == themeTypeValue,
            orElse: () => ThemeType.dark,
          )
        : ThemeType.dark;
    final selectedThemeId = prefs.getString(_keySelectedThemeId);
    final userThemesJson = prefs.getString(_keyUserThemesJson);

    final userThemes = <UserThemeDefinition>[];
    if (userThemesJson != null && userThemesJson.isNotEmpty) {
      try {
        final parsed = jsonDecode(userThemesJson) as List<dynamic>;
        for (final item in parsed) {
          if (item is Map<String, dynamic>) {
            final theme = ThemeSerialization.userThemeFromJson(item);
            if (theme != null) userThemes.add(theme);
          } else if (item is Map) {
            final theme = ThemeSerialization.userThemeFromJson(
              Map<String, dynamic>.from(item),
            );
            if (theme != null) userThemes.add(theme);
          }
        }
      } catch (_) {}
    }

    final resolvedSelectedThemeId =
        selectedThemeId != null &&
            userThemes.any((theme) => theme.id == selectedThemeId)
        ? selectedThemeId
        : null;

    final loadedSettings = ThemeSettings(
      themeType: themeType,
      selectedThemeId: resolvedSelectedThemeId,
      userThemes: userThemes,
    );

    if (state != loadedSettings) {
      state = loadedSettings;
    }
  }

  Future<void> selectBuiltInTheme(ThemeType themeType) async {
    state = state.copyWith(themeType: themeType, clearSelectedThemeId: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeBuiltInType, themeType.name);
    await prefs.remove(_keySelectedThemeId);
    await prefs.setString(_themeTypeKey, themeType.name);
  }

  Future<void> updateThemeType(ThemeType themeType) async {
    await selectBuiltInTheme(themeType);
  }

  Future<void> selectUserTheme(String themeId) async {
    if (!state.userThemes.any((theme) => theme.id == themeId)) return;
    state = state.copyWith(selectedThemeId: themeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedThemeId, themeId);
  }

  Future<String> createTheme({
    required String name,
    required ThemeInitMode mode,
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final baseScheme = _schemeForInitMode(mode);
    final baseStatusModes = _statusModesForInitMode(mode);
    final newTheme = UserThemeDefinition(
      id: id,
      name: name.trim().isEmpty ? 'Custom Theme' : name.trim(),
      createdAt: now,
      updatedAt: now,
      colorScheme: baseScheme,
      statusModes: baseStatusModes,
    );
    final updatedThemes = [...state.userThemes, newTheme];
    state = state.copyWith(selectedThemeId: id, userThemes: updatedThemes);
    await _saveThemeCollection();
    return id;
  }

  Future<void> renameTheme(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final updatedThemes = state.userThemes
        .map(
          (theme) => theme.id == id
              ? theme.copyWith(name: trimmed, updatedAt: DateTime.now())
              : theme,
        )
        .toList();
    state = state.copyWith(userThemes: updatedThemes);
    await _saveThemeCollection();
  }

  Future<void> updateThemeScheme(String id, AppThemeColorScheme scheme) async {
    final updatedThemes = state.userThemes
        .map(
          (theme) => theme.id == id
              ? theme.copyWith(colorScheme: scheme, updatedAt: DateTime.now())
              : theme,
        )
        .toList();
    state = state.copyWith(userThemes: updatedThemes);
    await _saveThemeCollection();
  }

  Future<void> updateThemeStatusMode(
    String id,
    int status,
    StatusMode mode,
  ) async {
    final updatedThemes = state.userThemes.map((theme) {
      if (theme.id != id) return theme;
      final updatedModes = Map<int, StatusMode>.from(theme.statusModes);
      updatedModes[status] = mode;
      return theme.copyWith(
        statusModes: updatedModes,
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(userThemes: updatedThemes);
    await _saveThemeCollection();
  }

  Future<void> duplicateTheme(String id) async {
    UserThemeDefinition? source;
    for (final theme in state.userThemes) {
      if (theme.id == id) {
        source = theme;
        break;
      }
    }
    if (source == null) return;
    final now = DateTime.now();
    final duplicate = UserThemeDefinition(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${source.name} Copy',
      createdAt: now,
      updatedAt: now,
      colorScheme: source.colorScheme,
      statusModes: source.statusModes,
    );
    state = state.copyWith(
      selectedThemeId: duplicate.id,
      userThemes: [...state.userThemes, duplicate],
    );
    await _saveThemeCollection();
  }

  Future<void> deleteTheme(String id) async {
    final updatedThemes = state.userThemes
        .where((theme) => theme.id != id)
        .toList();
    final shouldClearSelected = state.selectedThemeId == id;
    state = state.copyWith(
      userThemes: updatedThemes,
      clearSelectedThemeId: shouldClearSelected,
    );
    await _saveThemeCollection();
  }

  Future<void> resetThemeToPreset(String id, ThemeType preset) async {
    final presetScheme = _getPresetScheme(preset);
    final updatedThemes = state.userThemes
        .map(
          (theme) => theme.id == id
              ? theme.copyWith(
                  colorScheme: presetScheme,
                  statusModes: defaultStatusModes(),
                  updatedAt: DateTime.now(),
                )
              : theme,
        )
        .toList();
    state = state.copyWith(userThemes: updatedThemes);
    await _saveThemeCollection();
  }

  Future<void> resetThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeTypeKey);
    await prefs.remove(_keyThemeBuiltInType);
    await prefs.remove(_keySelectedThemeId);
    await prefs.remove(_keyUserThemesJson);
    await prefs.remove(_keyThemeDataVersion);

    state = ThemeSettings.defaultSettings;
  }

  Future<void> _saveThemeCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeBuiltInType, state.themeType.name);
    await prefs.setString(_themeTypeKey, state.themeType.name);
    if (state.selectedThemeId == null) {
      await prefs.remove(_keySelectedThemeId);
    } else {
      await prefs.setString(_keySelectedThemeId, state.selectedThemeId!);
    }
    final encodedThemes = jsonEncode(
      state.userThemes.map(ThemeSerialization.userThemeToJson).toList(),
    );
    await prefs.setString(_keyUserThemesJson, encodedThemes);
    await prefs.setInt(_keyThemeDataVersion, 2);
  }

  AppThemeColorScheme _schemeForInitMode(ThemeInitMode mode) {
    switch (mode) {
      case ThemeInitMode.fromDark:
        return darkThemePreset;
      case ThemeInitMode.fromLight:
        return lightThemePreset;
      case ThemeInitMode.fromBlackAndWhite:
        return blackAndWhiteThemePreset;
      case ThemeInitMode.fromCurrent:
        final selectedTheme = state.selectedUserTheme;
        if (selectedTheme != null) return selectedTheme.colorScheme;
        return _getPresetScheme(state.themeType);
      case ThemeInitMode.blank:
        return _blankScheme();
    }
  }

  Map<int, StatusMode> _statusModesForInitMode(ThemeInitMode mode) {
    if (mode == ThemeInitMode.fromCurrent) {
      final selectedTheme = state.selectedUserTheme;
      if (selectedTheme != null) {
        return Map<int, StatusMode>.from(selectedTheme.statusModes);
      }
    }
    return defaultStatusModes();
  }

  AppThemeColorScheme _getPresetScheme(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return lightThemePreset;
      case ThemeType.dark:
        return darkThemePreset;
      case ThemeType.blackAndWhite:
        return blackAndWhiteThemePreset;
    }
  }

  AppThemeColorScheme _blankScheme() {
    return const AppThemeColorScheme(
      text: TextColors(
        primary: Color(0xFF000000),
        secondary: Color(0xFF333333),
        disabled: Color(0xFF999999),
        headline: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onPrimaryContainer: Color(0xFF000000),
        onSecondaryContainer: Color(0xFF000000),
        onTertiary: Color(0xFFFFFFFF),
        onTertiaryContainer: Color(0xFF000000),
      ),
      background: BackgroundColors(
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFF2F2F2),
        surfaceContainerHighest: Color(0xFFEAEAEA),
      ),
      semantic: SemanticColors(
        success: Color(0xFF2E7D32),
        onSuccess: Color(0xFFFFFFFF),
        warning: Color(0xFFED6C02),
        onWarning: Color(0xFFFFFFFF),
        error: Color(0xFFD32F2F),
        onError: Color(0xFFFFFFFF),
        info: Color(0xFF1565C0),
        onInfo: Color(0xFFFFFFFF),
        connected: Color(0xFF2E7D32),
        disconnected: Color(0xFFD32F2F),
        aiProvider: Color(0xFF6A1B9A),
        localProvider: Color(0xFF1565C0),
      ),
      status: StatusColors(
        status0: Color(0xFF808080),
        status1: Color(0xFFB46B7A),
        status2: Color(0xFFBA8050),
        status3: Color(0xFFBD9C7B),
        status4: Color(0xFF756D6B),
        status5: Color(0xFF77706E),
        status98: Color(0xFF756D6B),
        status99: Color(0xFF419252),
        highlightedText: Color(0xFFFFFFFF),
        wordGlowColor: Color(0xFFFFD700),
      ),
      border: BorderColors(
        outline: Color(0xFF8A8A8A),
        outlineVariant: Color(0xFFCFCFCF),
        dividerColor: Color(0xFFCFCFCF),
      ),
      audio: AudioColors(
        background: Color(0xFF6750A4),
        icon: Color(0xFFFFFFFF),
        bookmark: Color(0xFFFFA000),
        error: Color(0xFFD32F2F),
        errorBackground: Color(0x33FFCDD2),
      ),
      error: ErrorColors(error: Color(0xFFD32F2F), onError: Color(0xFFFFFFFF)),
      material3: Material3ColorScheme(
        primary: Color(0xFF6750A4),
        secondary: Color(0xFF625B71),
        tertiary: Color(0xFF7D5260),
        primaryContainer: Color(0xFFEADDFF),
        secondaryContainer: Color(0xFFE8DEF8),
        tertiaryContainer: Color(0xFFFFD8E4),
      ),
    );
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
