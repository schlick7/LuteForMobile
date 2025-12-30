import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../../reader/providers/reader_provider.dart';

@immutable
class BooksState {
  final bool isLoading;
  final List<Book> activeBooks;
  final List<Book> archivedBooks;
  final bool showArchived;
  final String? errorMessage;
  final String searchQuery;

  const BooksState({
    this.isLoading = false,
    this.activeBooks = const [],
    this.archivedBooks = const [],
    this.showArchived = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  List<Book> get filteredBooks {
    final list = showArchived ? archivedBooks : activeBooks;
    if (searchQuery.isEmpty) return list;
    return list
        .where(
          (book) =>
              book.title.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  BooksState copyWith({
    bool? isLoading,
    List<Book>? activeBooks,
    List<Book>? archivedBooks,
    bool? showArchived,
    String? errorMessage,
    String? searchQuery,
  }) {
    return BooksState(
      isLoading: isLoading ?? this.isLoading,
      activeBooks: activeBooks ?? this.activeBooks,
      archivedBooks: archivedBooks ?? this.archivedBooks,
      showArchived: showArchived ?? this.showArchived,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BooksNotifier extends Notifier<BooksState> {
  late BooksRepository _repository;

  @override
  BooksState build() {
    _repository = ref.watch(booksRepositoryProvider);
    return const BooksState();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final active = await _repository.getActiveBooks();
      final archived = await _repository.getArchivedBooks();
      state = state.copyWith(
        isLoading: false,
        activeBooks: active,
        archivedBooks: archived,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshBooks() async {
    if (state.showArchived) {
      await _refreshArchived();
    } else {
      await _refreshActive();
    }
  }

  Future<void> _refreshActive() async {
    try {
      final active = await _repository.getActiveBooks();
      state = state.copyWith(activeBooks: active, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _refreshArchived() async {
    try {
      final archived = await _repository.getArchivedBooks();
      state = state.copyWith(archivedBooks: archived, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void toggleArchivedFilter() {
    state = state.copyWith(showArchived: !state.showArchived);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refreshAllStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.refreshAllBookStats(
        state.activeBooks + state.archivedBooks,
      );
      await loadBooks();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshBookStats(int bookId) async {
    try {
      await _repository.refreshBookStats(bookId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<Book> getBookWithStats(int bookId) async {
    try {
      await _repository.refreshBookStats(bookId);
      await loadBooks();
      final books = state.activeBooks + state.archivedBooks;
      return books.firstWhere((b) => b.id == bookId);
    } catch (e) {
      throw Exception('Failed to get book with stats: $e');
    }
  }
}

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return BooksRepository(contentService: contentService);
});

final booksProvider = NotifierProvider<BooksNotifier, BooksState>(() {
  return BooksNotifier();
});
