import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../../core/logger/api_logger.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/sentence_parser.dart';
import '../services/sentence_cache_service.dart';
import '../models/term_tooltip.dart';
import 'reader_provider.dart';
import '../../../core/cache/providers/tooltip_cache_provider.dart';
import '../../../shared/providers/network_providers.dart';

@immutable
class SentenceReaderState {
  final int currentSentenceIndex;
  final bool isNavigating;
  final bool isParsing;
  final List<CustomSentence> customSentences;
  final String? errorMessage;
  final bool shouldFlushAndRebuild;
  final int? lastParsedBookId;
  final int? lastParsedPageNum;

  const SentenceReaderState({
    this.currentSentenceIndex = 0,
    this.isNavigating = false,
    this.isParsing = false,
    this.customSentences = const [],
    this.errorMessage,
    this.shouldFlushAndRebuild = false,
    this.lastParsedBookId,
    this.lastParsedPageNum,
  });

  CustomSentence? get currentSentence {
    if (currentSentenceIndex >= 0 &&
        currentSentenceIndex < customSentences.length) {
      return customSentences[currentSentenceIndex];
    }
    return null;
  }

  int get totalSentences => customSentences.length;
  String get sentencePosition => '${currentSentenceIndex + 1}/$totalSentences';

  SentenceReaderState copyWith({
    int? currentSentenceIndex,
    bool? isNavigating,
    bool? isParsing,
    List<CustomSentence>? customSentences,
    String? errorMessage,
    bool? shouldFlushAndRebuild,
    int? lastParsedBookId,
    int? lastParsedPageNum,
  }) {
    return SentenceReaderState(
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      isParsing: isParsing ?? this.isParsing,
      customSentences: customSentences ?? this.customSentences,
      errorMessage: errorMessage,
      shouldFlushAndRebuild:
          shouldFlushAndRebuild ?? this.shouldFlushAndRebuild,
      lastParsedBookId: lastParsedBookId ?? this.lastParsedBookId,
      lastParsedPageNum: lastParsedPageNum ?? this.lastParsedPageNum,
    );
  }
}

class SentenceReaderNotifier extends Notifier<SentenceReaderState> {
  late SentenceCacheService _cacheService;

  @override
  SentenceReaderState build() {
    _cacheService = ref.read(sentenceCacheServiceProvider);
    return const SentenceReaderState();
  }

  bool get canGoNext {
    if (state.currentSentenceIndex < state.customSentences.length - 1) {
      return true;
    }
    final reader = ref.read(readerProvider);
    return reader.pageData != null &&
        reader.pageData!.currentPage < reader.pageData!.pageCount;
  }

  bool get canGoPrevious {
    if (state.currentSentenceIndex > 0) {
      return true;
    }
    final reader = ref.read(readerProvider);
    return reader.pageData != null && reader.pageData!.currentPage > 1;
  }

  void syncStatusFromPageData() {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null || state.customSentences.isEmpty) return;

    final needsUpdate = _needsStatusSync(state.customSentences, reader);
    if (!needsUpdate) return;

    final syncedSentences = _syncStatusFromPageData(
      state.customSentences,
      reader,
    );
    state = state.copyWith(customSentences: syncedSentences);
  }

  bool _needsStatusSync(List<CustomSentence> sentences, ReaderState reader) {
    final Map<int, String> wordIdToStatus = {};

    for (final paragraph in reader.pageData!.paragraphs) {
      for (final item in paragraph.textItems) {
        if (item.wordId != null) {
          wordIdToStatus[item.wordId!] = item.statusClass;
        }
      }
    }

    for (final sentence in sentences) {
      for (final item in sentence.textItems) {
        if (item.wordId != null &&
            wordIdToStatus.containsKey(item.wordId) &&
            wordIdToStatus[item.wordId!] != item.statusClass) {
          return true;
        }
      }
    }

    return false;
  }

  List<CustomSentence> _syncStatusFromPageData(
    List<CustomSentence> sentences,
    ReaderState reader,
  ) {
    final Map<int, String> wordIdToStatus = {};

    for (final paragraph in reader.pageData!.paragraphs) {
      for (final item in paragraph.textItems) {
        if (item.wordId != null) {
          wordIdToStatus[item.wordId!] = item.statusClass;
        }
      }
    }

    return sentences.map((sentence) {
      final updatedItems = sentence.textItems.map((item) {
        if (item.wordId != null && wordIdToStatus.containsKey(item.wordId)) {
          return item.copyWith(statusClass: wordIdToStatus[item.wordId!]);
        }
        return item;
      }).toList();

      return sentence.copyWith(textItems: updatedItems);
    }).toList();
  }

  int _getLangIdFromPageData() {
    final reader = ref.read(readerProvider);
    if (reader.pageData?.paragraphs.isNotEmpty == true &&
        reader.pageData!.paragraphs[0].textItems.isNotEmpty) {
      return reader.pageData!.paragraphs[0].textItems.first.langId ?? 0;
    }
    return 0;
  }

  Future<void> parseSentencesForPage(int langId, {int? initialIndex}) async {
    final reader = ref.read(readerProvider);
    final settings = ref.read(settingsProvider);

    if (reader.pageData == null) {
      return;
    }

    state = state.copyWith(isParsing: true);

    final bookId = reader.pageData!.bookId;
    final pageNum = reader.pageData!.currentPage;
    final combineThreshold = settings.combineShortSentences ?? 3;

    if (state.lastParsedBookId == bookId &&
        state.lastParsedPageNum != null &&
        state.lastParsedPageNum != pageNum &&
        state.customSentences.isNotEmpty) {
      ApiLogger.logCache(
        'clearStaleData',
        details: 'bookId=$bookId, page ${state.lastParsedPageNum} -> $pageNum',
      );
      state = state.copyWith(
        lastParsedBookId: null,
        lastParsedPageNum: null,
        customSentences: [],
      );
    }

    final cachedSentences = await _cacheService.getFromCache(
      bookId,
      pageNum,
      langId,
      combineThreshold,
    );

    if (cachedSentences != null) {
      final isSamePage =
          state.lastParsedBookId == bookId &&
          state.lastParsedPageNum == pageNum;
      final shouldPreserveIndex =
          isSamePage &&
          state.customSentences.isNotEmpty &&
          state.customSentences.length == cachedSentences.length &&
          state.currentSentenceIndex < cachedSentences.length;

      final resolvedIndex = initialIndex == -1
          ? cachedSentences.length - 1
          : (shouldPreserveIndex
                ? state.currentSentenceIndex
                : (initialIndex ?? 0));

      state = state.copyWith(
        customSentences: cachedSentences,
        currentSentenceIndex: resolvedIndex,
        errorMessage: null,
        isParsing: false,
        lastParsedBookId: bookId,
        lastParsedPageNum: pageNum,
      );

      syncStatusFromPageData();

      ApiLogger.logCache(
        'sentencesLoaded',
        hit: true,
        details: '${cachedSentences.length} sentences, page=$pageNum',
      );
      return;
    }

    if (reader.languageSentenceSettings == null ||
        reader.languageSentenceSettings!.languageId != langId) {
      await ref
          .read(readerProvider.notifier)
          .fetchLanguageSentenceSettings(langId);
    } else {}

    if (reader.languageSentenceSettings == null ||
        reader.languageSentenceSettings!.languageId != langId) {
      try {
        await ref
            .read(readerProvider.notifier)
            .fetchLanguageSentenceSettings(langId);
      } catch (e) {
        ApiLogger.logError('fetchLanguageSettings', e);
        state = state.copyWith(
          errorMessage: 'Failed to load language settings: $e',
          isParsing: false,
        );
        return;
      }
    }

    final sentenceSettings = reader.languageSentenceSettings;
    if (sentenceSettings == null) {
      state = state.copyWith(
        errorMessage: 'Failed to load language settings. Please try again.',
        isParsing: false,
      );
      return;
    }

    try {
      final parser = SentenceParser(
        settings: sentenceSettings,
        combineThreshold: combineThreshold,
      );

      final sentences = parser.parsePage(
        reader.pageData!.paragraphs,
        combineThreshold,
      );

      await _cacheService.saveToCache(
        bookId,
        pageNum,
        langId,
        combineThreshold,
        sentences,
      );

      state = state.copyWith(
        customSentences: sentences,
        currentSentenceIndex: initialIndex == -1
            ? sentences.length - 1
            : (initialIndex ?? 0),
        errorMessage: null,
        isParsing: false,
        lastParsedBookId: bookId,
        lastParsedPageNum: pageNum,
      );
    } catch (e, stackTrace) {
      ApiLogger.logError(
        'parseSentences',
        e,
        details: 'bookId=$bookId, pageNum=$pageNum, langId=$langId',
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        errorMessage:
            'Failed to parse sentences for page $pageNum. Check console for details.',
        isParsing: false,
      );
    }
  }

  Future<void> nextSentence() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null) return;

    if (state.currentSentenceIndex < state.customSentences.length - 1) {
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex + 1,
      );

      if (state.currentSentenceIndex >= state.customSentences.length - 3) {
        _triggerPrefetch(reader);
      }
    } else {
      if (reader.pageData!.currentPage >= reader.pageData!.pageCount) {
        return;
      }

      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;
        final pageCount = reader.pageData!.pageCount;

        if (currentPage < pageCount) {
          await ref
              .read(readerProvider.notifier)
              .markPageRead(reader.pageData!.bookId, currentPage);

          await ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: reader.pageData!.bookId,
                pageNum: currentPage + 1,
                showFullPageError:
                    false, // Don't show full page error for navigation
              );

          final langId = _getLangIdFromPageData();
          await parseSentencesForPage(langId, initialIndex: 0);

          state = state.copyWith(isNavigating: false);
        }
      } catch (e) {
        ApiLogger.logError('nextSentence', e);
        state = state.copyWith(isNavigating: false);
      }
    }
  }

  Future<void> previousSentence() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null) return;

    if (state.currentSentenceIndex > 0) {
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex - 1,
      );
    } else {
      if (reader.pageData!.currentPage <= 1) {
        return;
      }

      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;

        if (currentPage > 1) {
          await ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: reader.pageData!.bookId,
                pageNum: currentPage - 1,
                showFullPageError:
                    false, // Don't show full page error for navigation
              );

          final langId = _getLangIdFromPageData();
          await parseSentencesForPage(langId, initialIndex: -1);

          state = state.copyWith(isNavigating: false);
        }
      } catch (e) {
        ApiLogger.logError('previousSentence', e);
        state = state.copyWith(isNavigating: false);
      }
    }
  }

  void _triggerPrefetch(ReaderState reader) async {
    try {
      if (reader.pageData != null &&
          reader.pageData!.currentPage < reader.pageData!.pageCount) {
        final nextPage = reader.pageData!.currentPage + 1;

        final langId = _getLangIdFromPageData();
        _prefetchPage(reader.pageData!.bookId, nextPage, langId);
      }
    } catch (e) {
      ApiLogger.logError('_triggerPrefetch', e);
    }
  }

  Future<void> _prefetchPage(int bookId, int pageNum, int langId) async {
    try {
      await ref
          .read(readerProvider.notifier)
          .loadPage(
            bookId: bookId,
            pageNum: pageNum,
            updateReaderState: false,
            showFullPageError:
                false, // Don't show full page error for prefetching
          );

      await parseSentencesForPage(langId, initialIndex: 0);
    } catch (e) {
      ApiLogger.logError('_prefetchPage', e);
    }
  }

  Future<void> loadSavedPosition() async {
    final settings = ref.read(settingsProvider);
    final reader = ref.read(readerProvider);

    if (reader.pageData == null || state.customSentences.isEmpty) {
      state = state.copyWith(currentSentenceIndex: 0);
      return;
    }

    if (settings.currentBookPage == reader.pageData!.currentPage &&
        settings.currentBookSentenceIndex != null) {
      final savedIndex = settings.currentBookSentenceIndex!;
      if (savedIndex >= 0 && savedIndex < state.customSentences.length) {
        state = state.copyWith(currentSentenceIndex: savedIndex);
      } else {
        state = state.copyWith(currentSentenceIndex: 0);
      }
    }
  }

  Future<void> clearCacheForThresholdChange() async {
    final reader = ref.read(readerProvider);

    if (reader.pageData != null) {
      final bookId = reader.pageData!.bookId;

      await _cacheService.clearBookCache(bookId);

      state = state.copyWith(lastParsedBookId: null, lastParsedPageNum: null);
    }
  }

  Future<void> clearCacheForTermChange() async {
    final reader = ref.read(readerProvider);

    if (reader.pageData != null) {
      final bookId = reader.pageData!.bookId;

      await _cacheService.clearBookCache(bookId);

      state = state.copyWith(lastParsedBookId: null, lastParsedPageNum: null);
    }
  }

  void goToSentence(int index) {
    if (index >= 0 && index < state.customSentences.length) {
      state = state.copyWith(currentSentenceIndex: index);
    }
  }

  void resetToFirst() {
    state = state.copyWith(currentSentenceIndex: 0);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void updateTermStatusInSentences(int termId, String status) {
    final updatedSentences = state.customSentences.map((sentence) {
      final updatedItems = sentence.textItems.map((item) {
        if (item.wordId == termId) {
          return item.copyWith(statusClass: 'status$status');
        }
        return item;
      }).toList();
      return sentence.copyWith(textItems: updatedItems);
    }).toList();

    state = state.copyWith(customSentences: updatedSentences);
  }

  Future<void> triggerFlushAndRebuild() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null) return;

    final bookId = reader.pageData!.bookId;
    final pageNum = reader.pageData!.currentPage;
    final langId = _getLangIdFromPageData();

    await _cacheService.clearBookCache(bookId);

    // Also clear tooltip cache for this book if needed
    final settings = ref.read(settingsProvider);
    if (settings.enableTooltipCaching) {
      try {} catch (e) {
        ApiLogger.logError('clearTooltipCache', e);
      }
    }

    await ref
        .read(readerProvider.notifier)
        .loadPage(
          bookId: bookId,
          pageNum: pageNum,
          updateReaderState: true,
          showFullPageError:
              false, // Don't show full page error for manual refresh
        );

    final freshReader = ref.read(readerProvider);
    if (freshReader.pageData != null) {
      await parseSentencesForPage(langId, initialIndex: 0);
      await loadSavedPosition();
    }
  }

  /// Fetch term tooltip using cache if enabled
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
        ApiLogger.logError('getTooltipFromCache', e);
      }
    }

    // Fetch from network via the reader provider
    try {
      final result = await ref
          .read(readerProvider.notifier)
          .fetchTermTooltip(termId);
      return result;
    } catch (e) {
      return null;
    }
  }
}

final sentenceCacheServiceProvider = Provider<SentenceCacheService>((ref) {
  return SentenceCacheService();
});

final sentenceReaderProvider =
    NotifierProvider<SentenceReaderNotifier, SentenceReaderState>(() {
      return SentenceReaderNotifier();
    });
