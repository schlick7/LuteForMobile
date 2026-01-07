import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/term.dart';
import '../repositories/terms_repository.dart';
import '../../settings/providers/settings_provider.dart';
import '../../books/providers/books_provider.dart';

@immutable
class TermsState {
  final bool isLoading;
  final List<Term> terms;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final int? selectedLangId;
  final String? selectedStatus;
  final String? errorMessage;

  const TermsState({
    this.isLoading = false,
    this.terms = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.searchQuery = '',
    this.selectedLangId,
    this.selectedStatus,
    this.errorMessage,
  });

  TermsState copyWith({
    bool? isLoading,
    List<Term>? terms,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    int? selectedLangId,
    String? selectedStatus,
    String? errorMessage,
  }) {
    return TermsState(
      isLoading: isLoading ?? this.isLoading,
      terms: terms ?? this.terms,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLangId: selectedLangId ?? this.selectedLangId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage,
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
      await _setLanguageFilter();

      final newTerms = await _repository.getTermsPaginated(
        langId: state.selectedLangId,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: state.currentPage,
        pageSize: _pageSize,
        status: state.selectedStatus,
      );

      state = state.copyWith(
        isLoading: false,
        terms: reset ? newTerms : [...state.terms, ...newTerms],
        currentPage: state.currentPage + 1,
        hasMore: newTerms.length == _pageSize,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) return;
    _isLoadingMore = true;
    await loadTerms(reset: false);
    _isLoadingMore = false;
  }

  Future<void> _setLanguageFilter() async {
    final currentBookId = ref.read(settingsProvider).currentBookId;

    if (currentBookId == null) {
      state = state.copyWith(selectedLangId: null);
      return;
    }

    final booksState = ref.read(booksProvider);
    final allBooks = [...booksState.activeBooks, ...booksState.archivedBooks];
    final book = allBooks.firstWhere(
      (b) => b.id == currentBookId,
      orElse: () => allBooks.isNotEmpty
          ? allBooks.first
          : Book(
              id: 0,
              title: '',
              langId: 0,
              totalPages: 0,
              currentPage: 0,
              percent: 0,
              wordCount: 0,
              distinctTerms: null,
              unknownPct: null,
              statusDistribution: null,
            ),
    );
    state = state.copyWith(selectedLangId: book.langId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTerms(reset: true);
  }

  void setLanguageFilter(int? langId) {
    state = state.copyWith(selectedLangId: langId);
    loadTerms(reset: true);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
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
