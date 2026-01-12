import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/stats/repositories/stats_repository.dart';
import 'package:lute_for_mobile/features/stats/models/stats_cache_entry.dart';
import 'package:lute_for_mobile/features/stats/models/language_stats.dart';
import 'package:lute_for_mobile/core/network/content_service.dart';
import 'package:lute_for_mobile/shared/providers/network_providers.dart';

enum StatsPeriod { week, month, quarter, year, all }

enum StatsFilter { all, activeLanguages }

class StatsNotifier extends AsyncNotifier<StatsState> {
  late final ContentService _contentService;

  @override
  Future<StatsState> build() async {
    final ref = this.ref;
    final apiService = ref.watch(apiServiceProvider);
    _contentService = ContentService(apiService: apiService);
    return const StatsState();
  }

  Future<void> loadStats() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cacheEntry = await StatsRepository.fetchAndProcessStats(
        contentService: _contentService,
      );
      final languages = cacheEntry.stats.values.toList();
      return StatsState(
        isLoading: false,
        cacheEntry: cacheEntry,
        languages: languages,
        selectedLanguage: null,
        selectedPeriod: StatsPeriod.all,
        selectedFilter: StatsFilter.all,
      );
    });
  }

  Future<void> refreshStats() async {
    await StatsRepository.clearCache();
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
