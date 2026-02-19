import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/stats/models/stats_cache_entry.dart';
import 'package:lute_for_mobile/features/stats/models/language_stats.dart';
import 'package:lute_for_mobile/shared/providers/network_providers.dart';
import 'package:lute_for_mobile/shared/providers/language_data_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import 'stats_repository_provider.dart';

enum StatsPeriod { week, month, quarter, year, all }

enum StatsFilter { all, activeLanguages }

class StatsNotifier extends AsyncNotifier<StatsState> {
  Completer<StatsState>? _loadStatsCompleter;

  @override
  Future<StatsState> build() async {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.currentBookLangId != next.currentBookLangId) {
        _onLangIdChanged();
      }
    });

    return const StatsState();
  }

  Future<void> _onLangIdChanged() async {
    await loadStats();
  }

  Future<void> loadStats() async {
    // If a request is already in progress, wait for it instead of starting a new one
    if (_loadStatsCompleter != null) {
      await _loadStatsCompleter!.future;
      return;
    }

    // Create a new completer for this request
    final completer = Completer<StatsState>();
    _loadStatsCompleter = completer;

    final contentService = ref.read(contentServiceProvider);
    final statsRepository = ref.read(statsRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final cacheEntry = await statsRepository.fetchAndProcessStats(
          contentService: contentService,
        );
        final languages = cacheEntry.stats.values.toList();

        LanguageReadingStats? selectedLanguage;
        final currentBookLangId = ref.read(settingsProvider).currentBookLangId;
        if (currentBookLangId != null) {
          final languageList = await ref.read(languageListProvider.future);
          try {
            final currentBookLanguage = languageList.firstWhere(
              (lang) => lang.id == currentBookLangId,
            );
            selectedLanguage = languages.firstWhere(
              (lang) => lang.language == currentBookLanguage.name,
            );
          } catch (e) {
            // Language or stats not found, keep selectedLanguage as null
          }
        }

        final result = StatsState(
          isLoading: false,
          cacheEntry: cacheEntry,
          languages: languages,
          selectedLanguage: selectedLanguage,
          selectedPeriod: StatsPeriod.all,
          selectedFilter: StatsFilter.all,
        );

        completer.complete(result);
        return result;
      } catch (e) {
        completer.completeError(e);
        rethrow;
      } finally {
        _loadStatsCompleter = null;
      }
    });
  }

  Future<void> refreshStats() async {
    await ref.read(statsRepositoryProvider).clearCache();
    await loadStats();
  }

  void setPeriod(StatsPeriod period) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(selectedPeriod: period));
    }
  }

  void setLanguage(LanguageReadingStats? language) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(selectedLanguage: language));
    }
  }

  void clearLanguage() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        StatsState(
          isLoading: current.isLoading,
          error: current.error,
          cacheEntry: current.cacheEntry,
          languages: current.languages,
          selectedLanguage: null,
          selectedPeriod: current.selectedPeriod,
          selectedFilter: current.selectedFilter,
        ),
      );
    }
  }

  void setFilter(StatsFilter filter) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(selectedFilter: filter));
    }
  }

  List<LanguageReadingStats> get filteredLanguages {
    final currentState = state.value;
    if (currentState == null) return [];

    var languages = currentState.languages;

    switch (currentState.selectedFilter) {
      case StatsFilter.all:
        break;
      case StatsFilter.activeLanguages:
        languages = languages.where((l) => l.totalWords > 0).toList();
    }

    if (currentState.selectedLanguage != null) {
      languages = languages
          .where((l) => l.language == currentState.selectedLanguage!.language)
          .toList();
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (currentState.selectedPeriod) {
      case StatsPeriod.week:
        startDate = DateTime(now.year, now.month, now.day - 7);
        break;
      case StatsPeriod.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case StatsPeriod.quarter:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case StatsPeriod.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case StatsPeriod.all:
        startDate = DateTime(1970);
        break;
    }

    return languages.map((language) {
      final filteredStats = language.dailyStats
          .where((stat) => !stat.date.isBefore(startDate))
          .toList();

      return language.copyWith(dailyStats: filteredStats);
    }).toList();
  }
}

@immutable
class StatsState {
  final bool isLoading;
  final String? error;
  final StatsCacheEntry? cacheEntry;
  final List<LanguageReadingStats> languages;
  final LanguageReadingStats? selectedLanguage;
  final StatsPeriod selectedPeriod;
  final StatsFilter selectedFilter;

  const StatsState({
    this.isLoading = false,
    this.error,
    this.cacheEntry,
    this.languages = const [],
    this.selectedLanguage,
    this.selectedPeriod = StatsPeriod.all,
    this.selectedFilter = StatsFilter.all,
  });

  StatsState copyWith({
    bool? isLoading,
    String? error,
    StatsCacheEntry? cacheEntry,
    List<LanguageReadingStats>? languages,
    LanguageReadingStats? selectedLanguage,
    StatsPeriod? selectedPeriod,
    StatsFilter? selectedFilter,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      cacheEntry: cacheEntry ?? this.cacheEntry,
      languages: languages ?? this.languages,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, StatsState>(() {
  return StatsNotifier();
});

final statsPeriodProvider = Provider<StatsPeriod>((ref) {
  final state = ref.watch(statsProvider);
  return state.value?.selectedPeriod ?? StatsPeriod.all;
});

final statsLanguagesProvider = Provider<List<LanguageReadingStats>>((ref) {
  final notifier = ref.watch(statsProvider.notifier);
  return notifier.filteredLanguages;
});
