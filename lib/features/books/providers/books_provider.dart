import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../../core/logger/api_logger.dart';
import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../../../shared/providers/network_providers.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/providers/app_startup_providers.dart';

@immutable
class BooksState {
  final bool isLoading;
  final bool isRefreshing;
  final List<Book> activeBooks;
  final List<Book> archivedBooks;
  final bool showArchived;
  final String? errorMessage;
  final String searchQuery;
  final int? currentBookId;

  const BooksState({
    this.isLoading = false,
    this.isRefreshing = false,
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
    bool? isRefreshing,
    List<Book>? activeBooks,
    List<Book>? archivedBooks,
    bool? showArchived,
    String? errorMessage,
    String? searchQuery,
    int? currentBookId,
  }) {
    return BooksState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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
  bool _refreshRequestedAfterNavigate = false;
  bool _isLoadingArchivedBooks = false;
  bool _isLoadingFromNetwork = false;
  bool _isLoadingBooks = false;
  bool _isBackgroundRefreshing = false;
  int? _lastBackgroundRefreshTime;
  String? _previousServerUrl;
  bool _isInitialized = false;

  @override
  BooksState build() {
    _repository = ref.watch(booksRepositoryProvider);
    final settings = ref.watch(settingsProvider);

    // Reset loading flags on each build to prevent stuck states
    _isLoadingBooks = false;
    _isLoadingFromNetwork = false;
    _isBackgroundRefreshing = false;

    // Always initialize on first build of this notifier instance
    if (!_isInitialized) {
      _isInitialized = true;
      _previousServerUrl = settings.serverUrl;
      Future.microtask(() => _waitForReaderAndLoadBooks());
    } else if (_previousServerUrl != settings.serverUrl) {
      _previousServerUrl = settings.serverUrl;
      Future.microtask(() => _onServerChanged());
    }

    return const BooksState();
  }

  /// Waits for reader to signal ready, then loads books.
  /// Uses a 10-second fallback if reader never signals (e.g., user opens books screen directly).
  Future<void> _waitForReaderAndLoadBooks() async {
    // Check if reader is already ready
    if (ref.read(readerReadinessProvider)) {
      await _loadBooksAndSignalComplete();
      return;
    }

    // Set up a listener for reader readiness
    bool booksLoaded = false;
    late ProviderSubscription<bool> subscription;
    subscription = ref.listen(readerReadinessProvider, (previous, next) {
      if (next == true && !booksLoaded) {
        booksLoaded = true;
        subscription.close();
        _loadBooksAndSignalComplete();
      }
    });

    // Fallback: load books after 10 seconds if reader never signals ready
    Future.delayed(const Duration(seconds: 10), () {
      if (!booksLoaded) {
        booksLoaded = true;
        subscription.close();
        _loadBooksAndSignalComplete();
      }
    });
  }

  /// Loads books and signals completion (even on error, since cache might have partial data).
  Future<void> _loadBooksAndSignalComplete() async {
    try {
      await loadBooks(forceRefresh: true);
    } finally {
      // Signal that books loading is complete, even if there was an error
      // (partial cache data may still be valuable)
      ref.read(booksLoadingCompleteProvider.notifier).markComplete();
    }
  }

  Future<void> _onServerChanged() async {
    state = state.copyWith(
      activeBooks: const [],
      archivedBooks: const [],
      errorMessage: null,
    );
    _repository.resetLanguageMap();
    await loadBooks(forceRefresh: true);
  }

  Future<void> loadBooks({
    bool forceRefresh = false,
    bool skipExpiredBookRefresh = false,
  }) async {
    if (_isLoadingBooks) {
      return;
    }

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

      final hasCachedBooks =
          activeFromCache != null && activeFromCache.isNotEmpty;
      ApiLogger.logCache(
        'loadBooks',
        details:
            'hasCachedBooks=$hasCachedBooks, count=${activeFromCache?.length ?? 0}',
      );

      if (hasCachedBooks) {
        state = state.copyWith(
          isLoading: false,
          activeBooks: activeFromCache,
          archivedBooks: archivedFromCache ?? state.archivedBooks,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      await _loadBooksFromNetwork();
      // Only refresh expired books in background if not explicitly skipped.
      // Skip when followed by a full refresh (e.g., pull-to-refresh).
      if (!skipExpiredBookRefresh) {
        refreshExpiredBooks();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ApiLogger.logError('loadBooksFromCache', e);
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

  Future<void> refreshExpiredBooks({bool forceRefreshAll = false}) async {
    if (_isBackgroundRefreshing) {
      return;
    }
    _isBackgroundRefreshing = true;

    final now = DateTime.now().millisecondsSinceEpoch;
    const globalCooldownMs = 120 * 1000;

    if (_lastBackgroundRefreshTime != null) {
      final timeSinceLastRefresh = now - _lastBackgroundRefreshTime!;
      if (timeSinceLastRefresh < globalCooldownMs) {
        _isBackgroundRefreshing = false;
        return;
      }
    }

    if (forceRefreshAll) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    }

    try {
      final settings = ref.read(settingsProvider);
      final perBookCooldown = Duration(
        hours: settings.statsRefreshCooldownHours,
      );

      final booksToRefresh = forceRefreshAll
          ? state.activeBooks
          : state.activeBooks.where((book) {
              if (book.lastStatsRefresh == null) return true;
              final age = now - book.lastStatsRefresh!;
              return age > perBookCooldown.inMilliseconds;
            }).toList();

      ApiLogger.logCache(
        'refreshExpiredBooks',
        details:
            'forceRefreshAll=$forceRefreshAll, ${booksToRefresh.length} books out of ${state.activeBooks.length}',
      );

      if (booksToRefresh.isEmpty) {
        _lastBackgroundRefreshTime = now;
        if (forceRefreshAll) {
          state = state.copyWith(isRefreshing: false);
        }
        return;
      }

      try {
        await _repository.invalidateAllBookStatsCache(
          timeout: const Duration(seconds: 15),
        );

        await _repository.contentService.setUserSetting(
          'stats_calc_sample_size',
          '500',
        );

        final updatedActiveBooks = List<Book>.from(state.activeBooks);

        final futures = booksToRefresh
            .map(
              (book) => _refreshBookSimple(
                book.id,
                updatedBooksList: updatedActiveBooks,
              ),
            )
            .toList();
        await Future.wait(futures);

        await _repository.saveBooksToCache(
          activeBooks: updatedActiveBooks,
          archivedBooks: state.archivedBooks,
        );

        state = state.copyWith(
          isRefreshing: false,
          activeBooks: updatedActiveBooks,
        );
      } catch (e) {
        if (forceRefreshAll) {
          state = state.copyWith(
            isRefreshing: false,
            errorMessage: e.toString(),
          );
        }
        rethrow;
      } finally {
        try {
          final settings = ref.read(settingsProvider);
          await _repository.contentService.setUserSetting(
            'stats_calc_sample_size',
            settings.statsCalcSampleSize.toString(),
          );
        } catch (e) {
          ApiLogger.logError('restoreSampleSize', e);
        }
      }

      _lastBackgroundRefreshTime = now;
    } finally {
      _isBackgroundRefreshing = false;
    }
  }

  Future<void> _refreshBookSimple(
    int bookId, {
    List<Book>? updatedBooksList,
  }) async {
    ApiLogger.logRequest('_refreshBookSimple', details: 'bookId=$bookId');

    final booksList = updatedBooksList ?? state.activeBooks;
    final existingBook = booksList.firstWhere(
      (book) => book.id == bookId,
      orElse: () =>
          throw Exception('Book with id $bookId not found in active books'),
    );
    final statsBook = await _repository.contentService.getBookStats(bookId);
    ApiLogger.logRequest(
      '_refreshBookSimple',
      details: 'bookId=$bookId, distinctTerms=${statsBook.distinctTerms}',
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

    final settings = ref.read(settingsProvider);

    try {
      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        settings.stats500SampleSize.toString(),
      );

      final booksList = updatedBooksList ?? state.activeBooks;
      final existingBook = booksList.firstWhere(
        (book) => book.id == bookId,
        orElse: () =>
            throw Exception('Book with id $bookId not found in active books'),
      );
      final statsBook = await _repository.contentService.getBookStats(
        bookId,
        timeout: const Duration(seconds: 15),
      );
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
              ApiLogger.logError('saveBooksToCache', e);
            }
          }();
        }
      }
    } finally {
      _isRefreshingBook = false;
      try {
        final settings = ref.read(settingsProvider);
        await _repository.contentService.setUserSetting(
          'stats_calc_sample_size',
          settings.statsCalcSampleSize.toString(),
        );
      } catch (e) {
        ApiLogger.logError('restoreSampleSize', e);
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
      ApiLogger.logRequest(
        '_loadBooksFromNetwork',
        details: 'got ${networkBooks.length} books',
      );

      final networkBooksMap = {for (var b in networkBooks) b.id: b};
      final existingBookIds = {for (var b in state.activeBooks) b.id};
      final updatedActiveBooks = state.activeBooks.map((existing) {
        final network = networkBooksMap[existing.id];
        if (network != null) {
          return existing.copyWith(
            title: network.title,
            language: network.language,
            langId: existing.langId ?? network.langId,
            totalPages: network.totalPages,
            currentPage: network.currentPage,
            percent: network.percent,
            wordCount: network.wordCount,
            tags: network.tags ?? existing.tags,
            lastRead: network.lastRead ?? existing.lastRead,
            isCompleted: network.isCompleted,
            audioFilename: network.audioFilename ?? existing.audioFilename,
            distinctTerms: existing.distinctTerms,
            unknownPct: existing.unknownPct,
            statusDistribution: existing.statusDistribution,
          );
        }
        return existing;
      }).toList();

      final newBooks = networkBooks
          .where((b) => !existingBookIds.contains(b.id))
          .toList();

      final finalActiveBooks = [...updatedActiveBooks, ...newBooks];

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
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      _isLoadingFromNetwork = false;
    }
  }

  Future<void> _refreshArchived() async {
    if (_isLoadingFromNetwork) {
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
      final settings = ref.read(settingsProvider);
      await _repository.invalidateAllBookStatsCache();

      await _repository.contentService.setUserSetting(
        'stats_calc_sample_size',
        settings.stats500SampleSize.toString(),
      );

      final activeBooksToRefresh = state.activeBooks;
      final updatedActiveBooks = List<Book>.from(state.activeBooks);

      for (
        int i = 0;
        i < activeBooksToRefresh.length;
        i += settings.statsRefreshBatchSize
      ) {
        final batch = <Future<void>>[];
        for (int j = 0; j < settings.statsRefreshBatchSize; j++) {
          if (i + j < activeBooksToRefresh.length) {
            batch.add(
              _refreshBookSimple(
                activeBooksToRefresh[i + j].id,
                updatedBooksList: updatedActiveBooks,
              ),
            );
          }
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
        settings.statsCalcSampleSize.toString(),
      );
    } catch (e) {
      try {
        final settings = ref.read(settingsProvider);
        await _repository.contentService.setUserSetting(
          'stats_calc_sample_size',
          settings.statsCalcSampleSize.toString(),
        );
      } catch (err) {
        ApiLogger.logError('restoreSampleSize', err);
      }
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
