import 'dart:async';
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../models/language_sentence_settings.dart';
import '../repositories/reader_repository.dart';
import '../services/page_cache_service.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../features/settings/providers/settings_provider.dart';

import 'sentence_reader_provider.dart';
import '../../../core/cache/providers/tooltip_cache_provider.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermTooltipLoading;
  final bool isTermFormLoading;
  final LanguageSentenceSettings? languageSentenceSettings;
  final bool isBackgroundRefreshing;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermTooltipLoading = false,
    this.isTermFormLoading = false,
    this.languageSentenceSettings,
    this.isBackgroundRefreshing = false,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermTooltipLoading,
    bool? isTermFormLoading,
    LanguageSentenceSettings? languageSentenceSettings,
    bool? isBackgroundRefreshing,
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
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    return const ReaderState();
  }

  ReaderRepository get _repository => ref.read(readerRepositoryProvider);

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

    if (updateReaderState && !refreshStatuses) {
      state = state.copyWith(isLoading: true, errorMessage: null);
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
          final currentData = state.pageData;
          if (currentData != null) {
            final mergedData = _mergePageStatuses(currentData, pageData);
            state = state.copyWith(
              isBackgroundRefreshing: false,
              pageData: mergedData,
            );
          }
        } else {
          state = state.copyWith(isLoading: false, pageData: pageData);

          if (pageData.currentPage < pageData.pageCount) {
            preloadNextPage();
            preloadTooltipsForNextPage(); // Preload tooltips for the next page
          }

          // Preload tooltips for the current page to improve performance
          preloadTooltipsForCurrentPage();

          _backgroundRefreshStatuses();
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
        print('Navigation error (not showing full screen): $e');
        state = state.copyWith(isLoading: false, isBackgroundRefreshing: false);
      }
    }
  }

  void _backgroundRefreshStatuses() {
    Future.microtask(() {
      if (state.pageData == null) return;
      state = state.copyWith(isBackgroundRefreshing: true);

      _repository
          .getPage(
            bookId: state.pageData!.bookId,
            pageNum: state.pageData!.currentPage,
            useCache: false,
            forceRefresh: true,
          )
          .then((freshPage) {
            final mergedData = _mergePageStatuses(state.pageData!, freshPage);
            state = state.copyWith(
              isBackgroundRefreshing: false,
              pageData: mergedData,
            );
          })
          .catchError((e) {
            print('Background status refresh error: $e');
            state = state.copyWith(isBackgroundRefreshing: false);
          });
    });
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
    if (currentPageData == null) return;

    final nextPageNum = currentPageData.currentPage + 1;
    if (nextPageNum > currentPageData.pageCount) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _repository.getPage(
          bookId: currentPageData.bookId,
          pageNum: nextPageNum,
          useCache: true,
          forceRefresh: false,
        );
        return;
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        } else {
          print(
            'Preload error for page $nextPageNum after $maxRetries attempts: $e',
          );
        }
      }
    }
  }

  /// Preload tooltips for terms on the current page if caching is enabled
  Future<void> preloadTooltipsForCurrentPage() async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableTooltipCaching) return;

    final currentPageData = state.pageData;
    if (currentPageData == null) return;

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

      // Preload tooltips for these terms
      final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
      for (final termId in termIds) {
        // Check if tooltip is already cached
        final cachedEntry = await tooltipCacheService.getFromCache(termId);
        if (cachedEntry == null) {
          // Fetch and cache the tooltip
          try {
            final tooltip = await _repository.getTermTooltip(termId);
            if (tooltip != null) {
              final rawHtml = await _repository.contentService
                  .getRawTermTooltipHtml(termId);
              if (rawHtml != null) {
                await tooltipCacheService.saveToCache(termId, rawHtml);
              }
            }
          } catch (e) {
            print('Error preloading tooltip for term $termId: $e');
          }
        }
      }
    } catch (e) {
      print('Error preloading tooltips for current page: $e');
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

    try {
      // Get the next page data to identify terms that need tooltips
      final nextPageData = await _repository.getPage(
        bookId: currentPageData.bookId,
        pageNum: nextPageNum,
        useCache: true,
        forceRefresh: false,
      );

      // Extract unique term IDs from the next page
      final termIds = <int>{};
      for (final paragraph in nextPageData.paragraphs) {
        for (final item in paragraph.textItems) {
          if (item.wordId != null && item.wordId! > 0) {
            termIds.add(item.wordId!);
          }
        }
      }

      // Preload tooltips for these terms
      final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
      for (final termId in termIds) {
        // Check if tooltip is already cached
        final cachedEntry = await tooltipCacheService.getFromCache(termId);
        if (cachedEntry == null) {
          // Fetch and cache the tooltip
          try {
            final tooltip = await _repository.getTermTooltip(termId);
            if (tooltip != null) {
              final rawHtml = await _repository.contentService
                  .getRawTermTooltipHtml(termId);
              if (rawHtml != null) {
                await tooltipCacheService.saveToCache(termId, rawHtml);
              }
            }
          } catch (e) {
            print('Error preloading tooltip for term $termId: $e');
          }
        }
      }
    } catch (e) {
      print('Error preloading tooltips for next page: $e');
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
        useCache: false,
        forceRefresh: true,
      );

      final mergedData = _mergePageStatuses(currentPageData, freshPage);
      state = state.copyWith(
        isBackgroundRefreshing: false,
        pageData: mergedData,
      );
    } catch (e) {
      print('Background refresh error: $e');
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
        print('Error getting tooltip from cache: $e');
        // Continue to fetch from network if cache fails
      }
    }

    try {
      // Fetch from network
      final result = await _repository.getTermTooltip(termId);

      // If caching is enabled, save to cache
      if (settings.enableTooltipCaching && result != null) {
        try {
          final tooltipCacheService = ref.read(tooltipCacheServiceProvider);

          // We need to get the raw HTML that was used to create this result
          // For this, we need to fetch the raw HTML again
          final rawHtml = await _repository.contentService
              .getRawTermTooltipHtml(termId);
          if (rawHtml != null) {
            await tooltipCacheService.saveToCache(termId, rawHtml);
          }
        } catch (e) {
          print('Error saving tooltip to cache: $e');
        }
      }

      return result;
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
          final tooltipCacheService = ref.read(tooltipCacheServiceProvider);
          // Note: We don't have the termId here, so we can't invalidate the specific cache entry
          // The cache will be refreshed on next fetch
        } catch (e) {
          print('Error invalidating tooltip cache after save: $e');
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
          print('Error invalidating tooltip cache after edit: $e');
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
            print('Error invalidating tooltip cache after saveTerm: $e');
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
          print('Error invalidating tooltip cache after updateTermStatus: $e');
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
      print('Error getting current page for book $bookId: $e');
      // Return -1 to indicate error
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
    final cacheService = PageCacheService();
    await cacheService.clearBookCache(bookId);
  }

  Future<void> clearAllPageCache() async {
    final cacheService = PageCacheService();
    await cacheService.clearAllCache();
  }

  /// Parse a TermTooltip from HTML representation
  TermTooltip _parseTooltipFromHtml(String html) {
    // This is a simplified implementation - in reality, you'd want to properly
    // parse the HTML and reconstruct the TermTooltip object
    // For now, we'll create a basic tooltip with the HTML as the term
    return TermTooltip(
      term: html, // This is just a placeholder
      status: '0', // Default to unknown
      sentences: [], // Empty list
      parents: [], // Empty list
      children: [], // Empty list
    );
  }

  /// Create an HTML representation of a TermTooltip for caching
  String _createHtmlRepresentation(TermTooltip tooltip) {
    // Create a simple HTML representation of the tooltip
    // In a real implementation, you'd want to serialize the tooltip properly
    return '''
<div class="tooltip-cache">
  <div class="term">${tooltip.term}</div>
  <div class="translation">${tooltip.translation ?? ''}</div>
  <div class="status">${tooltip.status}</div>
  <div class="language">${tooltip.language ?? ''}</div>
</div>
''';
  }
}

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(contentService: contentService);
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
