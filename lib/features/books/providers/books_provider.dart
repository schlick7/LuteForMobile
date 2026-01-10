import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../../../shared/providers/network_providers.dart';
import '../../settings/providers/settings_provider.dart';

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
    var list = showArchived ? archivedBooks : activeBooks;
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
    if (!_repository.contentService.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server URL not configured. Please set it in settings.',
      );
      return;
    }

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

  Future<void> refreshBookStats(int bookId, {Duration? timeout}) async {
    try {
      await _repository.refreshBookStats(bookId, timeout: timeout);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<Book> getBookWithStats(int bookId) async {
    try {
      await _repository.refreshBookStats(bookId);
      final active = await _repository.getActiveBooks();
      final archived = await _repository.getArchivedBooks();
      final books = active + archived;
      return books.firstWhere((b) => b.id == bookId);
    } catch (e) {
      throw Exception('Failed to get book with stats: $e');
    }
  }

  Future<Book> getBookWithStatsAfterDelay(int bookId) async {
    try {
      final active = await _repository.getActiveBooks();
      final archived = await _repository.getArchivedBooks();
      final books = active + archived;
      return books.firstWhere((b) => b.id == bookId);
    } catch (e) {
      throw Exception('Failed to get book with stats: $e');
    }
  }

  Future<Book> getUpdatedBook(int bookId) async {
    await _repository.refreshBookStats(bookId);
    final active = await _repository.getActiveBooks();
    final archived = await _repository.getArchivedBooks();
    final books = active + archived;
    final updatedBook = books.firstWhere((b) => b.id == bookId);

    await updateBookInList(updatedBook);
    return updatedBook;
  }

  Future<void> updateBookInList(Book updatedBook) async {
    final isInActive = state.activeBooks.any((b) => b.id == updatedBook.id);
    if (isInActive) {
      final updatedActiveList = List<Book>.from(state.activeBooks);
      final activeIndex = state.activeBooks.indexWhere(
        (b) => b.id == updatedBook.id,
      );
      if (activeIndex != -1) {
        updatedActiveList[activeIndex] = updatedBook;
        state = state.copyWith(activeBooks: updatedActiveList);
      }
    } else {
      final updatedArchivedList = List<Book>.from(state.archivedBooks);
      final archivedIndex = state.archivedBooks.indexWhere(
        (b) => b.id == updatedBook.id,
      );
      if (archivedIndex != -1) {
        updatedArchivedList[archivedIndex] = updatedBook;
        state = state.copyWith(archivedBooks: updatedArchivedList);
      }
    }
  }

  Future<void> archiveBook(int bookId) async {
    try {
      await _repository.archiveBook(bookId);
      final bookToRemove = state.activeBooks.firstWhere(
        (b) => b.id == bookId,
        orElse: () => throw Exception('Book not found'),
      );
      final updatedArchivedBooks = [bookToRemove, ...state.archivedBooks];
      final updatedActiveBooks = state.activeBooks
          .where((b) => b.id != bookId)
          .toList();
      state = state.copyWith(
        activeBooks: updatedActiveBooks,
        archivedBooks: updatedArchivedBooks,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> unarchiveBook(int bookId) async {
    try {
      await _repository.unarchiveBook(bookId);
      final bookToRestore = state.archivedBooks.firstWhere(
        (b) => b.id == bookId,
        orElse: () => throw Exception('Book not found'),
      );
      final updatedActiveBooks = [bookToRestore, ...state.activeBooks];
      final updatedArchivedBooks = state.archivedBooks
          .where((b) => b.id != bookId)
          .toList();
      state = state.copyWith(
        activeBooks: updatedActiveBooks,
        archivedBooks: updatedArchivedBooks,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteBook(int bookId) async {
    try {
      await _repository.deleteBook(bookId);
      final updatedActiveBooks = state.activeBooks
          .where((b) => b.id != bookId)
          .toList();
      final updatedArchivedBooks = state.archivedBooks
          .where((b) => b.id != bookId)
          .toList();
      state = state.copyWith(
        activeBooks: updatedActiveBooks,
        archivedBooks: updatedArchivedBooks,
      );

      final settings = ref.read(settingsProvider);
      if (settings.currentBookId == bookId) {
        ref.read(settingsProvider.notifier).clearCurrentBook();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
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

final languagesProvider = FutureProvider<List<String>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getAllLanguages();
});
