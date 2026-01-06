import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../providers/reader_provider.dart';
import '../providers/sentence_reader_provider.dart';
import '../providers/sentence_tts_provider.dart';
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
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/settings/providers/ai_settings_provider.dart';
import '../../../features/settings/models/ai_settings.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
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
  Key? _sentenceKey;
  bool _isNavigating = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      // App has resumed from background/sleep
      // Check if the server's current page matches the reader's page
      _checkServerPage();
    }
  }

  /// Checks if the server's current page matches the reader's page
  /// If they don't match, navigate to the server's page
  Future<void> _checkServerPage() async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData != null) {
      try {
        final serverPage = await ref
            .read(readerProvider.notifier)
            .getCurrentPageForBook(pageData.bookId);

        // If we got a valid page number from server and it's different from current page
        if (serverPage != -1 && serverPage != pageData.currentPage) {
          // Navigate to the server's page
          ref
              .read(readerProvider.notifier)
              .loadPage(
                bookId: pageData.bookId,
                pageNum: serverPage,
                showFullPageError:
                    false, // Don't show full page error for navigation
              );
        }
      } catch (e) {
        print('Error checking server page: $e');
        // Don't show error, just continue with current page
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ttsNotifier?.stop();
    super.dispose();
  }

  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
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
  Widget build(BuildContext context) {
    _mainBuildCount++;

    final currentScreenRoute = ref.watch(currentScreenRouteProvider);
    final isVisible = currentScreenRoute == 'sentence-reader';

    print(
      'DEBUG: SentenceReaderScreen build #$_mainBuildCount, isVisible=$isVisible, _hasInitialized=$_hasInitialized',
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
        _sentenceKey = ValueKey('sentence-$currentSentence.id');
      });
    }

    if (isVisible && readerState.pageData != null && !readerState.isLoading) {
      final bookId = readerState.pageData!.bookId;
      final pageNum = readerState.pageData!.currentPage;

      if (_lastInitializedBookId != bookId ||
          _lastInitializedPageNum != pageNum) {
        print(
          'DEBUG: Page changed from bookId=$_lastInitializedBookId, pageNum=$_lastInitializedPageNum to bookId=$bookId, pageNum=$pageNum - forcing reinitialization',
        );
        _hasInitialized = false;
        _lastInitializedBookId = bookId;
        _lastInitializedPageNum = pageNum;
        _initializationFailed = false;
      }

      if (!_hasInitialized) {
        final langId = _getLangId(readerState);
        print(
          'DEBUG: SentenceReaderScreen: Initializing sentence parsing for bookId=$bookId, pageNum=$pageNum, langId=$langId',
        );

        if (_lastTooltipsBookId != bookId) {
          _termTooltips.clear();
          _lastTooltipsBookId = bookId;
        }

        if (_isParsing) {
          print('DEBUG: Already parsing, skipping duplicate call');
        } else {
          final sentenceReader = ref.read(sentenceReaderProvider);
          final reader = ref.read(readerProvider);

          if (sentenceReader.lastParsedBookId == bookId &&
              sentenceReader.lastParsedPageNum == pageNum &&
              sentenceReader.customSentences.isNotEmpty) {
            print(
              'DEBUG: Sentences already loaded for this page, skipping initialization',
            );
            _hasInitialized = true;
            _initializationFailed = false;
            _loadTooltipsForCurrentSentence();
          } else {
            print(
              'DEBUG: reader.languageSentenceSettings=${reader.languageSentenceSettings != null}, langId=$langId',
            );
            _isParsing = true;
            Future(() {
              ref
                  .read(sentenceReaderProvider.notifier)
                  .parseSentencesForPage(langId, initialIndex: 0)
                  .then((_) {
                    if (mounted) {
                      _isParsing = false;
                      final sentenceReader = ref.read(sentenceReaderProvider);
                      print(
                        'DEBUG: Sentences loaded: ${sentenceReader.customSentences.length}',
                      );
                      if (sentenceReader.customSentences.isNotEmpty) {
                        _hasInitialized = true;
                        _initializationFailed = false;
                        print(
                          'DEBUG: Initialization successful, _hasInitialized=$_hasInitialized',
                        );
                      } else {
                        _hasInitialized = false;
                        _initializationFailed = true;
                        print(
                          'DEBUG: Initialization failed - no sentences loaded',
                        );
                      }
                      ref
                          .read(sentenceReaderProvider.notifier)
                          .loadSavedPosition();
                      _loadTooltipsForCurrentSentence();
                    }
                  })
                  .catchError((e, stackTrace) {
                    print('DEBUG: Error during parsing: $e');
                    print('DEBUG: Stack trace: $stackTrace');
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
      print('DEBUG: About to setup settings listener');
      _setupSettingsListener();
    }

    if (isVisible && _initializationFailed && !_isParsing) {
      print('DEBUG: Retrying failed initialization...');
      _hasInitialized = false;
      _initializationFailed = false;
    }

    if (isVisible &&
        _hasInitialized &&
        currentSentence != null &&
        currentSentence.id != _currentSentenceId) {
      print(
        'DEBUG: Build method detected sentence change: ${_currentSentenceId} -> ${currentSentence.id}',
      );
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
              onPressed: () => ref.read(navigationProvider).navigateToScreen(0),
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
              onPressed: () => ref.read(navigationProvider).navigateToScreen(0),
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
              onPressed: () => ref.read(navigationProvider).navigateToScreen(0),
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
                    ref.read(navigationProvider).navigateToScreen(1),
                icon: const Icon(Icons.collections_bookmark),
                label: const Text('Browse Books'),
              ),
            ],
          ),
        ),
      );
    }

    final textSettings = ref.watch(textFormattingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (widget.scaffoldKey != null &&
                  widget.scaffoldKey!.currentState != null) {
                widget.scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        title: Text(pageTitle ?? 'Sentence Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref.read(navigationProvider).navigateToScreen(0),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _PageTransition(
        isForward: _isNavigatingForward,
        child: Column(
          key: ValueKey('column-${currentSentence?.id ?? "null"}'),
          children: [
            Expanded(
              flex: 3,
              child: _buildTopSection(textSettings, currentSentence),
            ),
            Expanded(flex: 7, child: _buildBottomSection(currentSentence)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildTopSection(
    dynamic textSettings,
    CustomSentence? currentSentence,
  ) {
    _topSectionBuildCount++;

    if (currentSentence == null) {
      return const Center(child: Text('No sentence available'));
    }

    return GestureDetector(
      onTapDown: (_) => TermTooltipClass.close(),
      onHorizontalDragEnd: (details) async {
        final velocity = details.primaryVelocity ?? 0;
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
              try {
                await ref
                    .read(readerProvider.notifier)
                    .markPageRead(
                      reader.pageData!.bookId,
                      reader.pageData!.currentPage,
                    );
              } catch (e) {
                print('Error marking page as read: $e');
              }
            }

            await Future.delayed(const Duration(milliseconds: 400));
            await _goNext();
          }
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SentenceReaderDisplay(
            sentence: currentSentence,
            onTap: (item, position) => _handleTap(item, position),
            onDoubleTap: (item) => _handleDoubleTap(item),
            onLongPress: (item) => _handleLongPress(item),
            textSize: textSettings.textSize,
            lineSpacing: textSettings.lineSpacing,
            fontFamily: textSettings.fontFamily,
            fontWeight: textSettings.fontWeight,
            isItalic: textSettings.isItalic,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(CustomSentence? currentSentence) {
    _bottomSectionBuildCount++;

    final settings = ref.watch(settingsProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) async {
        final velocity = details.primaryVelocity ?? 0;
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
              try {
                await ref
                    .read(readerProvider.notifier)
                    .markPageRead(
                      reader.pageData!.bookId,
                      reader.pageData!.currentPage,
                    );
              } catch (e) {
                print('Error marking page as read: $e');
              }
            }

            await Future.delayed(const Duration(milliseconds: 400));
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
                const Spacer(),
                if (currentSentence != null) ...[
                  SentenceAITranslationButton(
                    text: currentSentence!.textItems
                        .map((item) => item.text)
                        .join(),
                    sentenceId: currentSentence!.id,
                    languageId: currentSentence!.textItems.first.langId ?? 0,
                    language: 'English',
                    onTranslationRequested: () => _showAITranslation(
                      currentSentence!.textItems
                          .map((item) => item.text)
                          .join(),
                      currentSentence!.textItems.first.langId ?? 0,
                    ),
                  ),
                  SentenceTTSButton(
                    text: currentSentence!.textItems
                        .map((item) => item.text)
                        .join(),
                    sentenceId: currentSentence!.id,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TermListDisplay(
              sentence: currentSentence,
              tooltips: _termTooltips,
              onTermTap: (item, position) => _handleTap(item, position),
              onTermDoubleTap: (item) => _handleDoubleTap(item),
              showKnownTerms: settings.showKnownTermsInSentenceReader,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar() {
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

  void _setupSettingsListener() {
    if (_settingsListenerSetup) return;
    _settingsListenerSetup = true;

    ref.listen<bool>(
      settingsProvider.select((s) => s.showKnownTermsInSentenceReader),
      (previous, next) {
        if (previous != next) {
          print('DEBUG: Show known terms toggle changed: $previous -> $next');
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

    print('DEBUG: Loading tooltips for sentence ID: ${currentSentence.id}');
    print(
      'DEBUG: Terms needing tooltips: ${termsNeedingTooltips.length} (out of ${currentSentence.uniqueTerms.length} total)',
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
        print('DEBUG: All tooltips already cached');
        _tooltipsLoadInProgress = false;
        if (_canPreload()) {
          _preloadNextSentence();
        }
        return;
      }

      print(
        'DEBUG: Concurrently fetching ${termsToFetch.length} tooltips for sentence ID: ${currentSentence.id}',
      );

      final futures = termsToFetch.map((term) async {
        if (term.wordId == null) return null;
        try {
          final termTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(term.wordId!);
          return termTooltip;
        } catch (e) {
          print('DEBUG: Failed to fetch tooltip for wordId=${term.wordId}: $e');
          return null;
        }
      }).toList();

      final results = await Future.wait(futures, eagerError: false);

      final Map<int, TermTooltip> newTooltips = {};
      for (int i = 0; i < results.length; i++) {
        final tooltip = results[i];
        final wordId = termsToFetch[i].wordId;
        if (tooltip != null && wordId != null && tooltip.hasData) {
          newTooltips[wordId!] = tooltip;
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
      print('DEBUG: Preload already in progress, skipping');
      return;
    }

    final sentenceReaderState = ref.read(sentenceReaderProvider);
    final sentenceReaderNotifier = ref.read(sentenceReaderProvider.notifier);
    final settings = ref.read(settingsProvider);

    if (!sentenceReaderNotifier.canGoNext) {
      print('DEBUG: No next sentence to preload');
      return;
    }

    final nextIndex = sentenceReaderState.currentSentenceIndex + 1;
    if (nextIndex >= sentenceReaderState.customSentences.length) {
      print('DEBUG: Next index out of bounds');
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
      print('DEBUG: All next sentence tooltips already cached');
      return;
    }

    if (!_canPreload()) {
      print('DEBUG: Stopping preload - not visible');
      return;
    }

    _preloadInProgress = true;

    try {
      print('DEBUG: Concurrently preloading ${termsToFetch.length} tooltips');

      final futures = termsToFetch.map((term) async {
        if (term.wordId == null) return null;
        try {
          if (!_canPreload()) {
            print('DEBUG: Canceling preload - not visible');
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
          newTooltips[wordId!] = tooltip;
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

      print('DEBUG: Finished preloading next sentence');
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
    print('DEBUG: _goNext called');
    setState(() {
      _isNavigatingForward = true;
      _isNavigating = true;
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

    if (currentSentence != null) {
      final newKey = ValueKey('sentence-${currentSentence.id}');
      print('DEBUG: Updating _sentenceKey from $_sentenceKey to $newKey');
      setState(() {
        _sentenceKey = newKey;
      });
    }

    await Future.delayed(const Duration(milliseconds: 350));
    setState(() {
      _isNavigating = false;
    });
  }

  Future<void> _goPrevious() async {
    print('DEBUG: _goPrevious called');
    setState(() {
      _isNavigatingForward = false;
      _isNavigating = true;
    });
    await ref.read(sentenceReaderProvider.notifier).previousSentence();
    _saveSentencePosition();

    final currentSentence = ref.read(sentenceReaderProvider).currentSentence;
    if (currentSentence != null) {
      final newKey = ValueKey('sentence-${currentSentence.id}');
      print('DEBUG: Updating _sentenceKey from $_sentenceKey to $newKey');
      setState(() {
        _sentenceKey = newKey;
      });
    }

    await Future.delayed(const Duration(milliseconds: 350));
    setState(() {
      _isNavigating = false;
    });
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

  void _handleTap(TextItem item, Offset position) async {
    if (item.isSpace) return;
    TermTooltipClass.close();

    try {
      if (item.wordId == null) return;

      final termTooltip = await ref
          .read(readerProvider.notifier)
          .fetchTermTooltip(item.wordId!);
      if (termTooltip != null && termTooltip.hasData && mounted) {
        TermTooltipClass.show(context, termTooltip, position);
      }
    } catch (e) {
      return;
    }
  }

  void _handleDoubleTap(TextItem item) async {
    if (item.wordId == null) return;
    if (item.langId == null) return;

    try {
      final termForm = await ref
          .read(readerProvider.notifier)
          .fetchTermFormById(item.wordId!);
      if (termForm != null && mounted) {
        _showTermForm(termForm);
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

  void _showTermForm(TermForm termForm) {
    _currentTermForm = termForm;
    _isDictionaryOpen = false;
    bool _shouldAutoSaveOnClose = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                final updatedForm = _currentTermForm ?? termForm;
                final success = await ref
                    .read(readerProvider.notifier)
                    .saveTerm(updatedForm);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save term')),
                  );
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
                          _showParentTermForm(parentTermForm);
                        }
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

  void _showParentTermForm(TermForm termForm) {
    _isDictionaryOpen = false;
    bool _shouldAutoSaveOnClose = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                final updatedForm = _currentTermForm ?? termForm;
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
                TermForm? currentForm = termForm;
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
                    contentService: repository.contentService,
                    dictionaryService: DictionaryService(
                      fetchLanguageSettingsHtml: (langId) => repository
                          .contentService
                          .getLanguageSettingsHtml(langId),
                    ),
                    onUpdate: (updatedForm) {
                      setState(() {
                        currentForm = updatedForm;
                      });
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
                          _showParentTermForm(parentTermForm);
                        }
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
      backgroundColor: Colors.transparent,
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
    final aiSettings = ref.read(aiSettingsProvider);
    final language =
        aiSettings.promptConfigs[AIPromptType.sentenceTranslation]?.language ??
        'English';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SentenceAITranslationWidget(
          sentence: sentence,
          languageId: languageId,
          language: language,
          onClose: () => Navigator.of(context).pop(),
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

    print(
      'DEBUG SentenceReaderScreen.flushCacheAndRebuild: Clearing cache for bookId=$bookId',
    );
    await ref.read(sentenceCacheServiceProvider).clearBookCache(bookId);

    _termTooltips.clear();
    _lastTooltipsBookId = null;

    print(
      'DEBUG SentenceReaderScreen.flushCacheAndRebuild: Reloading page bookId=$bookId, pageNum=$pageNum',
    );
    await ref
        .read(readerProvider.notifier)
        .loadPage(bookId: bookId, pageNum: pageNum, updateReaderState: true);

    final freshReader = ref.read(readerProvider);
    if (freshReader.pageData != null) {
      print(
        'DEBUG SentenceReaderScreen.flushCacheAndRebuild: Parsing sentences for langId=$langId',
      );
      await ref
          .read(sentenceReaderProvider.notifier)
          .parseSentencesForPage(langId, initialIndex: 0);
      await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();

      _currentSentenceId = null;
      _loadTooltipsForCurrentSentence();
    }
  }
}
