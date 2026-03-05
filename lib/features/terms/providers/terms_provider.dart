import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../../core/logger/api_logger.dart';
import '../models/term.dart';
import '../models/term_stats.dart';
import '../repositories/terms_repository.dart';
import '../../settings/providers/settings_provider.dart';

@immutable
class TermsState {
  final bool isLoading;
  final List<Term> terms;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final int? selectedLangId;
  final Set<String?> selectedStatuses;
  final String? errorMessage;
  final bool isInitialized;
  final TermStats stats;

  const TermsState({
    this.isLoading = false,
    this.terms = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.searchQuery = '',
    this.selectedLangId,
    this.selectedStatuses = const {'1', '2', '3', '4', '5', '99'},
    this.errorMessage,
    this.isInitialized = false,
    this.stats = TermStats.empty,
  });

  TermsState copyWith({
    bool? isLoading,
    List<Term>? terms,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    int? selectedLangId,
    Set<String?>? selectedStatuses,
    String? errorMessage,
    bool? isInitialized,
    TermStats? stats,
  }) {
    return TermsState(
      isLoading: isLoading ?? this.isLoading,
      terms: terms ?? this.terms,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLangId: selectedLangId ?? this.selectedLangId,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      stats: stats ?? this.stats,
    );
  }
}

class TermsNotifier extends Notifier<TermsState> {
  final int _pageSize = 20;
  bool _isLoadingMore = false;

  bool _status99LoadInProgress = false;
  int? _lastStatus99LangId;
  DateTime? _lastStatus99LoadTime;
  Timer? _status99DebounceTimer;

  @override
  TermsState build() {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.serverUrl != next.serverUrl) {
        _onServerChanged();
      }
      if (previous?.currentBookLangId != next.currentBookLangId) {
        _onLangIdChanged();
      }
    });

    return const TermsState();
  }

  void _onServerChanged() {
    state = state.copyWith(isInitialized: false);
    loadTerms(reset: true);
  }

  Future<void> _onLangIdChanged() async {
    state = state.copyWith(isInitialized: false, errorMessage: null);
    await loadTerms(reset: true);
  }

  Future<void> loadTerms({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        terms: [],
        currentPage: 0,
        hasMore: true,
        errorMessage: null,
      );
    }

    final repository = ref.read(termsRepositoryProvider);

    if (!repository.contentService.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server URL not configured.',
      );
      return;
    }

    try {
      int? langId = state.selectedLangId;

      if (!state.isInitialized) {
        final currentBookLangId = ref.read(settingsProvider).currentBookLangId;
        state = state.copyWith(
          selectedLangId: currentBookLangId,
          isInitialized: true,
        );
        langId = currentBookLangId;
      }

      final filteredStatuses = state.selectedStatuses
          .whereType<String>()
          .toSet();

      print(
        'DEBUG loadTerms: langId=$langId, search="${state.searchQuery}", statuses=$filteredStatuses',
      );

      final newTerms = await repository.getTermsPaginated(
        langId: langId,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: state.currentPage,
        pageSize: _pageSize,
        selectedStatuses: filteredStatuses.isEmpty ? null : filteredStatuses,
      );

      state = state.copyWith(
        isLoading: false,
        terms: reset ? newTerms : [...state.terms, ...newTerms],
        currentPage: state.currentPage + 1,
        hasMore: newTerms.length == _pageSize,
        errorMessage: null,
      );

      if (langId != null && reset) {
        if (ref.read(settingsProvider).showTermStatsCard) {
          loadStats(langId);
        }
      }
    } catch (e) {
      ApiLogger.logError('loadTerms', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) return;
    _isLoadingMore = true;
    await loadTerms(reset: false);
    _isLoadingMore = false;
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTerms(reset: true);
  }

  void setLanguageFilter(int? langId) {
    state = state.copyWith(selectedLangId: langId);
    loadTerms(reset: true);
    if (langId != null) {
      if (ref.read(settingsProvider).showTermStatsCard) {
        loadStats(langId);
      }
    }
  }

  Future<void> loadStats(int langId) async {
    if (!ref.read(settingsProvider).showKnownTermsCount) {
      return;
    }
    if (!ref.read(settingsProvider).showTermStatsCard) {
      return;
    }
    try {
      final repository = ref.read(termsRepositoryProvider);
      final stats = await repository.getTermStats(langId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      ApiLogger.logError('loadStats', e);
    }
  }

  Future<void> loadStatus99Only(int langId) async {
    if (!ref.read(settingsProvider).showKnownTermsCount) {
      return;
    }

    _status99DebounceTimer?.cancel();
    _status99DebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeLoadStatus99(langId);
    });
  }

  Future<void> _executeLoadStatus99(int langId) async {
    final now = DateTime.now();
    if (_status99LoadInProgress) {
      return;
    }
    if (_lastStatus99LangId == langId &&
        _lastStatus99LoadTime != null &&
        now.difference(_lastStatus99LoadTime!).inSeconds < 3) {
      return;
    }

    _status99LoadInProgress = true;
    try {
      final repository = ref.read(termsRepositoryProvider);
      final count = await repository.contentService.getTermCount(
        langId: langId,
        statusMin: 99,
        statusMax: 99,
      );

      final currentStats = state.stats;
      final newStats = TermStats(
        status1: currentStats.status1,
        status2: currentStats.status2,
        status3: currentStats.status3,
        status4: currentStats.status4,
        status5: currentStats.status5,
        status99: count,
        total:
            currentStats.status1 +
            currentStats.status2 +
            currentStats.status3 +
            currentStats.status4 +
            currentStats.status5 +
            count,
      );
      state = state.copyWith(stats: newStats);

      _lastStatus99LangId = langId;
      _lastStatus99LoadTime = DateTime.now();
    } catch (e) {
      ApiLogger.logError('loadStatus99Only', e);
    } finally {
      _status99LoadInProgress = false;
    }
  }

  void setStatusFilter(String? status) {
    final newStatuses = Set<String?>.from(state.selectedStatuses);
    if (status == null) {
      final allDefaultSelected = {
        '1',
        '2',
        '3',
        '4',
        '5',
        '99',
      }.every((s) => newStatuses.contains(s));
      if (allDefaultSelected) {
        newStatuses.clear();
      } else {
        newStatuses.addAll(['1', '2', '3', '4', '5', '99']);
      }
    } else {
      if (newStatuses.contains(status)) {
        newStatuses.remove(status);
      } else {
        newStatuses.add(status);
      }
    }
    state = state.copyWith(selectedStatuses: newStatuses);
    loadTerms(reset: true);
  }

  void clearStatuses() {
    state = state.copyWith(
      selectedStatuses: const {'1', '2', '3', '4', '5', '99'},
    );
    loadTerms(reset: true);
  }

  Future<void> deleteTerm(int termId) async {
    try {
      final repository = ref.read(termsRepositoryProvider);
      await repository.deleteTerm(termId);
      state = state.copyWith(
        terms: state.terms.where((t) => t.id != termId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void updateTermInList(Term updatedTerm) {
    final updatedTerms = state.terms.map((term) {
      if (term.id == updatedTerm.id) {
        return updatedTerm;
      }
      return term;
    }).toList();
    state = state.copyWith(terms: updatedTerms);
  }

  Future<void> refreshTerms() async {
    await loadTerms(reset: true);
  }
}

final termsProvider = NotifierProvider<TermsNotifier, TermsState>(() {
  return TermsNotifier();
});
