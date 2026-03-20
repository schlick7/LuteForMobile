import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/widget_logger.dart';
import '../../../shared/widgets/app_bar_leading.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../providers/reader_provider.dart';
import '../providers/sentence_reader_provider.dart';
import '../providers/sentence_tts_provider.dart';
import '../providers/current_book_provider.dart';
import '../widgets/term_tooltip.dart';
import '../widgets/term_form.dart';
import '../widgets/sentence_translation.dart';
import '../widgets/sentence_reader_display.dart';
import '../widgets/term_list_display.dart';
import '../widgets/sentence_tts_button.dart';
import '../widgets/sentence_ai_translation_button.dart';
import '../widgets/sentence_ai_translation_widget.dart';
import '../utils/sentence_parser.dart';
import '../../../core/network/dictionary_service.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/utils/language_flag_mapper.dart';
import '../../../features/stats/providers/stats_provider.dart';
import '../../../features/stats/models/stats_data.dart';
import '../../../features/terms/providers/terms_provider.dart';
import '../../../app.dart';

class _PageTransition extends StatefulWidget {
  final Widget child;
  final bool isForward;

  const _PageTransition({
    required this.child,
    required this.isForward,
    Key? key,
  }) : super(key: key);

  @override
  State<_PageTransition> createState() => _PageTransitionState();
}

class _PageTransitionState extends State<_PageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Widget _oldChild;
  Widget? _currentChild;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _currentChild = widget.child;
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_PageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _oldChild = oldWidget.child;
      _currentChild = widget.child;
      _controller.forward(from: 0.0);
      _hasAnimated = true;
    } else if (oldWidget.child != widget.child) {
      _currentChild = widget.child;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_hasAnimated) {
          return _currentChild ?? SizedBox();
        }

        return Stack(
          children: [
            if (_oldChild.key != _currentChild?.key)
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: Offset.zero,
                      end: widget.isForward
                          ? const Offset(-1.0, 0.0)
                          : const Offset(1.0, 0.0),
                    ).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: _oldChild,
              ),
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: widget.isForward
                        ? const Offset(1.0, 0.0)
                        : const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: _currentChild,
            ),
          ],
        );
      },
    );
  }
}

class SentenceReaderScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SentenceReaderScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<SentenceReaderScreen> createState() =>
      SentenceReaderScreenState();
}

class SentenceReaderScreenState extends ConsumerState<SentenceReaderScreen>
    with WidgetsBindingObserver {
  TermForm? _currentTermForm;
  final Map<int, TermTooltip> _termTooltips = {};
  bool _tooltipsLoadInProgress = false;
  bool _preloadInProgress = false;
  int _mainBuildCount = 0;
  int _topSectionBuildCount = 0;
  int _bottomSectionBuildCount = 0;

  int? _lastInitializedBookId;
  int? _lastInitializedPageNum;
  int? _lastTooltipsBookId;
  bool _hasInitialized = false;
  int? _currentSentenceId;
  AppLifecycleState? _lastLifecycleState;
  bool _settingsListenerSetup = false;
  bool _isParsing = false;
  bool _initializationFailed = false;
  bool _isDictionaryOpen = false;
  bool _isLastPageMarkedDone = false;
  SentenceTTSNotifier? _ttsNotifier;
  bool _isNavigatingForward = true;
  Map<int, String> _languageIdToName = {};
  int? _lastStatsLangId;
  bool _checkServerPageInProgress = false;
  int _splitRatio = DictionaryService.defaultSplitRatio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, _loadLanguageMapping);
    Future.delayed(Duration.zero, _loadStatsIfNeeded);
    Future.delayed(Duration.zero, _loadSplitRatio);
  }

  Future<void> _loadSplitRatio() async {
    final dictionaryService = ref.read(dictionaryServiceProvider);
    final ratio = await dictionaryService.getSentenceReaderSplitRatio();
    if (mounted) {
      setState(() {
        _splitRatio = ratio;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ttsNotifier?.stop();
    super.dispose();
  }

  void _loadStatsIfNeeded() {
    final statsState = ref.read(statsProvider);
    if (statsState.value == null && !statsState.isLoading) {
      ref.read(statsProvider.notifier).loadStats();
    }
  }

  Future<void> _loadLanguageMapping() async {
    final repository = ref.read(readerRepositoryProvider);
    try {
      final languages = await repository.contentService.getLanguagesWithIds();
      setState(() {
        _languageIdToName = {for (var lang in languages) lang.id: lang.name};
      });
    } catch (e) {
      // Failed to load language mapping
    }
  }

  bool _canPreload() {
    return ref.read(currentScreenRouteProvider) == 'sentence-reader' &&
        _lastLifecycleState != AppLifecycleState.paused;
  }

  int _getLangId(ReaderState reader) {
    if (reader.pageData?.paragraphs.isNotEmpty == true &&
        reader.pageData!.paragraphs[0].textItems.isNotEmpty) {
      return reader.pageData!.paragraphs[0].textItems.first.langId ?? 0;
    }
    return 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      if (!_checkServerPageInProgress) {
        _checkServerPage();
      }
    }
  }

  Future<void> _checkServerPage() async {
    if (_checkServerPageInProgress) {
      return;
    }
    _checkServerPageInProgress = true;

    final pageData = ref.read(readerProvider).pageData;
    if (pageData != null) {
      try {
        final serverPage = await ref
            .read(readerProvider.notifier)
            .getCurrentPageForBook(pageData.bookId);

        if (serverPage != -1 && serverPage != pageData.currentPage) {
          ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: pageData.bookId,
                pageNum: serverPage,
                showFullPageError: false,
              );
        }
      } catch (e) {
        print('Error checking server page: $e');
      }
    }

    _checkServerPageInProgress = false;
  }

  @override
  Widget build(BuildContext context) {
    final currentScreenRoute = ref.watch(currentScreenRouteProvider);
    final isVisible = currentScreenRoute == 'sentence-reader';

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    _mainBuildCount++;
    WidgetLogger.logRebuild(
      'SentenceReaderScreen',
      _mainBuildCount,
      'isVisible=$isVisible',
    );

    final pageTitle = ref.watch(
      readerProvider.select((state) => state.pageData?.title),
    );
    final readerState = ref.read(readerProvider);
    final sentenceReader = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    if (currentSentence != null && _currentSentenceId != currentSentence.id) {
      setState(() {
        _currentSentenceId = currentSentence.id;
      });
    }

    if (isVisible && readerState.pageData != null && !readerState.isLoading) {
      final bookId = readerState.pageData!.bookId;
      final pageNum = readerState.pageData!.currentPage;

      if (_lastInitializedBookId != bookId ||
          _lastInitializedPageNum != pageNum) {
        // Page changed - forcing reinitialization
        _hasInitialized = false;
        _lastInitializedBookId = bookId;
        _lastInitializedPageNum = pageNum;
        _initializationFailed = false;
      }

      if (!_hasInitialized) {
        final langId = _getLangId(readerState);

        if (_lastTooltipsBookId != bookId) {
          _termTooltips.clear();
          _lastTooltipsBookId = bookId;
        }

        if (!_isParsing) {
          final sentenceReader = ref.read(sentenceReaderProvider);

          if (sentenceReader.lastParsedBookId == bookId &&
              sentenceReader.lastParsedPageNum == pageNum &&
              sentenceReader.customSentences.isNotEmpty) {
            ref.read(sentenceReaderProvider.notifier).syncStatusFromPageData();
            _hasInitialized = true;
            _initializationFailed = false;
            ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
            _loadTooltipsForCurrentSentence();
          } else {
            _isParsing = true;
            Future(() {
              ref
                  .read(sentenceReaderProvider.notifier)
                  .parseSentencesForPage(langId, initialIndex: 0)
                  .then((_) {
                    if (mounted) {
                      _isParsing = false;
                      final sentenceReader = ref.read(sentenceReaderProvider);

                      if (sentenceReader.customSentences.isNotEmpty) {
                        _hasInitialized = true;
                        _initializationFailed = false;
                      } else {
                        _hasInitialized = false;
                        _initializationFailed = true;
                      }
                      ref
                          .read(sentenceReaderProvider.notifier)
                          .loadSavedPosition();
                      _loadTooltipsForCurrentSentence();
                    }
                  })
                  .catchError((e, stackTrace) {
                    if (mounted) {
                      _isParsing = false;
                      _hasInitialized = false;
                      _initializationFailed = true;
                    }
                  });
            });
          }
        }
      }
    }

    if (isVisible && _hasInitialized && !_settingsListenerSetup) {
      _setupSettingsListener();
    }

    if (isVisible && _initializationFailed && !_isParsing) {
      _hasInitialized = false;
      _initializationFailed = false;
    }

    if (isVisible &&
        _hasInitialized &&
        currentSentence != null &&
        currentSentence.id != _currentSentenceId) {
      _currentSentenceId = currentSentence.id;
      _loadTooltipsForCurrentSentence();
    }

    ref.listen<ReaderState>(readerProvider, (previous, next) {
      final prevPage = previous?.pageData;
      final nextPage = next.pageData;

      if (_hasInitialized &&
          prevPage != null &&
          nextPage != null &&
          prevPage != nextPage) {
        ref.read(sentenceReaderProvider.notifier).syncStatusFromPageData();
      }
    });

    if (readerState.isLoading || sentenceReader.isParsing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sentence Reader'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(navigationProvider).navigateToScreen('reader'),
              tooltip: 'Close',
            ),
          ],
        ),
        body: const LoadingIndicator(message: 'Loading content...'),
      );
    }

    if (readerState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sentence Reader'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(navigationProvider).navigateToScreen('reader'),
              tooltip: 'Close',
            ),
          ],
        ),
        body: ErrorDisplay(
          message: readerState.errorMessage!,
          onRetry: () {
            ref.read(readerProvider.notifier).clearError();
            final pageData = ref.read(readerProvider).pageData;
            if (pageData != null) {
              ref
                  .read(readerProvider.notifier)
                  .loadPage(
                    bookId: pageData.bookId,
                    pageNum: pageData.currentPage,
                  );
            }
          },
        ),
      );
    }

    if (readerState.pageData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sentence Reader'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(navigationProvider).navigateToScreen('reader'),
              tooltip: 'Close',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 64),
              const SizedBox(height: 16),
              const Text('No Book Loaded'),
              const SizedBox(height: 8),
              const Text(
                'Select a book from the books screen to start reading.',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(navigationProvider).navigateToScreen('books'),
                icon: const Icon(Icons.collections_bookmark),
                label: const Text('Browse Books'),
              ),
            ],
          ),
        ),
      );
    }

    final textSettings = ref.watch(textFormattingSettingsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AppBarLeading(scaffoldKey: widget.scaffoldKey),
        title: Text(pageTitle ?? 'Sentence Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(navigationProvider).navigateToScreen('reader'),
            tooltip: 'Close',
          ),
        ],
      ),
      body: settings.pageTurnAnimations
          ? _PageTransition(
              isForward: _isNavigatingForward,
              child: Column(
                key: ValueKey('column-${currentSentence?.id ?? "null"}'),
                children: [
                  Expanded(
                    flex: 10 - _splitRatio,
                    child: _buildTopSection(
                      textSettings,
                      settings,
                      currentSentence,
                    ),
                  ),
                  Expanded(
                    flex: _splitRatio,
                    child: _buildBottomSection(currentSentence),
                  ),
                ],
              ),
            )
          : Column(
              key: ValueKey('column-${currentSentence?.id ?? "null"}'),
              children: [
                Expanded(
                  flex: 10 - _splitRatio,
                  child: _buildTopSection(
                    textSettings,
                    settings,
                    currentSentence,
                  ),
                ),
                Expanded(
                  flex: _splitRatio,
                  child: _buildBottomSection(currentSentence),
                ),
              ],
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ref.read(settingsProvider).showStatsBar) _buildStatsRow(),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildTopSection(
    dynamic textSettings,
    dynamic settings,
    CustomSentence? currentSentence,
  ) {
    _topSectionBuildCount++;
    WidgetLogger.logRebuild(
      'SentenceReaderScreen._buildTopSection',
      _topSectionBuildCount,
    );

    if (currentSentence == null) {
      return const Center(child: Text('No sentence available'));
    }

    return GestureDetector(
      onTapDown: (_) => TermTooltipClass.close(),
      onHorizontalDragEnd: (details) async {
        final textSettings = ref.read(textFormattingSettingsProvider);
        if (!textSettings.swipeNavigationEnabled) return;

        final velocity = details.primaryVelocity ?? 0;
        const minSwipeVelocity = 300.0;

        if (velocity.abs() < minSwipeVelocity) return;

        final sentenceReaderNotifier = ref.read(
          sentenceReaderProvider.notifier,
        );

        if (velocity > 0) {
          if (sentenceReaderNotifier.canGoPrevious) {
            _goPrevious();
          }
        } else if (velocity < 0) {
          if (sentenceReaderNotifier.canGoNext) {
            final textSettings = ref.read(textFormattingSettingsProvider);
            final reader = ref.read(readerProvider);

            if (textSettings.swipeMarksRead && reader.pageData != null) {
              ref
                  .read(readerProvider.notifier)
                  .markPageRead(
                    reader.pageData!.bookId,
                    reader.pageData!.currentPage,
                  );
            }

            await _goNext();
          }
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).systemGestureInsets.bottom,
          ),
          child: SentenceReaderDisplay(
            sentence: currentSentence,
            onTap: (item, context) => _handleTap(item, context),
            onDoubleTap: (item) => _handleDoubleTap(item),
            onLongPress: (item) => _handleLongPress(item),
            textSize: textSettings.textSize,
            lineSpacing: textSettings.lineSpacing,
            fontFamily: textSettings.fontFamily,
            fontWeight: textSettings.fontWeight,
            isItalic: textSettings.isItalic,
            doubleTapTimeout: settings.doubleTapTimeout,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(CustomSentence? currentSentence) {
    _bottomSectionBuildCount++;
    WidgetLogger.logRebuild(
      'SentenceReaderScreen._buildBottomSection',
      _bottomSectionBuildCount,
    );

    final settings = ref.watch(settingsProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) async {
        final textSettings = ref.read(textFormattingSettingsProvider);
        if (!textSettings.swipeNavigationEnabled) return;

        final velocity = details.primaryVelocity ?? 0;
        const minSwipeVelocity = 300.0;

        if (velocity.abs() < minSwipeVelocity) return;

        final sentenceReaderNotifier = ref.read(
          sentenceReaderProvider.notifier,
        );

        if (velocity > 0) {
          if (sentenceReaderNotifier.canGoPrevious) {
            _goPrevious();
          }
        } else if (velocity < 0) {
          if (sentenceReaderNotifier.canGoNext) {
            final textSettings = ref.read(textFormattingSettingsProvider);
            final reader = ref.read(readerProvider);

            if (textSettings.swipeMarksRead && reader.pageData != null) {
              ref
                  .read(readerProvider.notifier)
                  .markPageRead(
                    reader.pageData!.bookId,
                    reader.pageData!.currentPage,
                  );
            }

            await _goNext();
          }
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Terms', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: () => _showSplitRatioDialog(context),
                  tooltip: 'Adjust split ratio',
                ),
                const Spacer(),
                if (currentSentence != null) ...[
                  SentenceAITranslationButton(
                    text: currentSentence.textItems
                        .map((item) => item.text)
                        .join(),
                    sentenceId: currentSentence.id,
                    languageId: currentSentence.textItems.first.langId ?? 0,
                    language: 'English',
                    onTranslationRequested: () => _showAITranslation(
                      currentSentence.textItems.map((item) => item.text).join(),
                      currentSentence.textItems.first.langId ?? 0,
                    ),
                  ),
                  SentenceTTSButton(
                    text: currentSentence.textItems
                        .map((item) => item.text)
                        .join(),
                    sentenceId: currentSentence.id,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TermListDisplay(
              sentence: currentSentence,
              tooltips: _termTooltips,
              onTermTap: (item, context) => _handleTap(item, context),
              onTermDoubleTap: (item) => _handleDoubleTap(item),
              showKnownTerms: settings.showKnownTermsInSentenceReader,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final pageData = ref.watch(readerProvider).pageData;
    final sentenceReaderState = ref.watch(sentenceReaderProvider);
    final sentenceReaderNotifier = ref.read(sentenceReaderProvider.notifier);
    final sentencePosition = sentenceReaderState.sentencePosition;

    String pageDisplay = sentencePosition;
    if (pageData != null) {
      pageDisplay = '(${pageData.pageIndicator}) - $sentencePosition';
    }

    final isLastPage =
        pageData != null && pageData.currentPage == pageData.pageCount;
    final isLastSentence =
        sentenceReaderState.currentSentenceIndex ==
        sentenceReaderState.customSentences.length - 1;
    final theme = Theme.of(context);

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(pageDisplay, style: theme.textTheme.bodyMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: sentenceReaderNotifier.canGoPrevious
                  ? () => _goPrevious()
                  : null,
              iconSize: 24,
            ),
            if (isLastPage && isLastSentence)
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: _isLastPageMarkedDone
                      ? theme.colorScheme.primary
                      : null,
                ),
                onPressed: () => _markLastPageDone(),
                iconSize: 24,
                tooltip: 'Mark as done',
              )
            else
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: sentenceReaderNotifier.canGoNext
                    ? () => _goNext()
                    : null,
                iconSize: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final sentenceReaderState = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReaderState.currentSentence;

    int? langId;
    if (currentSentence != null && currentSentence.textItems.isNotEmpty) {
      langId = currentSentence.textItems.first.langId;
    }

    final languageName = langId != null
        ? (_languageIdToName[langId] ?? '')
        : '';
    if (languageName.isEmpty) {
      return const SizedBox.shrink();
    }
    if (langId != null && langId != _lastStatsLangId) {
      _lastStatsLangId = langId;
      Future.microtask(() {
        final settings = ref.read(settingsProvider);
        if (mounted && settings.showStatsBar && settings.showKnownTermsCount) {
          ref.read(termsProvider.notifier).loadStatus99Only(langId!);
        }
      });
    }

    return Consumer(
      builder: (context, ref, _) {
        final termsState = ref.watch(termsProvider);
        final statsState = ref.watch(statsProvider);

        final languageFlag = getFlagForLanguage(languageName) ?? '';

        int todayWordcount = 0;
        int status99Count = termsState.stats.status99;

        if (statsState.value != null) {
          final today = DateTime.now();

          for (final langStats in statsState.value!.languages) {
            if (langStats.language == languageName) {
              final todayStats = langStats.dailyStats.firstWhere(
                (s) =>
                    s.date.year == today.year &&
                    s.date.month == today.month &&
                    s.date.day == today.day,
                orElse: () => DailyReadingStats(
                  date: today,
                  wordcount: 0,
                  runningTotal: 0,
                ),
              );
              todayWordcount = todayStats.wordcount;
              break;
            }
          }
        }

        final theme = Theme.of(context);
        final showKnownTermsCount = ref
            .read(settingsProvider)
            .showKnownTermsCount;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (languageFlag.isNotEmpty) ...[
                Text(languageFlag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Text(
                "Today's Words: $todayWordcount",
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (showKnownTermsCount)
                Text("Known: $status99Count", style: theme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  void _setupSettingsListener() {
    if (_settingsListenerSetup) return;
    _settingsListenerSetup = true;

    ref.listen<bool>(
      settingsProvider.select((s) => s.showKnownTermsInSentenceReader),
      (previous, next) {
        if (previous != next) {
          _loadTooltipsForCurrentSentence();
        }
      },
    );
  }

  Future<void> _loadTooltipsForCurrentSentence() async {
    if (_tooltipsLoadInProgress) return;

    final sentenceReader = ref.read(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;
    final settings = ref.read(settingsProvider);

    if (currentSentence == null) return;

    final termsNeedingTooltips = _extractTermsNeedingTooltips(
      currentSentence,
      showKnownTerms: settings.showKnownTermsInSentenceReader,
    );

    _tooltipsLoadInProgress = true;

    try {
      final termsToFetch = termsNeedingTooltips
          .where(
            (term) =>
                term.wordId != null && !_termTooltips.containsKey(term.wordId!),
          )
          .toList();

      if (termsToFetch.isEmpty) {
        _tooltipsLoadInProgress = false;
        if (_canPreload()) {
          _preloadNextSentence();
        }
        return;
      }

      final futures = termsToFetch.map((term) async {
        if (term.wordId == null) return null;
        try {
          final termTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(term.wordId!);
          return termTooltip;
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures, eagerError: false);

      final Map<int, TermTooltip> newTooltips = {};
      for (int i = 0; i < results.length; i++) {
        final tooltip = results[i];
        final wordId = termsToFetch[i].wordId;
        if (tooltip != null && wordId != null && tooltip.hasData) {
          newTooltips[wordId] = tooltip;
        }
      }

      print(
        'DEBUG: Successfully loaded ${newTooltips.length}/${termsToFetch.length} tooltips',
      );

      if (mounted && newTooltips.isNotEmpty) {
        setState(() {
          _termTooltips.addAll(newTooltips);
        });
      }
    } finally {
      _tooltipsLoadInProgress = false;
      print(
        'DEBUG: Finished loading tooltips for sentence ID: ${currentSentence.id}',
      );
    }

    if (_canPreload()) {
      _preloadNextSentence();
    }
  }

  List<TextItem> _extractTermsNeedingTooltips(
    CustomSentence sentence, {
    required bool showKnownTerms,
  }) {
    final Map<int, TextItem> termsNeedingTooltips = {};

    for (final item in sentence.textItems) {
      if (item.wordId != null) {
        final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
        final status = statusMatch?.group(1) ?? '0';

        if (status == '0') {
          continue;
        }

        if (status == '98') {
          continue;
        }

        if (!showKnownTerms && status == '99') {
          continue;
        }

        termsNeedingTooltips[item.wordId!] = item;
      }
    }

    return termsNeedingTooltips.values.toList();
  }

  Future<void> _preloadNextSentence() async {
    if (_preloadInProgress) {
      return;
    }

    final sentenceReaderState = ref.read(sentenceReaderProvider);
    final sentenceReaderNotifier = ref.read(sentenceReaderProvider.notifier);
    final settings = ref.read(settingsProvider);

    if (!sentenceReaderNotifier.canGoNext) {
      return;
    }

    final nextIndex = sentenceReaderState.currentSentenceIndex + 1;
    if (nextIndex >= sentenceReaderState.customSentences.length) {
      return;
    }

    final nextSentence = sentenceReaderState.customSentences[nextIndex];

    final termsNeedingTooltips = _extractTermsNeedingTooltips(
      nextSentence,
      showKnownTerms: settings.showKnownTermsInSentenceReader,
    );

    if (termsNeedingTooltips.isEmpty) {
      print(
        'DEBUG: Next sentence has no terms needing tooltips - skipping preload',
      );
      return;
    }

    print(
      'DEBUG: Preloading tooltips for next sentence ID: ${nextSentence.id} (${termsNeedingTooltips.length} terms)',
    );

    final termsToFetch = termsNeedingTooltips
        .where(
          (term) =>
              term.wordId != null && !_termTooltips.containsKey(term.wordId!),
        )
        .toList();

    if (termsToFetch.isEmpty) {
      return;
    }

    if (!_canPreload()) {
      return;
    }

    _preloadInProgress = true;

    try {
      final futures = termsToFetch.map((term) async {
        if (term.wordId == null) return null;
        try {
          if (!_canPreload()) {
            return null;
          }
          final termTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(term.wordId!);
          return termTooltip;
        } catch (e) {
          print(
            'DEBUG: Failed to preload tooltip for wordId=${term.wordId}: $e',
          );
          return null;
        }
      }).toList();

      final results = await Future.wait(futures, eagerError: false);

      final Map<int, TermTooltip> newTooltips = {};
      for (int i = 0; i < results.length; i++) {
        final tooltip = results[i];
        final wordId = termsToFetch[i].wordId;
        if (tooltip != null && wordId != null && tooltip.hasData) {
          newTooltips[wordId] = tooltip;
        }
      }

      print(
        'DEBUG: Successfully preloaded ${newTooltips.length}/${termsToFetch.length} tooltips',
      );

      if (mounted && _canPreload() && newTooltips.isNotEmpty) {
        setState(() {
          _termTooltips.addAll(newTooltips);
        });
      }
    } finally {
      _preloadInProgress = false;
    }
  }

  Future<void> _refreshAffectedTermTooltips(
    TermTooltip updatedTermTooltip,
  ) async {
    final sentenceReader = ref.read(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    if (currentSentence == null) return;

    final currentSentenceTerms = <String, int>{};
    for (final item in currentSentence.textItems) {
      if (item.wordId != null) {
        currentSentenceTerms[item.text.toLowerCase()] = item.wordId!;
      }
    }

    for (final parent in updatedTermTooltip.parents) {
      final parentTermLower = parent.term.toLowerCase();

      if (currentSentenceTerms.containsKey(parentTermLower)) {
        final int parentWordId = currentSentenceTerms[parentTermLower]!;

        print(
          'DEBUG: Refreshing tooltip for affected PARENT term: "${parent.term}" (wordId=$parentWordId)',
        );

        try {
          final parentTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(parentWordId);

          if (parentTooltip != null && mounted) {
            setState(() {
              _termTooltips[parentWordId] = parentTooltip;
            });
          }
        } catch (e) {
          print(
            'DEBUG: Failed to refresh tooltip for parent wordId=$parentWordId: $e',
          );
        }
      }
    }

    for (final child in updatedTermTooltip.children) {
      final childTermLower = child.term.toLowerCase();

      if (currentSentenceTerms.containsKey(childTermLower)) {
        final int childWordId = currentSentenceTerms[childTermLower]!;

        print(
          'DEBUG: Refreshing tooltip for affected CHILD term: "${child.term}" (wordId=$childWordId)',
        );

        try {
          final childTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(childWordId);

          if (childTooltip != null && mounted) {
            setState(() {
              _termTooltips[childWordId] = childTooltip;
            });
          }
        } catch (e) {
          print(
            'DEBUG: Failed to refresh tooltip for child wordId=$childWordId: $e',
          );
        }
      }
    }
  }

  Future<void> _goNext() async {
    setState(() {
      _isNavigatingForward = true;
    });
    await ref.read(sentenceReaderProvider.notifier).nextSentence();
    _saveSentencePosition();

    final pageData = ref.read(readerProvider).pageData;
    final sentenceReader = ref.read(sentenceReaderProvider);
    final currentSentence = ref.read(sentenceReaderProvider).currentSentence;

    print(
      'DEBUG: After nextSentence, new currentSentence=${currentSentence?.id}, currentSentenceIndex=${sentenceReader.currentSentenceIndex}',
    );

    if (pageData != null && sentenceReader.currentSentenceIndex == 0) {
      setState(() {
        _isLastPageMarkedDone = false;
      });
    }

    if (currentSentence != null) {}

    await Future.delayed(const Duration(milliseconds: 350));

    _loadTooltipsForCurrentSentence();
    ref.read(statsProvider.notifier).loadStats();
  }

  Future<void> _goPrevious() async {
    setState(() {
      _isNavigatingForward = false;
    });
    await ref.read(sentenceReaderProvider.notifier).previousSentence();
    _saveSentencePosition();

    final currentSentence = ref.read(sentenceReaderProvider).currentSentence;
    if (currentSentence != null) {}

    await Future.delayed(const Duration(milliseconds: 350));

    _loadTooltipsForCurrentSentence();
    ref.read(statsProvider.notifier).loadStats();
  }

  void _saveSentencePosition() {
    final currentIndex = ref.read(sentenceReaderProvider).currentSentenceIndex;
    ref
        .read(settingsProvider.notifier)
        .updateCurrentBookSentenceIndex(currentIndex);
  }

  Future<void> _markLastPageDone() async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    try {
      await ref
          .read(readerProvider.notifier)
          .markPageRead(pageData.bookId, pageData.currentPage);

      if (mounted) {
        setState(() {
          _isLastPageMarkedDone = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page marked as done'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      ref.read(statsProvider.notifier).loadStats();
    } catch (e) {
      print('Error marking page as done: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark page as done: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleTap(TextItem item, BuildContext context) async {
    if (item.isSpace) return;
    TermTooltipClass.close();

    try {
      if (item.wordId == null) return;

      final renderBox = context.findRenderObject() as RenderBox;
      final termRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

      final termTooltip = await ref
          .read(readerProvider.notifier)
          .fetchTermTooltip(item.wordId!);
      if (termTooltip != null && termTooltip.hasData && mounted) {
        TermTooltipClass.show(context, termTooltip, termRect);
      }
    } catch (e) {
      return;
    }
  }

  void _handleDoubleTap(TextItem item) async {
    TermTooltipClass.close();

    if (item.wordId == null) return;
    if (item.langId == null) return;

    try {
      final termForm = await ref
          .read(readerProvider.notifier)
          .fetchTermFormById(item.wordId!);
      if (termForm != null && mounted) {
        _showTermForm(termForm, sentence: _extractSentence(item));
      }
    } catch (e) {
      return;
    }
  }

  void _handleLongPress(TextItem item) {
    if (item.wordId == null) return;
    if (item.langId == null) return;

    final sentence = _extractSentence(item);
    if (sentence.isNotEmpty) {
      _showSentenceTranslation(sentence, item.langId!);
    }
  }

  String _extractSentence(TextItem item) {
    final sentenceReader = ref.read(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    if (currentSentence == null) return '';

    return currentSentence.textItems.map((i) => i.text).join();
  }

  void _showTermForm(TermForm termForm, {String? sentence}) {
    _currentTermForm = termForm;
    _isDictionaryOpen = false;
    bool _shouldAutoSaveOnClose = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Keep sheet backgrounds transparent so child widgets render card styling.
      backgroundColor: const Color(0x00000000),
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: PopScope(
            canPop: !_isDictionaryOpen,
            onPopInvoked: (didPop) async {
              if (didPop) {
                if (settings.autoSave && _shouldAutoSaveOnClose) {
                  final updatedForm = _currentTermForm ?? termForm;
                  final success = await ref
                      .read(readerProvider.notifier)
                      .saveTerm(updatedForm);
                  if (success && mounted && updatedForm.termId != null) {
                    _termTooltips.remove(updatedForm.termId!);

                    try {
                      final freshTooltip = await ref
                          .read(readerProvider.notifier)
                          .fetchTermTooltip(updatedForm.termId!);
                      if (freshTooltip != null && mounted) {
                        setState(() {
                          _termTooltips[updatedForm.termId!] = freshTooltip;
                        });

                        await Future.delayed(const Duration(milliseconds: 100));
                        await _refreshAffectedTermTooltips(freshTooltip);
                      }
                    } catch (e) {}
                  } else if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save term')),
                    );
                  }
                }
              }
            },
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return GestureDetector(
                  onVerticalDragStart: _isDictionaryOpen ? (_) {} : null,
                  onVerticalDragUpdate: _isDictionaryOpen ? (_) {} : null,
                  onVerticalDragEnd: _isDictionaryOpen
                      ? (_) {}
                      : (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 500) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: TermFormWidget(
                    termForm: _currentTermForm ?? termForm,
                    sentence: sentence,
                    contentService: repository.contentService,
                    dictionaryService: DictionaryService(
                      fetchLanguageSettingsHtml: (langId) => repository
                          .contentService
                          .getLanguageSettingsHtml(langId),
                    ),
                    onUpdate: (updatedForm) {
                      setState(() {
                        _currentTermForm = updatedForm;
                      });
                      setModalState(() {});
                    },
                    onSave: (updatedForm) async {
                      final success = await ref
                          .read(readerProvider.notifier)
                          .saveTerm(updatedForm);
                      if (success && mounted) {
                        if (updatedForm.termId != null) {
                          _termTooltips.remove(updatedForm.termId!);

                          try {
                            final freshTooltip = await ref
                                .read(readerProvider.notifier)
                                .fetchTermTooltip(updatedForm.termId!);
                            if (freshTooltip != null && mounted) {
                              setState(() {
                                _termTooltips[updatedForm.termId!] =
                                    freshTooltip;
                              });

                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              await _refreshAffectedTermTooltips(freshTooltip);
                            }
                          } catch (e) {}
                        }

                        Navigator.of(context).pop();
                      }
                    },
                    onCancel: () {
                      _shouldAutoSaveOnClose = false;
                      Navigator.of(context).pop();
                    },
                    onDictionaryToggle: (isOpen) {
                      setState(() {
                        _isDictionaryOpen = isOpen;
                      });
                      setModalState(() {});
                    },
                    onParentDoubleTap: (parent) async {
                      if (parent.id != null) {
                        final parentTermForm = await ref
                            .read(readerProvider.notifier)
                            .fetchTermFormById(parent.id!);
                        if (parentTermForm != null && mounted) {
                          _showParentTermForm(
                            parentTermForm,
                            sentence: sentence,
                            onParentUpdated: (updatedParent) {
                              setState(() {
                                _currentTermForm = _currentTermForm?.copyWith(
                                  parents: (_currentTermForm?.parents ?? [])
                                      .map(
                                        (existingParent) =>
                                            existingParent.id ==
                                                updatedParent.id
                                            ? updatedParent
                                            : existingParent,
                                      )
                                      .toList(),
                                );
                              });
                            },
                          );
                        }
                      }
                    },
                    onStatus99Changed: (langId) async {
                      if (ref.read(settingsProvider).showStatsBar) {
                        await ref
                            .read(termsProvider.notifier)
                            .loadStats(langId);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showParentTermForm(
    TermForm termForm, {
    String? sentence,
    void Function(TermParent)? onParentUpdated,
  }) {
    _isDictionaryOpen = false;
    bool _shouldAutoSaveOnClose = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: PopScope(
            canPop: !_isDictionaryOpen,
            onPopInvoked: (didPop) async {
              if (didPop && settings.autoSave && _shouldAutoSaveOnClose) {
                final updatedForm = termForm;
                final success = await ref
                    .read(readerProvider.notifier)
                    .saveTerm(updatedForm);
                if (success && mounted) {
                  if (updatedForm.termId != null) {
                    _termTooltips.remove(updatedForm.termId!);

                    try {
                      final freshTooltip = await ref
                          .read(readerProvider.notifier)
                          .fetchTermTooltip(updatedForm.termId!);
                      if (freshTooltip != null && mounted) {
                        setState(() {
                          _termTooltips[updatedForm.termId!] = freshTooltip;
                        });

                        await Future.delayed(const Duration(milliseconds: 100));
                        await _refreshAffectedTermTooltips(freshTooltip);
                      }
                    } catch (e) {}
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save term')),
                  );
                }
              }
            },
            child: StatefulBuilder(
              builder: (context, setModalState) {
                var currentForm = termForm;
                return GestureDetector(
                  onVerticalDragStart: _isDictionaryOpen ? (_) {} : null,
                  onVerticalDragUpdate: _isDictionaryOpen ? (_) {} : null,
                  onVerticalDragEnd: _isDictionaryOpen
                      ? (_) {}
                      : (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 500) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: TermFormWidget(
                    termForm: currentForm,
                    sentence: sentence,
                    contentService: repository.contentService,
                    dictionaryService: DictionaryService(
                      fetchLanguageSettingsHtml: (langId) => repository
                          .contentService
                          .getLanguageSettingsHtml(langId),
                    ),
                    onUpdate: (updatedForm) {
                      currentForm = updatedForm;
                      setModalState(() {});
                    },
                    onSave: (updatedForm) async {
                      final success = await ref
                          .read(readerProvider.notifier)
                          .saveTerm(updatedForm);
                      if (success && mounted) {
                        if (updatedForm.termId != null) {
                          setState(() {
                            final existingTooltip =
                                _termTooltips[updatedForm.termId!];
                            if (existingTooltip != null) {
                              _termTooltips[updatedForm.termId!] = TermTooltip(
                                term: existingTooltip.term,
                                translation: updatedForm.translation,
                                termId: existingTooltip.termId,
                                status: existingTooltip.status,
                                statusText: existingTooltip.statusText,
                                sentences: existingTooltip.sentences,
                                language: existingTooltip.language,
                                languageId: existingTooltip.languageId,
                                parents: existingTooltip.parents,
                                children: existingTooltip.children,
                              );
                            }
                          });

                          try {
                            final freshTooltip = await ref
                                .read(readerProvider.notifier)
                                .fetchTermTooltip(updatedForm.termId!);
                            if (freshTooltip != null && mounted) {
                              setState(() {
                                _termTooltips[updatedForm.termId!] =
                                    freshTooltip;
                              });

                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              await _refreshAffectedTermTooltips(freshTooltip);
                            }
                          } catch (e) {}
                        }

                        onParentUpdated?.call(
                          TermParent(
                            id: updatedForm.termId,
                            term: updatedForm.term,
                            translation: updatedForm.translation,
                            status: int.tryParse(updatedForm.status),
                            syncStatus: updatedForm.syncStatus,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    onCancel: () {
                      _shouldAutoSaveOnClose = false;
                      Navigator.of(context).pop();
                    },
                    onDictionaryToggle: (isOpen) {
                      setState(() {
                        _isDictionaryOpen = isOpen;
                      });
                      setModalState(() {});
                    },
                    onParentDoubleTap: (parent) async {
                      if (parent.id != null) {
                        final parentTermForm = await ref
                            .read(readerProvider.notifier)
                            .fetchTermFormById(parent.id!);
                        if (parentTermForm != null && mounted) {
                          _showParentTermForm(
                            parentTermForm,
                            sentence: sentence,
                            onParentUpdated: (updatedParent) {
                              currentForm = currentForm.copyWith(
                                parents: currentForm.parents
                                    .map(
                                      (existingParent) =>
                                          existingParent.id == updatedParent.id
                                          ? updatedParent
                                          : existingParent,
                                    )
                                    .toList(),
                              );
                              setModalState(() {});
                            },
                          );
                        }
                      }
                    },
                    onStatus99Changed: (langId) async {
                      if (ref.read(settingsProvider).showStatsBar) {
                        await ref
                            .read(termsProvider.notifier)
                            .loadStats(langId);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSentenceTranslation(String sentence, int languageId) {
    final repository = ref.read(readerRepositoryProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (context) {
        return SentenceTranslationWidget(
          sentence: sentence,
          translation: null,
          translationProvider: 'local',
          languageId: languageId,
          dictionaryService: DictionaryService(
            fetchLanguageSettingsHtml: (langId) =>
                repository.contentService.getLanguageSettingsHtml(langId),
          ),
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showAITranslation(String sentence, int languageId) {
    final currentBookState = ref.read(currentBookProvider);
    final language =
        currentBookState.languageName ??
        (_languageIdToName[languageId] ?? 'English');
    final sentenceReader = ref.read(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (context) {
        return SentenceAITranslationWidget(
          sentence: sentence,
          languageId: languageId,
          language: language,
          onClose: () => Navigator.of(context).pop(),
          sentenceId: currentSentence?.id,
        );
      },
    );
  }

  Future<void> flushCacheAndRebuild() async {
    _hasInitialized = false;
    _currentSentenceId = null;
    _settingsListenerSetup = false;
    _isParsing = false;
    _initializationFailed = false;
    _tooltipsLoadInProgress = false;
    _preloadInProgress = false;
    final reader = ref.read(readerProvider);
    if (reader.pageData == null) return;

    final bookId = reader.pageData!.bookId;
    final pageNum = reader.pageData!.currentPage;
    final langId = _getLangId(reader);

    await ref.read(sentenceCacheServiceProvider).clearBookCache(bookId);

    _termTooltips.clear();
    _lastTooltipsBookId = null;

    await ref
        .read(readerProvider.notifier)
        .loadPage(bookId: bookId, pageNum: pageNum, updateReaderState: true);

    final freshReader = ref.read(readerProvider);
    if (freshReader.pageData != null) {
      await ref
          .read(sentenceReaderProvider.notifier)
          .parseSentencesForPage(langId, initialIndex: 0);
      await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();

      _currentSentenceId = null;
      _loadTooltipsForCurrentSentence();
    }
  }

  void _showSplitRatioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SplitRatioDialog(
        currentRatio: _splitRatio,
        onRatioChanged: (newRatio) async {
          final dictionaryService = ref.read(dictionaryServiceProvider);
          await dictionaryService.setSentenceReaderSplitRatio(newRatio);
          if (mounted) {
            setState(() {
              _splitRatio = newRatio;
            });
          }
        },
      ),
    );
  }
}

class _SplitRatioDialog extends StatefulWidget {
  final int currentRatio;
  final Future<void> Function(int) onRatioChanged;

  const _SplitRatioDialog({
    required this.currentRatio,
    required this.onRatioChanged,
  });

  @override
  State<_SplitRatioDialog> createState() => _SplitRatioDialogState();
}

class _SplitRatioDialogState extends State<_SplitRatioDialog> {
  late double _ratio;

  @override
  void initState() {
    super.initState();
    _ratio = widget.currentRatio.toDouble();
  }

  int get _topFlex => (10 - _ratio).round();
  int get _bottomFlex => _ratio.round();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Split Ratio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Top: $_topFlex / Bottom: $_bottomFlex'),
          Slider(
            value: _ratio,
            min: DictionaryService.minSplitRatio.toDouble(),
            max: DictionaryService.maxSplitRatio.toDouble(),
            divisions:
                DictionaryService.maxSplitRatio -
                DictionaryService.minSplitRatio,
            label: '$_topFlex / $_bottomFlex',
            onChanged: (value) {
              setState(() {
                _ratio = value;
              });
            },
            onChangeEnd: (value) {
              widget.onRatioChanged(value.round());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
