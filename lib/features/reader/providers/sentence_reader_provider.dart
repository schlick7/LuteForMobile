import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/paragraph.dart';
import '../models/language_sentence_settings.dart';
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

  const SentenceReaderState({
    this.currentSentenceIndex = 0,
    this.isNavigating = false,
    this.isParsing = false,
    this.customSentences = const [],
    this.errorMessage,
    this.shouldFlushAndRebuild = false,
  });

  CustomSentence? get currentSentence {
    if (currentSentenceIndex >= 0 &&
        currentSentenceIndex < customSentences.length) {
      return customSentences[currentSentenceIndex];
    }
    return null;
  }

  int get totalSentences => customSentences.length;
  bool get canGoNext => currentSentenceIndex < totalSentences - 1;
  bool get canGoPrevious => currentSentenceIndex > 0;
  String get sentencePosition => '${currentSentenceIndex + 1}/$totalSentences';

  SentenceReaderState copyWith({
    int? currentSentenceIndex,
    bool? isNavigating,
    bool? isParsing,
    List<CustomSentence>? customSentences,
    String? errorMessage,
    bool? shouldFlushAndRebuild,
  }) {
    return SentenceReaderState(
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      isParsing: isParsing ?? this.isParsing,
      customSentences: customSentences ?? this.customSentences,
      errorMessage: errorMessage,
      shouldFlushAndRebuild:
          shouldFlushAndRebuild ?? this.shouldFlushAndRebuild,
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

  int _getLangIdFromPageData() {
    final reader = ref.read(readerProvider);
    if (reader.pageData?.paragraphs?.isNotEmpty == true &&
        reader.pageData!.paragraphs[0].textItems.isNotEmpty) {
      return reader.pageData!.paragraphs[0].textItems.first.langId ?? 0;
    }
    return 0;
  }

  Future<void> parseSentencesForPage(int langId) async {
    print('DEBUG: parseSentencesForPage called with langId=$langId');
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
    final cachedSentences = await _cacheService.getFromCache(
      bookId,
      pageNum,
      langId,
      combineThreshold,
    );

    print(
      'DEBUG: cachedSentences=${cachedSentences != null ? "FOUND (${cachedSentences.length})" : "NOT FOUND"}',
    );

    if (cachedSentences != null) {
      state = state.copyWith(
        customSentences: cachedSentences,
        currentSentenceIndex: 0,
        errorMessage: null,
        isParsing: false,
      );
      print('DEBUG: Loaded ${cachedSentences.length} sentences from cache');
      return;
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
    if (sentenceSettings == null) {
      print('DEBUG: Language settings is null after fetch');
      state = state.copyWith(
        errorMessage: 'Failed to load language settings. Please try again.',
        isParsing: false,
      );
      return;
    }

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
        currentSentenceIndex: 0,
        errorMessage: null,
        isParsing: false,
      );
      print('DEBUG: Parsing complete, state updated');
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
    if (reader.pageData == null || state.customSentences.isEmpty) return;

    if (state.currentSentenceIndex < state.customSentences.length - 1) {
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex + 1,
      );

      if (state.currentSentenceIndex >= state.customSentences.length - 3) {
        _triggerPrefetch(reader);
      }
    } else {
      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;
        final pageCount = reader.pageData!.pageCount;

        if (currentPage < pageCount) {
          await ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: reader.pageData!.bookId,
                pageNum: currentPage + 1,
              );

          final langId = _getLangIdFromPageData();
          await parseSentencesForPage(langId);

          state = state.copyWith(currentSentenceIndex: 0, isNavigating: false);
        }
      } catch (e) {
        state = state.copyWith(isNavigating: false);
      }
    }
  }

  Future<void> previousSentence() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData == null || state.customSentences.isEmpty) return;

    if (state.currentSentenceIndex > 0) {
      state = state.copyWith(
        currentSentenceIndex: state.currentSentenceIndex - 1,
      );
    } else {
      state = state.copyWith(isNavigating: true);
      try {
        final currentPage = reader.pageData!.currentPage;

        if (currentPage > 1) {
          await ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: reader.pageData!.bookId,
                pageNum: currentPage - 1,
              );

          final langId = _getLangIdFromPageData();
          await parseSentencesForPage(langId);

          state = state.copyWith(
            currentSentenceIndex: state.customSentences.length - 1,
            isNavigating: false,
          );
        }
      } catch (e) {
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
          .loadPage(bookId: bookId, pageNum: pageNum, updateReaderState: false);

      await parseSentencesForPage(langId);
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
    } else {
      state = state.copyWith(currentSentenceIndex: 0);
    }
  }

  Future<void> clearCacheForThresholdChange() async {
    final reader = ref.read(readerProvider);

    if (reader.pageData != null) {
      final bookId = reader.pageData!.bookId;

      await _cacheService.clearBookCache(bookId);
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
        .loadPage(bookId: bookId, pageNum: pageNum, updateReaderState: true);

    final freshReader = ref.read(readerProvider);
    if (freshReader.pageData != null) {
      print(
        'DEBUG: triggerFlushAndRebuild: Parsing sentences for langId=$langId',
      );
      await parseSentencesForPage(langId);
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
