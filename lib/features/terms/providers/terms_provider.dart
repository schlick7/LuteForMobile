import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
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
  late TermsRepository _repository;
  final int _pageSize = 50;
  bool _isLoadingMore = false;

  @override
  TermsState build() {
    _repository = ref.watch(termsRepositoryProvider);
    return const TermsState();
  }

  void resetForNewNavigation() {
    print('DEBUG resetForNewNavigation: called');
    state = state.copyWith(isInitialized: false);
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

    if (!_repository.contentService.isConfigured) {
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

      final newTerms = await _repository.getTermsPaginated(
        langId: langId,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: state.currentPage,
        pageSize: _pageSize,
        selectedStatuses: filteredStatuses.isEmpty ? null : filteredStatuses,
      );

      print('DEBUG loadTerms: loaded ${newTerms.length} terms');

      state = state.copyWith(
        isLoading: false,
        terms: reset ? newTerms : [...state.terms, ...newTerms],
        currentPage: state.currentPage + 1,
        hasMore: newTerms.length == _pageSize,
        errorMessage: null,
      );

      if (langId != null && reset) {
        loadStats(langId);
      }
    } catch (e) {
      print('DEBUG loadTerms: error $e');
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
    print('DEBUG setLanguageFilter: $langId');
    state = state.copyWith(selectedLangId: langId);
    loadTerms(reset: true);
    if (langId != null) {
      loadStats(langId);
    }
  }

  Future<void> loadStats(int langId) async {
    try {
      final stats = await _repository.getTermStats(langId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      print('DEBUG loadStats: error $e');
    }
  }

  void setStatusFilter(String? status) {
    print(
      'DEBUG setStatusFilter: $status, current selectedStatuses: ${state.selectedStatuses}',
    );
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
      await _repository.deleteTerm(termId);
      state = state.copyWith(
        terms: state.terms.where((t) => t.id != termId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refreshTerms() async {
    await loadTerms(reset: true);
  }
}

final termsProvider = NotifierProvider<TermsNotifier, TermsState>(() {
  return TermsNotifier();
});
