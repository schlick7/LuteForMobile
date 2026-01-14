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
  final int? currentBookId;

  const BooksState({
    this.isLoading = false,
    this.activeBooks = const [],
    this.archivedBooks = const [],
    this.showArchived = false,
    this.errorMessage,
    this.searchQuery = '',
    this.currentBookId,
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
    int? currentBookId,
  }) {
    return BooksState(
      isLoading: isLoading ?? this.isLoading,
      activeBooks: activeBooks ?? this.activeBooks,
      archivedBooks: archivedBooks ?? this.archivedBooks,
      showArchived: showArchived ?? this.showArchived,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      currentBookId: currentBookId ?? this.currentBookId,
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
      final activeFromCache = await _repository.getActiveBooksFromCache();
      final archivedFromCache = await _repository.getArchivedBooksFromCache();

      if (activeFromCache != null || archivedFromCache != null) {
        state = state.copyWith(
          isLoading: false,
          activeBooks: activeFromCache ?? state.activeBooks,
          archivedBooks: archivedFromCache ?? state.archivedBooks,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error loading books from cache: $e');
    }

    _loadBooksFromNetwork();
    _backgroundRefreshExpiredBooks();
  }

  void setCurrentBook(int? bookId) {
    if (bookId != null && bookId != state.currentBookId) {
      state = state.copyWith(currentBookId: bookId);
      _refreshCurrentBook();
    }
  }

  Future<void> _refreshCurrentBook() async {
    final currentBookId = state.currentBookId;
    if (currentBookId == null) return;

    final book = state.activeBooks.firstWhere(
      (b) => b.id == currentBookId,
      orElse: () => state.archivedBooks.firstWhere(
        (b) => b.id == currentBookId,
        orElse: () => throw Exception('Book not found'),
      ),
    );

    if (state.archivedBooks.any((b) => b.id == currentBookId)) {
      return;
    }

    await _refreshBookWith500SampleSize(book.id);
  }

  Future<void> _backgroundRefreshExpiredBooks() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ttl = Duration(hours: 48);

    final expiredBooks = state.activeBooks.where((book) {
      if (book.lastStatsRefresh == null) return true;
      final age = now - book.lastStatsRefresh!;
      return age > ttl.inMilliseconds;
    }).toList();

    if (expiredBooks.isEmpty) return;

    for (int i = 0; i < expiredBooks.length; i += 2) {
      final batch = <Future<void>>[];
      if (i < expiredBooks.length) {
        batch.add(
          _refreshBookWith500SampleSize(expiredBooks[i].id).catchError((e) {
            print('Failed to refresh stats for book ${expiredBooks[i].id}: $e');
          }),
        );
      }
      if (i + 1 < expiredBooks.length) {
        batch.add(
          _refreshBookWith500SampleSize(expiredBooks[i + 1].id).catchError((e) {
            print(
              'Failed to refresh stats for book ${expiredBooks[i + 1].id}: $e',
            );
          }),
        );
      }
      await Future.wait(batch);
    }
  }

  Future<void> _refreshBookWith500SampleSize(int bookId) async {
    try {
      final originalSampleSize = await _repository.contentService
          .getStatsSampleSize();
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        '500',
      );
      await _repository.refreshBookStats(
        bookId,
        timeout: const Duration(seconds: 15),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        originalSampleSize.toString(),
      );

      final active = await _repository.getActiveBooks();
      final archived = state.archivedBooks;

      final existingActiveMap = {for (var b in state.activeBooks) b.id: b};

      final mergedActive = active.map((networkBook) {
        final existing = existingActiveMap[networkBook.id];
        if (existing != null) {
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: networkBook.distinctTerms,
            unknownPct: networkBook.unknownPct,
            statusDistribution: networkBook.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
            lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
          );
        }
        return networkBook.copyWith(
          lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: mergedActive,
        archivedBooks: archived,
      );

      state = state.copyWith(
        activeBooks: mergedActive,
        archivedBooks: archived,
      );
    } catch (e) {
      print('Error refreshing book with 500 sample size: $e');
    }
  }

  Future<void> _loadBooksFromNetwork() async {
    try {
      final active = await _repository.getActiveBooks();
      final archived = await _repository.getArchivedBooks();

      final existingActiveMap = {for (var b in state.activeBooks) b.id: b};
      final existingArchivedMap = {for (var b in state.archivedBooks) b.id: b};

      final mergedActive = active.map((networkBook) {
        final existing = existingActiveMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
            lastStatsRefresh: existing.lastStatsRefresh,
          );
        }
        return networkBook;
      }).toList();

      final mergedArchived = archived.map((networkBook) {
        final existing = existingArchivedMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
            lastStatsRefresh: existing.lastStatsRefresh,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: mergedActive,
        archivedBooks: mergedArchived,
      );

      state = state.copyWith(
        isLoading: false,
        activeBooks: mergedActive,
        archivedBooks: mergedArchived,
        errorMessage: null,
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
      final archived = state.archivedBooks;

      final existingActiveMap = {for (var b in state.activeBooks) b.id: b};

      final mergedActive = active.map((networkBook) {
        final existing = existingActiveMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: mergedActive,
        archivedBooks: archived,
      );

      state = state.copyWith(activeBooks: mergedActive, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _refreshArchived() async {
    try {
      final archived = await _repository.getArchivedBooks();
      final active = state.activeBooks;

      final existingArchivedMap = {for (var b in state.archivedBooks) b.id: b};

      final mergedArchived = archived.map((networkBook) {
        final existing = existingArchivedMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: active,
        archivedBooks: mergedArchived,
      );

      state = state.copyWith(archivedBooks: mergedArchived, errorMessage: null);
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
    final isArchived = state.archivedBooks.any((b) => b.id == bookId);

    if (isArchived) {
      await _repository.refreshBookStats(bookId);
      final archived = await _repository.getArchivedBooks();
      final active = state.activeBooks;

      final existingArchivedMap = {for (var b in state.archivedBooks) b.id: b};

      final mergedArchived = archived.map((networkBook) {
        final existing = existingArchivedMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: active,
        archivedBooks: mergedArchived,
      );

      state = state.copyWith(
        activeBooks: active,
        archivedBooks: mergedArchived,
      );
      return mergedArchived.firstWhere((b) => b.id == bookId);
    } else {
      await _repository.refreshBookStats(bookId);
      final active = await _repository.getActiveBooks();
      final archived = state.archivedBooks;

      final existingActiveMap = {for (var b in state.activeBooks) b.id: b};

      final mergedActive = active.map((networkBook) {
        final existing = existingActiveMap[networkBook.id];
        if (existing != null) {
          final shouldUpdateStats = !existing.hasStats && networkBook.hasStats;
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms: shouldUpdateStats
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUpdateStats
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution: shouldUpdateStats
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: mergedActive,
        archivedBooks: archived,
      );

      state = state.copyWith(
        activeBooks: mergedActive,
        archivedBooks: archived,
      );
      return mergedActive.firstWhere((b) => b.id == bookId);
    }
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

      await _repository.saveBooksToCache(
        activeBooks: updatedActiveBooks,
        archivedBooks: updatedArchivedBooks,
      );

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

  Future<void> invalidateCacheForBookLanguage(int bookId) async {
    final book = state.activeBooks.firstWhere(
      (b) => b.id == bookId,
      orElse: () => state.archivedBooks.firstWhere(
        (b) => b.id == bookId,
        orElse: () => throw Exception('Book not found'),
      ),
    );

    await _repository.invalidateLanguageCache(book.language);
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
