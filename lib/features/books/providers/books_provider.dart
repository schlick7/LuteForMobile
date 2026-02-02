import 'package:flutter/foundation.dart';
import 'dart:async';
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
  bool _isRefreshingBook = false;
  int? _originalSampleSize;
  bool _refreshRequestedAfterNavigate = false;
  bool _isLoadingArchivedBooks = false;
  bool _isLoadingFromNetwork = false;
  bool _isLoadingBooks = false;
  int? _lastBackgroundRefreshTime;

  @override
  BooksState build() {
    _repository = ref.watch(booksRepositoryProvider);
    return const BooksState();
  }

  Future<void> loadBooks({bool forceRefresh = false}) async {
    if (_isLoadingBooks) {
      print('DEBUG: loadBooks() skipped - already loading');
      return;
    }

    print('DEBUG: loadBooks() called, forceRefresh=$forceRefresh');
    _isLoadingBooks = true;

    if (!_repository.contentService.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server URL not configured. Please set it in settings.',
      );
      _isLoadingBooks = false;
      return;
    }

    if (forceRefresh) {
      _lastBackgroundRefreshTime = null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final activeFromCache = await _repository.getActiveBooksFromCache();
      final archivedFromCache = await _repository.getArchivedBooksFromCache();

      print(
        'DEBUG: loadBooks() - cache activeFromCache=${activeFromCache != null}, first book hasStats=${activeFromCache?.first.hasStats ?? "N/A"}, count=${activeFromCache?.length ?? 0}',
      );

      if (activeFromCache != null) {
        state = state.copyWith(
          isLoading: false,
          activeBooks: activeFromCache,
          archivedBooks: archivedFromCache ?? state.archivedBooks,
        );
        _backgroundRefreshExpiredBooks();
      } else {
        state = state.copyWith(isLoading: false);
        await _loadBooksFromNetwork();
        _backgroundRefreshExpiredBooks();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error loading books from cache: $e');
    } finally {
      _isLoadingBooks = false;
    }
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
    final cooldown = Duration(hours: 6);

    if (_lastBackgroundRefreshTime != null) {
      final timeSinceLastRefresh = now - _lastBackgroundRefreshTime!;
      if (timeSinceLastRefresh < cooldown.inMilliseconds) {
        print(
          'DEBUG: Background refresh skipped - cooldown active (${(timeSinceLastRefresh / 1000 / 60).toStringAsFixed(0)} mins since last refresh)',
        );
        return;
      }
    }

    final expiredBooks = state.activeBooks.where((book) {
      if (book.lastStatsRefresh == null) return true;
      final age = now - book.lastStatsRefresh!;
      return age > ttl.inMilliseconds;
    }).toList();

    print(
      'DEBUG: _backgroundRefreshExpiredBooks - ${expiredBooks.length} expired books out of ${state.activeBooks.length} total, first book hasStats=${state.activeBooks.first.hasStats}, distinctTerms=${state.activeBooks.first.distinctTerms}',
    );

    if (expiredBooks.isEmpty) {
      _lastBackgroundRefreshTime = now;
      return;
    }

    try {
      await _repository.invalidateAllBookStatsCache();

      _originalSampleSize ??= await _repository.contentService
          .getStatsSampleSize();
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        '500',
      );

      final updatedActiveBooks = List<Book>.from(state.activeBooks);

      for (int i = 0; i < expiredBooks.length; i += 2) {
        final batch = <Future<void>>[];
        if (i < expiredBooks.length) {
          batch.add(
            _refreshBookSimple(
              expiredBooks[i].id,
              updatedBooksList: updatedActiveBooks,
            ),
          );
        }
        if (i + 1 < expiredBooks.length) {
          batch.add(
            _refreshBookSimple(
              expiredBooks[i + 1].id,
              updatedBooksList: updatedActiveBooks,
            ),
          );
        }
        await Future.wait(batch);
      }

      await _repository.saveBooksToCache(
        activeBooks: updatedActiveBooks,
        archivedBooks: state.archivedBooks,
      );

      print(
        'DEBUG: Updating state with ${updatedActiveBooks.length} books, first book hasStats=${updatedActiveBooks.first.hasStats}, distinctTerms=${updatedActiveBooks.first.distinctTerms}',
      );
      state = state.copyWith(activeBooks: updatedActiveBooks);
    } finally {
      if (_originalSampleSize != null) {
        try {
          await _repository.contentService.setUserSetting(
            'stats_calc_sample_size',
            _originalSampleSize!.toString(),
          );
        } catch (e) {
          print('Failed to restore sample size: $e');
        }
      }
    }

    _lastBackgroundRefreshTime = now;
  }

  Future<void> _refreshBookSimple(
    int bookId, {
    List<Book>? updatedBooksList,
  }) async {
    print(
      'DEBUG: _refreshBookSimple called for bookId=$bookId at ${DateTime.now().millisecondsSinceEpoch}',
    );

    final booksList = updatedBooksList ?? state.activeBooks;
    final existingBook = booksList.firstWhere(
      (book) => book.id == bookId,
      orElse: () =>
          throw Exception('Book with id $bookId not found in active books'),
    );
    final statsBook = await _repository.contentService.getBookStats(bookId);
    print(
      'DEBUG: Refresh stats for book $bookId - distinctTerms: ${statsBook.distinctTerms}, unknownPct: ${statsBook.unknownPct}, statusDistribution: ${statsBook.statusDistribution}',
    );
    final updatedBook = existingBook.copyWith(
      distinctTerms: statsBook.distinctTerms,
      unknownPct: statsBook.unknownPct,
      statusDistribution: statsBook.statusDistribution,
      lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
    );

    if (updatedBooksList != null) {
      final index = updatedBooksList.indexWhere((book) => book.id == bookId);
      if (index != -1) {
        updatedBooksList[index] = updatedBook;
      }
    }
  }

  Future<void> _refreshBookWith500SampleSize(
    int bookId, {
    List<Book>? updatedBooksList,
  }) async {
    if (_isRefreshingBook) {
      _refreshRequestedAfterNavigate = true;
      return;
    }

    _isRefreshingBook = true;
    _refreshRequestedAfterNavigate = false;

    try {
      _originalSampleSize ??= await _repository.contentService
          .getStatsSampleSize();
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        '500',
      );
      await _repository.refreshBookStats(
        bookId,
        timeout: const Duration(seconds: 15),
      );
      await Future.delayed(const Duration(seconds: 1));

      // Get the existing book from the provided list or from the current state
      final booksList = updatedBooksList ?? state.activeBooks;
      final existingBook = booksList.firstWhere(
        (book) => book.id == bookId,
        orElse: () =>
            throw Exception('Book with id $bookId not found in active books'),
      );
      final statsBook = await _repository.contentService.getBookStats(bookId);
      final updatedBook = existingBook.copyWith(
        distinctTerms: statsBook.distinctTerms,
        unknownPct: statsBook.unknownPct,
        statusDistribution: statsBook.statusDistribution,
        lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
      );

      // Update only the specific book in the provided list or in the state
      if (updatedBooksList != null) {
        final index = updatedBooksList.indexWhere((book) => book.id == bookId);
        if (index != -1) {
          updatedBooksList[index] = updatedBook;
        }
      } else {
        // Update the state normally (for non-batch updates)
        final updatedActiveBooks = state.activeBooks.map((book) {
          if (book.id == bookId) {
            return book.copyWith(
              title: updatedBook.title,
              language: updatedBook.language,
              langId: updatedBook.langId,
              totalPages: updatedBook.totalPages,
              currentPage: updatedBook.currentPage,
              percent: updatedBook.percent,
              wordCount: updatedBook.wordCount,
              distinctTerms: updatedBook.distinctTerms,
              unknownPct: updatedBook.unknownPct,
              statusDistribution: updatedBook.statusDistribution,
              tags: updatedBook.tags,
              lastRead: updatedBook.lastRead,
              isCompleted: updatedBook.isCompleted,
              lastStatsRefresh: updatedBook.lastStatsRefresh,
              audioFilename: updatedBook.audioFilename,
            );
          }
          return book;
        }).toList();

        state = state.copyWith(
          activeBooks: updatedActiveBooks,
          archivedBooks: state.archivedBooks,
        );

        // Save to cache asynchronously without waiting to avoid blocking the UI
        // This reduces the frequency of cache writes while still persisting the changes
        // Only do this when NOT in batch mode (batch mode handles its own save)
        if (updatedBooksList == null) {
          () async {
            try {
              await _repository.saveBooksToCache(
                activeBooks: updatedActiveBooks,
                archivedBooks: state.archivedBooks,
              );
            } catch (e) {
              print('Cache save error: $e');
            }
          }();
        }
      }
    } finally {
      _isRefreshingBook = false;
      if (_originalSampleSize != null) {
        try {
          await _repository.contentService.setUserSetting(
            'stats_calc_sample_size',
            _originalSampleSize!.toString(),
          );
        } catch (e) {
          print('Failed to restore sample size: $e');
        }
        _originalSampleSize = null;
      }
      if (_refreshRequestedAfterNavigate) {
        _refreshRequestedAfterNavigate = false;
        final currentBookId = state.currentBookId;
        if (currentBookId != null) {
          await _refreshBookWith500SampleSize(currentBookId);
        }
      }
    }
  }

  Future<void> _loadBooksFromNetwork() async {
    if (_isLoadingFromNetwork) return;
    _isLoadingFromNetwork = true;

    try {
      final networkBooks = await _repository.getActiveBooks();
      print(
        'DEBUG: _loadBooksFromNetwork - got ${networkBooks.length} books from network, first book hasStats=${networkBooks.first.hasStats}, distinctTerms=${networkBooks.first.distinctTerms}',
      );

      final existingBookIds = {for (var b in state.activeBooks) b.id};
      final newBooks = networkBooks
          .where((b) => !existingBookIds.contains(b.id))
          .toList();

      print(
        'DEBUG: _loadBooksFromNetwork - ${newBooks.length} new books (out of ${networkBooks.length}), ${existingBookIds.length} existing books',
      );

      final finalActiveBooks = [...state.activeBooks, ...newBooks];

      await _repository.saveBooksToCache(
        activeBooks: finalActiveBooks,
        archivedBooks: state.archivedBooks,
      );

      state = state.copyWith(
        isLoading: false,
        activeBooks: finalActiveBooks,
        archivedBooks: state.archivedBooks,
        errorMessage: null,
      );
      _lastBackgroundRefreshTime = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      _isLoadingFromNetwork = false;
    }
  }

  Future<void> _loadArchivedBooksFromNetwork() async {
    try {
      final archived = await _repository.getArchivedBooks();
      final existingArchivedMap = {for (var b in state.archivedBooks) b.id: b};

      final mergedArchived = archived.map((networkBook) {
        final existing = existingArchivedMap[networkBook.id];
        if (existing != null) {
          final shouldUseNetworkStats =
              networkBook.hasStats &&
              (!existing.hasStats ||
                  networkBook.distinctTerms != null ||
                  networkBook.statusDistribution != null);
          return existing.copyWith(
            title: networkBook.title,
            language: networkBook.language,
            langId: existing.langId,
            totalPages: networkBook.totalPages,
            currentPage: networkBook.currentPage,
            percent: networkBook.percent,
            wordCount: networkBook.wordCount,
            distinctTerms:
                shouldUseNetworkStats && networkBook.distinctTerms != null
                ? networkBook.distinctTerms
                : existing.distinctTerms,
            unknownPct: shouldUseNetworkStats && networkBook.unknownPct != null
                ? networkBook.unknownPct
                : existing.unknownPct,
            statusDistribution:
                shouldUseNetworkStats && networkBook.statusDistribution != null
                ? networkBook.statusDistribution
                : existing.statusDistribution,
            tags: networkBook.tags,
            lastRead: networkBook.lastRead,
            isCompleted: networkBook.isCompleted,
            lastStatsRefresh: shouldUseNetworkStats
                ? DateTime.now().millisecondsSinceEpoch
                : existing.lastStatsRefresh,
          );
        }
        return networkBook;
      }).toList();

      await _repository.saveBooksToCache(
        activeBooks: state.activeBooks,
        archivedBooks: mergedArchived,
      );

      state = state.copyWith(archivedBooks: mergedArchived, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refreshBooks() async {
    if (_isLoadingFromNetwork) {
      print('DEBUG: refreshBooks() skipped - already loading');
      return;
    }
    if (state.showArchived) {
      await _refreshArchived();
    } else {
      await _refreshActive();
    }
  }

  Future<void> _refreshActive() async {
    if (_isLoadingFromNetwork) {
      print('DEBUG: _refreshActive() skipped - already loading');
      return;
    }
    _isLoadingFromNetwork = true;

    try {
      final networkBooks = await _repository.getActiveBooks();
      final archived = state.archivedBooks;

      final existingBookIds = {for (var b in state.activeBooks) b.id};
      final newBooks = networkBooks
          .where((b) => !existingBookIds.contains(b.id))
          .toList();

      final finalActiveBooks = [...state.activeBooks, ...newBooks];

      await _repository.saveBooksToCache(
        activeBooks: finalActiveBooks,
        archivedBooks: archived,
      );

      state = state.copyWith(activeBooks: finalActiveBooks, errorMessage: null);
      _lastBackgroundRefreshTime = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      _isLoadingFromNetwork = false;
    }
  }

  Future<void> _refreshArchived() async {
    if (_isLoadingFromNetwork) {
      print('DEBUG: _refreshArchived() skipped - already loading');
      return;
    }
    _isLoadingFromNetwork = true;

    try {
      final networkBooks = await _repository.getArchivedBooks();
      final active = state.activeBooks;

      final existingArchivedIds = {for (var b in state.archivedBooks) b.id};
      final newArchivedBooks = networkBooks
          .where((b) => !existingArchivedIds.contains(b.id))
          .toList();

      final finalArchivedBooks = [...state.archivedBooks, ...newArchivedBooks];

      await _repository.saveBooksToCache(
        activeBooks: active,
        archivedBooks: finalArchivedBooks,
      );

      state = state.copyWith(
        archivedBooks: finalArchivedBooks,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      _isLoadingFromNetwork = false;
    }
  }

  void toggleArchivedFilter() {
    final newShowArchived = !state.showArchived;
    state = state.copyWith(showArchived: newShowArchived);

    if (newShowArchived &&
        state.archivedBooks.isEmpty &&
        !_isLoadingArchivedBooks) {
      _isLoadingArchivedBooks = true;
      _loadArchivedBooksFromNetwork().then((_) {
        _isLoadingArchivedBooks = false;
      });
    }
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
      await _repository.invalidateAllBookStatsCache();

      _originalSampleSize ??= await _repository.contentService
          .getStatsSampleSize();
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        '500',
      );

      final activeBooksToRefresh = state.activeBooks;
      final updatedActiveBooks = List<Book>.from(state.activeBooks);

      for (int i = 0; i < activeBooksToRefresh.length; i += 2) {
        final batch = <Future<void>>[];
        if (i < activeBooksToRefresh.length) {
          batch.add(
            _refreshBookSimple(
              activeBooksToRefresh[i].id,
              updatedBooksList: updatedActiveBooks,
            ),
          );
        }
        if (i + 1 < activeBooksToRefresh.length) {
          batch.add(
            _refreshBookSimple(
              activeBooksToRefresh[i + 1].id,
              updatedBooksList: updatedActiveBooks,
            ),
          );
        }
        await Future.wait(batch);
      }

      await _repository.saveBooksToCache(
        activeBooks: updatedActiveBooks,
        archivedBooks: state.archivedBooks,
      );

      state = state.copyWith(
        isLoading: false,
        activeBooks: updatedActiveBooks,
        archivedBooks: state.archivedBooks,
      );
      _lastBackgroundRefreshTime = DateTime.now().millisecondsSinceEpoch;

      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        '100',
      );
    } catch (e) {
      try {
        await _repository.contentService.setUserSetting(
          'stats_calc_sample_size',
          '100',
        );
      } catch (err) {
        print('Failed to restore sample size: $err');
      }
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
    final books = isArchived ? state.archivedBooks : state.activeBooks;

    final existingBook = books.firstWhere(
      (b) => b.id == bookId,
      orElse: () => throw Exception('Book not found'),
    );

    await _repository.refreshBookStats(bookId);
    final statsBook = await _repository.contentService.getBookStats(bookId);

    final updatedBook = existingBook.copyWith(
      distinctTerms: statsBook.distinctTerms,
      unknownPct: statsBook.unknownPct,
      statusDistribution: statsBook.statusDistribution,
      lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
    );

    if (isArchived) {
      final updatedArchived = state.archivedBooks
          .map((b) => b.id == bookId ? updatedBook : b)
          .toList();
      state = state.copyWith(archivedBooks: updatedArchived);
    } else {
      final updatedActive = state.activeBooks
          .map((b) => b.id == bookId ? updatedBook : b)
          .toList();
      state = state.copyWith(activeBooks: updatedActive);
    }

    await _repository.saveBooksToCache(
      activeBooks: state.activeBooks,
      archivedBooks: state.archivedBooks,
    );

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
