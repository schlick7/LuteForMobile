import 'dart:async';
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../../core/logger/api_logger.dart';
import '../../../core/network/content_service.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../models/language_sentence_settings.dart';
import '../repositories/reader_repository.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../features/settings/providers/settings_provider.dart';

import 'sentence_reader_provider.dart';
import '../../../core/cache/providers/tooltip_cache_provider.dart';
import '../../../core/cache/providers/page_cache_provider.dart';
import '../../../features/terms/providers/terms_provider.dart';
import '../../../shared/providers/app_startup_providers.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermTooltipLoading;
  final bool isTermFormLoading;
  final LanguageSentenceSettings? languageSentenceSettings;
  final bool isBackgroundRefreshing;
  final bool isPreloadingTooltips;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermTooltipLoading = false,
    this.isTermFormLoading = false,
    this.languageSentenceSettings,
    this.isBackgroundRefreshing = false,
    this.isPreloadingTooltips = false,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermTooltipLoading,
    bool? isTermFormLoading,
    LanguageSentenceSettings? languageSentenceSettings,
    bool? isBackgroundRefreshing,
    bool? isPreloadingTooltips,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pageData: pageData ?? this.pageData,
      errorMessage: errorMessage,
      isTermTooltipLoading: isTermTooltipLoading ?? this.isTermTooltipLoading,
      isTermFormLoading: isTermFormLoading ?? this.isTermFormLoading,
      languageSentenceSettings:
          languageSentenceSettings ?? this.languageSentenceSettings,
      isBackgroundRefreshing:
          isBackgroundRefreshing ?? this.isBackgroundRefreshing,
      isPreloadingTooltips: isPreloadingTooltips ?? this.isPreloadingTooltips,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  // Track the current page request to ignore stale responses
  String _currentRequestKey = '';

  // Sequential prefetch queue - ensures tooltip preloads happen in order
  // and don't overlap (prevents duplicate fetches for shared terms)
  Future<void>? _prefetchQueue;

  @override
  ReaderState build() {
    return const ReaderState();
  }

  /// Adds a prefetch task to the sequential queue.
  /// Ensures that prefetch operations don't overlap and cause duplicate fetches.
  Future<void> _enqueuePrefetch(Future<void> Function() task) async {
    ApiLogger.logRequest(
      '_enqueuePrefetch',
      details: 'queueActive=${_prefetchQueue != null}',
    );
    final future =
        _prefetchQueue?.then((_) => task()).catchError((_) => task()) ?? task();
    _prefetchQueue = future;
    return future;
  }

  ReaderRepository get _repository => ref.read(readerRepositoryProvider);

  void clearPageData() {
    state = const ReaderState();
  }

  String _getRequestKey(int bookId, int? pageNum) {
    return '${bookId}_${pageNum ?? 0}';
  }

  String _formatError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your network connection.';
        case DioExceptionType.sendTimeout:
          return 'Request timed out. The server may be slow or unavailable.';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond. Please try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to server. Please check your network connection and server settings.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null && statusCode >= 500) {
            return 'Server error ($statusCode). Please try again later.';
          } else if (statusCode != null && statusCode >= 400) {
            return 'Request error ($statusCode). Please check your settings.';
          }
          return 'Server error occurred. Please try again.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.unknown:
          if (error.error?.toString().contains('Connection refused') == true) {
            return 'Server is not running or is unreachable. Please check your server URL.';
          }
          return 'Network error occurred. Please check your connection.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }
    if (error.toString().contains('Failed to load page')) {
      return 'Could not load page. Please check your network connection.';
    }
    return 'An error occurred: $error';
  }

  Future<void> loadPage({
    required int bookId,
    int? pageNum,
    bool updateReaderState = true,
    bool showFullPageError = true,
    bool useCache = true,
    bool refreshStatuses = false,
  }) async {
    if (!_repository.contentService.isConfigured) {
      if (updateReaderState) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Server URL not configured. Please set it in settings.',
        );
      }
      return;
    }

    // Set the current request key to track this page load
    final requestKey = _getRequestKey(bookId, pageNum);
    _currentRequestKey = requestKey;

    ApiLogger.logRequest(
      'loadPage',
      details:
          'requestKey=$requestKey, useCache=$useCache, refreshStatuses=$refreshStatuses',
    );

    if (updateReaderState && !refreshStatuses) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    // Safety timeout - if loading takes more than 15 seconds, force stop
    Timer? safetyTimeout;
    if (updateReaderState && !refreshStatuses) {
      safetyTimeout = Timer(const Duration(seconds: 15), () {
        if (state.isLoading) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Loading timed out. Please try again.',
          );
        }
      });
    }

    try {
      final pageData = await _repository.getPage(
        bookId: bookId,
        pageNum: pageNum,
        useCache: useCache && !refreshStatuses,
        forceRefresh: false,
      );

      if (updateReaderState) {
        if (refreshStatuses) {
          // Background refresh mode: merge with current data
          final currentData = state.pageData;
          if (currentData != null && pageData != null) {
            final mergedData = _mergePageStatuses(currentData, pageData);
            state = state.copyWith(
              isBackgroundRefreshing: false,
              pageData: mergedData,
            );
          } else if (pageData != null) {
            // No current data, just use the fresh data
            state = state.copyWith(
              isBackgroundRefreshing: false,
              isLoading: false,
              pageData: pageData,
            );
          }
        } else if (pageData != null) {
          // Cache hit: update state with cached data
          state = state.copyWith(isLoading: false, pageData: pageData);

          // Queue up prefetch operations sequentially to ensure start_reading
          // completes before preloading the next page
          _enqueuePrefetch(
            () => _backgroundRefreshStatuses(bookId, pageNum, requestKey),
          );
          _enqueuePrefetch(() => preloadTooltipsForCurrentPage());

          if (pageData.currentPage < pageData.pageCount) {
            final settings = ref.read(settingsProvider);
            if (settings.enablePagePreload) {
              _enqueuePrefetch(() => preloadNextPage());
              _enqueuePrefetch(() => preloadTooltipsForNextPage());
            }
          }

          // Signal that reader is ready for other operations to begin
          if (updateReaderState && !refreshStatuses) {
            ref.read(readerReadinessProvider.notifier).markReady();
          }
        } else {
          // Cache miss: stay in loading state and trigger background refresh
          await _backgroundRefreshStatuses(bookId, pageNum, requestKey);
        }
      }
    } catch (e) {
      if (showFullPageError && updateReaderState && !refreshStatuses) {
        state = state.copyWith(
          isLoading: false,
          isBackgroundRefreshing: false,
          errorMessage: _formatError(e),
        );
      } else if (updateReaderState) {
        ApiLogger.logError('loadPageNavigation', e);
        state = state.copyWith(isLoading: false, isBackgroundRefreshing: false);
      }
    } finally {
      // Always cancel the safety timeout
      safetyTimeout?.cancel();
    }
  }

  Future<void> _backgroundRefreshStatuses(
    int bookId,
    int? pageNum,
    String requestKey,
  ) async {
    state = state.copyWith(isBackgroundRefreshing: true);

    const maxRetries = 3;
    int attempt = 0;
    PageData? freshPage;
    Object? lastError;

    while (attempt < maxRetries && freshPage == null) {
      try {
        freshPage = await _repository.getPage(
          bookId: bookId,
          pageNum: pageNum,
          mode: ContentMode.reading,
          useCache: false,
          forceRefresh: true,
        );
      } catch (e) {
        attempt++;
        lastError = e;
        ApiLogger.logBackground(
          'statusRefresh',
          details: 'attempt=$attempt failed',
        );
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    ApiLogger.logBackground(
      'statusRefreshComplete',
      details: 'requestKey=$requestKey, freshPage=${freshPage != null}',
    );

    // Check if this response is still valid (user hasn't navigated to a different page)
    if (requestKey != _currentRequestKey) {
      ApiLogger.logBackground(
        'statusRefreshIgnored',
        details: 'pageChanged from $requestKey to $_currentRequestKey',
      );
      return;
    }

    if (freshPage == null) {
      final currentData = state.pageData;
      if (currentData != null) {
        state = state.copyWith(isBackgroundRefreshing: false, isLoading: false);
      } else {
        state = state.copyWith(
          isBackgroundRefreshing: false,
          isLoading: false,
          errorMessage: lastError != null
              ? 'Failed to load page: ${_formatError(lastError)}'
              : 'Failed to load page',
        );
      }
      return;
    }

    final currentData = state.pageData;
    if (currentData == null) {
      // No cached data, use fresh data directly and stop loading
      state = state.copyWith(
        isBackgroundRefreshing: false,
        isLoading: false,
        pageData: freshPage,
      );
    } else if (currentData.currentPage == freshPage.currentPage) {
      // Same page - merge statuses with existing data
      final mergedData = _mergePageStatuses(currentData, freshPage);
      state = state.copyWith(
        isBackgroundRefreshing: false,
        isLoading: false,
        pageData: mergedData,
      );
      ApiLogger.logBackground(
        'statusRefresh',
        details: 'failedAfter=$maxRetries attempts',
      );
    } else {
      // Different page - use fresh data directly
      state = state.copyWith(
        isBackgroundRefreshing: false,
        isLoading: false,
        pageData: freshPage,
      );
    }
  }

  PageData _mergePageStatuses(PageData currentPage, PageData freshPage) {
    final updatedParagraphs = currentPage.paragraphs.asMap().entries.map((
      entry,
    ) {
      final paraIdx = entry.key;
      final currentPara = entry.value;

      if (paraIdx >= freshPage.paragraphs.length) {
        return currentPara;
      }

      final freshPara = freshPage.paragraphs[paraIdx];
      final updatedItems = currentPara.textItems.asMap().entries.map((
        itemEntry,
      ) {
        final itemIdx = itemEntry.key;
        final currentItem = itemEntry.value;

        if (itemIdx >= freshPara.textItems.length) {
          return currentItem;
        }

        final freshItem = freshPara.textItems[itemIdx];
        return currentItem.copyWith(statusClass: freshItem.statusClass);
      }).toList();

      return currentPara.copyWith(textItems: updatedItems);
    }).toList();

    return currentPage.copyWith(paragraphs: updatedParagraphs);
  }

  Future<void> preloadNextPage() async {
    final currentPageData = state.pageData;
    if (currentPageData == null) {
      ApiLogger.logRequest('preloadNextPage', details: 'SKIP - no page data');
      return;
    }

    final nextPageNum = currentPageData.currentPage + 1;
    if (nextPageNum > currentPageData.pageCount) {
      ApiLogger.logRequest(
        'preloadNextPage',
        details: 'SKIP - already at last page (${currentPageData.pageCount})',
      );
      return;
    }

    ApiLogger.logRequest(
      'preloadNextPage',
      details: 'START - bookId=${currentPageData.bookId}, page=$nextPageNum',
    );

    // Get cached metadata from current page to reuse (avoids extra API call)
    final cacheService = ref.read(pageCacheServiceProvider);
    final cachedMetadata = await cacheService.getMetadataFromCache(
      currentPageData.bookId,
      currentPageData.currentPage,
    );

    // Use the dedicated preload method which checks cache first and fetches if needed
    await _repository.preloadPage(
      currentPageData.bookId,
      nextPageNum,
      cachedMetadataHtml: cachedMetadata,
    );

    ApiLogger.logRequest(
      'preloadNextPage',
      details: 'DONE - bookId=${currentPageData.bookId}, page=$nextPageNum',
    );
  }

  /// Preload tooltips for terms on the current page if caching is enabled
  Future<void> preloadTooltipsForCurrentPage() async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableTooltipCaching) return;

    final currentPageData = state.pageData;
    if (currentPageData == null) return;

    state = state.copyWith(isPreloadingTooltips: true);
    try {
      // Extract unique term IDs from the current page
      final termIds = <int>{};
      for (final paragraph in currentPageData.paragraphs) {
        for (final item in paragraph.textItems) {
          if (item.wordId != null && item.wordId! > 0) {
            termIds.add(item.wordId!);
          }
        }
      }

      await _preloadTooltipsForTerms(termIds, 'current');
    } finally {
      state = state.copyWith(isPreloadingTooltips: false);
    }
  }

  /// Helper method to preload tooltips for a set of term IDs
  /// Fetches in parallel based on maxConcurrentTooltipFetches setting
  /// Uses concurrent queue pattern - maintains N concurrent requests,
  /// starting a new one as soon as any completes
  Future<void> _preloadTooltipsForTerms(
    Set<int> termIds,
    String pageLabel,
  ) async {
    if (termIds.isEmpty) return;

    final settings = ref.read(settingsProvider);
    if (!settings.enableTooltipCaching) return;

    final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
    final maxConcurrent = settings.maxConcurrentTooltipFetches.clamp(1, 10);
    int fetchedCount = 0;
    int cachedCount = 0;

    // Phase 1: Check cache for ALL terms in parallel to identify misses
    final cacheChecks = termIds.map((termId) async {
      final cached = await tooltipCacheService.getFromCache(termId);
      return {'termId': termId, 'cached': cached != null};
    });
    final cacheResults = await Future.wait(cacheChecks);

    // Phase 2: Filter to uncached term IDs only
    final uncachedTermIds = cacheResults
        .where((r) => r['cached'] == false)
        .map((r) => r['termId'] as int)
        .toSet();

    cachedCount = cacheResults.where((r) => r['cached'] == true).length;

    if (uncachedTermIds.isEmpty) {
      if (cachedCount > 0) {
        ApiLogger.logCache(
          'preloadTooltipsComplete',
          details: '$pageLabel: fetched=0, cached=$cachedCount (all cached)',
        );
      }
      return;
    }

    // Phase 3: Concurrent queue pattern - maintain N concurrent requests
    // When any request completes, immediately start the next one
    final queue = List<int>.from(uncachedTermIds);
    int activeCount = 0;
    final completer = Completer<void>();

    Future<void> fetchNext() async {
      if (queue.isEmpty) {
        if (activeCount == 0 && !completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      activeCount++;
      final termId = queue.removeAt(0);

      try {
        final result = await _repository.getTermTooltipWithHtml(termId);
        if (result != null) {
          final (tooltip, html) = result;
          final htmlToCache = html.isEmpty ? ' ' : html;
          await tooltipCacheService.saveToCache(termId, htmlToCache);
          fetchedCount++;
        }
      } catch (e) {
        ApiLogger.logError('preloadTooltip', e, details: 'termId=$termId');
      } finally {
        activeCount--;
        fetchNext(); // Immediately trigger next request
      }
    }

    // Start initial batch (up to maxConcurrent concurrent)
    for (int i = 0; i < maxConcurrent && queue.isNotEmpty; i++) {
      fetchNext();
    }

    // Wait for all to complete
    if (queue.isNotEmpty || activeCount > 0) {
      await completer.future;
    }

    if (fetchedCount > 0 || cachedCount > 0) {
      ApiLogger.logCache(
        'preloadTooltipsComplete',
        details:
            '$pageLabel: fetched=$fetchedCount, cached=$cachedCount, maxConcurrent=$maxConcurrent',
      );
    }
  }

  /// Preload tooltips for terms on the next page if caching is enabled
  Future<void> preloadTooltipsForNextPage() async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableTooltipCaching) return;

    final currentPageData = state.pageData;
    if (currentPageData == null) return;

    final nextPageNum = currentPageData.currentPage + 1;
    if (nextPageNum > currentPageData.pageCount) return;

    state = state.copyWith(isPreloadingTooltips: true);
    try {
      // Get the next page data to identify terms that need tooltips
      final nextPageData = await _repository.getPage(
        bookId: currentPageData.bookId,
        pageNum: nextPageNum,
        useCache: true,
        forceRefresh: false,
      );

      if (nextPageData == null) return;

      // Extract unique term IDs from the next page
      final termIds = <int>{};
      for (final paragraph in nextPageData.paragraphs) {
        for (final item in paragraph.textItems) {
          if (item.wordId != null && item.wordId! > 0) {
            termIds.add(item.wordId!);
          }
        }
      }

      await _preloadTooltipsForTerms(termIds, 'next');
    } catch (e) {
      print('Error preloading tooltips for next page: $e');
    } finally {
      state = state.copyWith(isPreloadingTooltips: false);
    }
  }

  Future<void> refreshCurrentPageStatuses() async {
    final currentPageData = state.pageData;
    if (currentPageData == null) return;

    state = state.copyWith(isBackgroundRefreshing: true);

    try {
      final freshPage = await _repository.getPage(
        bookId: currentPageData.bookId,
        pageNum: currentPageData.currentPage,
        mode: ContentMode.refresh,
        useCache: false,
        forceRefresh: true,
      );

      if (freshPage == null) {
        state = state.copyWith(isBackgroundRefreshing: false);
        return;
      }

      final mergedData = _mergePageStatuses(currentPageData, freshPage);
      state = state.copyWith(
        isBackgroundRefreshing: false,
        pageData: mergedData,
      );
    } catch (e) {
      ApiLogger.logError('backgroundRefresh', e);
      state = state.copyWith(isBackgroundRefreshing: false);
    }
  }

  void setPageDirectly(PageData pageData) {
    state = state.copyWith(isLoading: false, pageData: pageData);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> fetchLanguageSentenceSettings(int langId) async {
    try {
      final settings = await _repository.getLanguageSentenceSettings(langId);
      state = state.copyWith(languageSentenceSettings: settings);
    } catch (e) {
      state = state.copyWith(languageSentenceSettings: null);
    }
  }

  Future<TermTooltip?> fetchTermTooltip(int termId) async {
    final settings = ref.read(settingsProvider);

    // If tooltip caching is enabled, check the cache first
    if (settings.enableTooltipCaching) {
      try {
        final tooltipCacheService = ref.read(tooltipCacheServiceProvider);

        // Try to get from cache
        final cachedEntry = await tooltipCacheService.getFromCache(termId);
        if (cachedEntry != null) {
          // Parse the cached HTML to create a TermTooltip object using the same parser as the server
          final contentService = ref.read(contentServiceProvider);
          final tooltip = contentService.parser.parseTermTooltip(
            cachedEntry.tooltipHtml,
          );
          return tooltip;
        }
      } catch (e) {
        ApiLogger.logError('getTooltipFromCache', e, details: 'termId=$termId');
      }
    }

    try {
      // Fetch from network using single API call
      final resultWithHtml = await _repository.getTermTooltipWithHtml(termId);

      if (resultWithHtml != null) {
        final (tooltip, rawHtml) = resultWithHtml;

        // If caching is enabled, save to cache (including empty HTML as " " marker)
        if (settings.enableTooltipCaching) {
          try {
            final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
            final htmlToCache = rawHtml.isEmpty ? ' ' : rawHtml;
            await tooltipCacheService.saveToCache(termId, htmlToCache);
          } catch (e) {
            ApiLogger.logError(
              'saveTooltipToCache',
              e,
              details: 'termId=$termId',
            );
          }
        }

        return tooltip;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<TermForm?> fetchTermForm(int langId, String text) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermForm(langId, text);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermFormLoading: false);
    }
  }

  Future<TermForm?> fetchTermFormById(int termId) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermFormByIdWithParentDetails(termId);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermFormLoading: false);
    }
  }

  Future<TermForm?> fetchTermFormWithDetails(int langId, String text) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermFormWithParentDetails(langId, text);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermFormLoading: false);
    }
  }

  Future<bool> saveTermForm(
    int langId,
    String text,
    Map<String, dynamic> data,
  ) async {
    try {
      await _repository.saveTermForm(langId, text, data);

      // Invalidate tooltip cache for this term if caching is enabled
      final settings = ref.read(settingsProvider);
      if (settings.enableTooltipCaching) {
        try {
          // Note: We don't have the termId here, so we can't invalidate the specific cache entry
          // The cache will be refreshed on next fetch
        } catch (e) {
          ApiLogger.logError('invalidateTooltipCache', e);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editTerm(int termId, Map<String, dynamic> data) async {
    try {
      await _repository.editTerm(termId, data);

      // Invalidate tooltip cache for this term if caching is enabled
      final settings = ref.read(settingsProvider);
      if (settings.enableTooltipCaching) {
        try {
          final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
          await tooltipCacheService.removeFromCache(termId);
        } catch (e) {
          ApiLogger.logError(
            'invalidateTooltipCache',
            e,
            details: 'termId=$termId',
          );
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveTerm(TermForm termForm) async {
    try {
      if (termForm.termId != null) {
        await _repository.editTerm(termForm.termId!, termForm.toFormData());
        await updateTermStatus(termForm.termId!, termForm.status);

        // No longer needed - getPageContent handles caching when fresh data is loaded

        if (termForm.status == '99') {
          final currentPageData = state.pageData;
          if (currentPageData != null) {
            int? langId;
            for (final paragraph in currentPageData.paragraphs) {
              for (final item in paragraph.textItems) {
                if (item.wordId == termForm.termId && item.langId != null) {
                  langId = item.langId;
                  break;
                }
              }
              if (langId != null) break;
            }

            if (langId != null) {
              if (ref.read(settingsProvider).showStatsBar) {
                ref.read(termsProvider.notifier).loadStats(langId);
              }
            }
          }
        }

        // Invalidate tooltip cache for this term if caching is enabled
        final settings = ref.read(settingsProvider);
        if (settings.enableTooltipCaching) {
          try {
            final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
            await tooltipCacheService.removeFromCache(termForm.termId!);

            // Also invalidate cache for parent terms
            for (final parent in termForm.parents) {
              if (parent.id != null) {
                await tooltipCacheService.removeFromCache(parent.id!);
              }
            }
          } catch (e) {
            ApiLogger.logError('invalidateTooltipCache', e);
          }
        }
      } else {
        await _repository.saveTermForm(
          termForm.languageId,
          termForm.term,
          termForm.toFormData(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateTermStatus(int termId, String status) async {
    final currentPageData = state.pageData;
    if (currentPageData == null) {
      return;
    }

    bool found = false;
    final updatedParagraphs = currentPageData.paragraphs.map((paragraph) {
      final updatedItems = paragraph.textItems.map((item) {
        if (item.wordId == termId) {
          found = true;
          final updated = item.copyWith(statusClass: 'status$status');
          return updated;
        }
        return item;
      }).toList();
      return paragraph.copyWith(textItems: updatedItems);
    }).toList();

    if (found) {
      state = state.copyWith(
        pageData: currentPageData.copyWith(paragraphs: updatedParagraphs),
      );

      ref
          .read(sentenceReaderProvider.notifier)
          .updateTermStatusInSentences(termId, status);

      // Invalidate tooltip cache for this term if caching is enabled
      final settings = ref.read(settingsProvider);
      if (settings.enableTooltipCaching) {
        try {
          final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
          await tooltipCacheService.removeFromCache(termId);
        } catch (e) {
          ApiLogger.logError('invalidateTooltipCache', e);
        }
      }
    }
  }

  /// Gets the current page number from the server for a book
  /// This is used to check if the server's current page matches the reader's page
  Future<int> getCurrentPageForBook(int bookId) async {
    try {
      return await _repository.getCurrentPageForBook(bookId);
    } catch (e) {
      ApiLogger.logError('getCurrentPageForBook', e, details: 'bookId=$bookId');
      return -1;
    }
  }

  Future<void> markPageRead(int bookId, int pageNum) async {
    await _repository.markPageRead(bookId, pageNum);
  }

  Future<void> markPageKnown(int bookId, int pageNum) async {
    await _repository.markPageKnown(bookId, pageNum);
  }

  Future<void> clearPageCacheForBook(int bookId) async {
    final cacheService = ref.read(pageCacheServiceProvider);
    await cacheService.clearBookCache(bookId);
  }

  Future<void> clearAllPageCache() async {
    final cacheService = ref.read(pageCacheServiceProvider);
    await cacheService.clearAllCache();
  }
}

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(contentService: contentService);
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
