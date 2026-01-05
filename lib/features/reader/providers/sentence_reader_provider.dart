import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/sentence_parser.dart';
import '../services/sentence_cache_service.dart';
import 'reader_provider.dart';

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
    if (reader.pageData?.paragraphs?.isNotEmpty == true &&
        reader.pageData!.paragraphs[0].textItems.isNotEmpty) {
      return reader.pageData!.paragraphs[0].textItems.first.langId ?? 0;
    }
    return 0;
  }

  Future<void> parseSentencesForPage(int langId, {int? initialIndex}) async {
    print(
      'DEBUG: parseSentencesForPage called with langId=$langId, initialIndex=$initialIndex',
    );
    final reader = ref.read(readerProvider);
    final settings = ref.read(settingsProvider);

    print('DEBUG: reader.pageData=${reader.pageData != null}');
    if (reader.pageData == null) {
      print('DEBUG: parseSentencesForPage returning early - no pageData');
      return;
    }

    state = state.copyWith(isParsing: true);

    final bookId = reader.pageData!.bookId;
    final pageNum = reader.pageData!.currentPage;
    final combineThreshold = settings.combineShortSentences ?? 3;

    print(
      'DEBUG: Checking cache for bookId=$bookId, pageNum=$pageNum, langId=$langId, threshold=$combineThreshold',
    );

    final isNavigatingBack =
        state.customSentences.isNotEmpty &&
        state.lastParsedPageNum != null &&
        state.lastParsedPageNum! > pageNum;

    if (state.lastParsedBookId == bookId &&
        state.lastParsedPageNum != null &&
        state.lastParsedPageNum != pageNum &&
        state.customSentences.isNotEmpty) {
      print(
        'DEBUG: BookId=$bookId matches but pageNum changed from ${state.lastParsedPageNum} to $pageNum, clearing stale data (isNavigatingBack=$isNavigatingBack)',
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

    print(
      'DEBUG: cachedSentences=${cachedSentences != null ? "FOUND (${cachedSentences.length})" : "NOT FOUND"}',
    );

    print('DEBUG: About to check language settings...');

    if (cachedSentences != null) {
      final isSamePage =
          state.lastParsedBookId == bookId &&
          state.lastParsedPageNum == pageNum;
      final shouldPreserveIndex =
          isSamePage &&
          state.customSentences.isNotEmpty &&
          state.customSentences.length == cachedSentences!.length &&
          state.currentSentenceIndex < cachedSentences!.length;

      final resolvedIndex = initialIndex == -1
          ? cachedSentences!.length - 1
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
      print(
        'DEBUG: Loaded ${cachedSentences.length} sentences from cache - isSamePage=$isSamePage, shouldPreserveIndex=$shouldPreserveIndex, lastParsedPageNum=${state.lastParsedPageNum}, currentPageNum=$pageNum, resolvedIndex=$resolvedIndex',
      );
      return;
    }

    print('DEBUG: No cache, checking if language settings needed...');
    print(
      'DEBUG: reader.languageSentenceSettings=${reader.languageSentenceSettings != null}',
    );
    if (reader.languageSentenceSettings == null ||
        reader.languageSentenceSettings!.languageId != langId) {
      print('DEBUG: Fetching language settings for langId=$langId');
      await ref
          .read(readerProvider.notifier)
          .fetchLanguageSentenceSettings(langId);
      print('DEBUG: Language settings fetched');
    } else {
      print('DEBUG: Language settings already loaded for langId=$langId');
    }

    print('DEBUG: No cache found, checking language settings...');
    if (reader.languageSentenceSettings == null ||
        reader.languageSentenceSettings!.languageId != langId) {
      print('DEBUG: Fetching language settings for langId=$langId');
      try {
        await ref
            .read(readerProvider.notifier)
            .fetchLanguageSentenceSettings(langId);
      } catch (e) {
        print('DEBUG: Error fetching language settings: $e');
        state = state.copyWith(
          errorMessage: 'Failed to load language settings: $e',
          isParsing: false,
        );
        return;
      }
    }

    final sentenceSettings = reader.languageSentenceSettings;
    print('DEBUG: sentenceSettings=${sentenceSettings != null}');
    if (sentenceSettings == null) {
      print('DEBUG: Language settings is null after fetch, setting error');
      print(
        'DEBUG: ERROR: reader.languageSentenceSettings is null even after fetch!',
      );
      state = state.copyWith(
        errorMessage: 'Failed to load language settings. Please try again.',
        isParsing: false,
      );
      return;
    }

    print('DEBUG: About to start parsing sentences...');

    print('DEBUG: Language settings loaded, starting parse...');

    try {
      print('DEBUG: Parsing sentences for page $pageNum');
      print('DEBUG: Paragraphs count: ${reader.pageData!.paragraphs.length}');

      final parser = SentenceParser(
        settings: sentenceSettings,
        combineThreshold: combineThreshold,
      );

      final sentences = parser.parsePage(
        reader.pageData!.paragraphs,
        combineThreshold,
      );

      print('DEBUG: Parsed ${sentences.length} sentences');
      if (sentences.isNotEmpty && sentences[0].textItems.isNotEmpty) {
        final firstItem = sentences[0].textItems[0];
        print(
          'DEBUG: After parse - first textItem text="${firstItem.text}", wordId=${firstItem.wordId}',
        );
      }

      print('DEBUG: Saving to cache...');
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
      print(
        'DEBUG: Parsing complete, state updated - ${sentences.length} sentences, set index to ${initialIndex == -1 ? sentences.length - 1 : (initialIndex ?? 0)}',
      );
    } catch (e, stackTrace) {
      print(
        'Sentence parsing error: bookId=$bookId, pageNum=$pageNum, langId=$langId, threshold=$combineThreshold, error=$e',
      );
      print('DEBUG: Stack trace: $stackTrace');

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

    print(
      'DEBUG: nextSentence called, currentSentenceIndex=${state.currentSentenceIndex}, customSentences.length=${state.customSentences.length}, currentSentenceId=${state.currentSentence?.id}',
    );

    if (state.currentSentenceIndex < state.customSentences.length - 1) {
      print('DEBUG: nextSentence: Moving to next sentence within page');
      final oldIndex = state.currentSentenceIndex;
      final oldSentenceId = state.currentSentence?.id;
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex + 1,
      );
      final newSentenceId = state.currentSentence?.id;
      print(
        'DEBUG: nextSentence: Updated index from $oldIndex to ${state.currentSentenceIndex}, sentenceId from $oldSentenceId to $newSentenceId',
      );

      if (state.currentSentenceIndex >= state.customSentences.length - 3) {
        _triggerPrefetch(reader);
      }
    } else {
      if (reader.pageData!.currentPage >= reader.pageData!.pageCount) {
        print('DEBUG: nextSentence: Already on last page, no next page');
        return;
      }

      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;
        final pageCount = reader.pageData!.pageCount;

        print(
          'DEBUG: nextSentence: At end of sentences, navigating from page $currentPage to page ${currentPage + 1}',
        );

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

          print(
            'DEBUG: nextSentence: Loaded page ${currentPage + 1} with ${state.customSentences.length} sentences, set index to 0',
          );
          state = state.copyWith(isNavigating: false);
        }
      } catch (e) {
        print('DEBUG: nextSentence: Error during page navigation: $e');
        state = state.copyWith(isNavigating: false);
      }
    }
  }

  Future<void> previousSentence() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null) return;

    print(
      'DEBUG: previousSentence called, currentSentenceIndex=${state.currentSentenceIndex}, customSentences.length=${state.customSentences.length}, currentPage=${reader.pageData!.currentPage}',
    );

    if (state.currentSentenceIndex > 0) {
      print('DEBUG: previousSentence: Moving to previous sentence within page');
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex - 1,
      );
    } else {
      if (reader.pageData!.currentPage <= 1) {
        print(
          'DEBUG: previousSentence: Already on first page, no previous page',
        );
        return;
      }

      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;

        print(
          'DEBUG: previousSentence: At first sentence, navigating from page $currentPage to page ${currentPage - 1}',
        );

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

          print(
            'DEBUG: previousSentence: Loaded page ${currentPage - 1} with ${state.customSentences.length} sentences, set index to ${state.currentSentenceIndex}',
          );
          state = state.copyWith(isNavigating: false);
        }
      } catch (e) {
        print('DEBUG: previousSentence: Error during page navigation: $e');
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
      print('Prefetch error: $e');
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
      print('Prefetch parse error: $e');
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

    print('DEBUG: triggerFlushAndRebuild: Clearing cache for bookId=$bookId');
    await _cacheService.clearBookCache(bookId);

    print(
      'DEBUG: triggerFlushAndRebuild: Reloading page bookId=$bookId, pageNum=$pageNum',
    );
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
      print(
        'DEBUG: triggerFlushAndRebuild: Parsing sentences for langId=$langId',
      );
      await parseSentencesForPage(langId, initialIndex: 0);
      await loadSavedPosition();
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
