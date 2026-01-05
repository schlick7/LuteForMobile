import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../models/language_sentence_settings.dart';
import '../repositories/reader_repository.dart';
import '../services/page_cache_service.dart';
import '../../../shared/providers/network_providers.dart';

import 'sentence_reader_provider.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermTooltipLoading;
  final bool isTermFormLoading;
  final LanguageSentenceSettings? languageSentenceSettings;
  final bool isBackgroundRefreshing;
  final PageData? nextPageData;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermTooltipLoading = false,
    this.isTermFormLoading = false,
    this.languageSentenceSettings,
    this.isBackgroundRefreshing = false,
    this.nextPageData,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermTooltipLoading,
    bool? isTermFormLoading,
    LanguageSentenceSettings? languageSentenceSettings,
    bool? isBackgroundRefreshing,
    PageData? nextPageData,
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
      nextPageData: nextPageData ?? this.nextPageData,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    return const ReaderState();
  }

  ReaderRepository get _repository => ref.read(readerRepositoryProvider);

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
          state = state.copyWith(
            isLoading: false,
            pageData: pageData,
            nextPageData: null,
          );

          if (!state.isLoading) {
            unawaited(preloadNextPage());
          }
        }
      }
    } catch (e) {
      if (showFullPageError && updateReaderState && !refreshStatuses) {
        state = state.copyWith(
          isLoading: false,
          isBackgroundRefreshing: false,
          errorMessage: e.toString(),
        );
      } else if (updateReaderState) {
        print('Navigation error (not showing full screen): $e');
        state = state.copyWith(isLoading: false, isBackgroundRefreshing: false);
      }
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
    if (currentPageData == null) return;

    final nextPageNum = currentPageData.currentPage + 1;
    if (nextPageNum > currentPageData.pageCount) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final nextPage = await _repository.getPage(
          bookId: currentPageData.bookId,
          pageNum: nextPageNum,
          useCache: true,
          forceRefresh: false,
        );
        state = state.copyWith(nextPageData: nextPage);
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
    state = state.copyWith(
      isLoading: false,
      pageData: pageData,
      nextPageData: null,
    );
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
    try {
      final result = await _repository.getTermTooltip(termId);
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
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editTerm(int termId, Map<String, dynamic> data) async {
    try {
      await _repository.editTerm(termId, data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveTerm(TermForm termForm) async {
    try {
      if (termForm.termId != null) {
        await _repository.editTerm(termForm.termId!, termForm.toFormData());
        updateTermStatus(termForm.termId!, termForm.status);
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

  void updateTermStatus(int termId, String status) {
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
}

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(contentService: contentService);
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
