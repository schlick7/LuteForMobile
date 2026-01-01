import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../providers/reader_provider.dart';
import '../providers/sentence_reader_provider.dart';
import '../widgets/term_tooltip.dart';
import '../widgets/term_form.dart';
import '../widgets/sentence_translation.dart';
import '../widgets/sentence_reader_display.dart';
import '../widgets/term_list_display.dart';
import '../utils/sentence_parser.dart';
import '../../../core/network/dictionary_service.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../app.dart';

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
  int _mainBuildCount = 0;
  int _topSectionBuildCount = 0;
  int _bottomSectionBuildCount = 0;

  int? _lastInitializedBookId;
  int? _lastInitializedPageNum;
  int? _lastTooltipsBookId;
  bool _hasInitialized = false;
  int? _currentSentenceId;
  AppLifecycleState? _lastLifecycleState;
  bool _sentenceNavigationListenerSetup = false;
  bool _settingsListenerSetup = false;
  bool _isParsing = false;
  bool _initializationFailed = false;

  @override
  void initState() {
    super.initState();
    _setupAppLifecycleListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lastLifecycleState = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    final pageTitle = ref.watch(
      readerProvider.select((state) => state.pageData?.title),
    );
    final readerState = ref.read(readerProvider);
    final sentenceReader = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    if (isVisible &&
        readerState.pageData != null &&
        !_hasInitialized &&
        !readerState.isLoading) {
      final bookId = readerState.pageData!.bookId;
      final pageNum = readerState.pageData!.currentPage;

      if (_lastInitializedBookId != bookId ||
          _lastInitializedPageNum != pageNum) {
        _lastInitializedBookId = bookId;
        _lastInitializedPageNum = pageNum;
        _initializationFailed = false;

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
          final reader = ref.read(readerProvider);
          print(
            'DEBUG: reader.languageSentenceSettings=${reader.languageSentenceSettings != null}, langId=$langId',
          );
          _isParsing = true;
          Future(() {
            ref
                .read(sentenceReaderProvider.notifier)
                .parseSentencesForPage(langId)
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
                      print('DEBUG: Initialization successful');
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

    if (isVisible && _hasInitialized && !_sentenceNavigationListenerSetup) {
      _setupSentenceNavigationListener();
    }

    if (isVisible && _hasInitialized && !_settingsListenerSetup) {
      _setupSettingsListener();
    }

    if (isVisible && _initializationFailed && !_isParsing) {
      print('DEBUG: Retrying failed initialization...');
      _hasInitialized = false;
      _initializationFailed = false;
    }

    if (isVisible && _hasInitialized && !_sentenceNavigationListenerSetup) {
      _setupSentenceNavigationListener();
    }

    if (isVisible && _hasInitialized && !_settingsListenerSetup) {
      _setupSettingsListener();
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

      if (prevPage == null &&
          nextPage != null &&
          _lastInitializedBookId != nextPage.bookId &&
          isVisible) {
        final bookId = nextPage.bookId;
        final pageNum = nextPage.currentPage;

        if (_lastInitializedBookId != bookId ||
            _lastInitializedPageNum != pageNum) {
          _lastInitializedBookId = bookId;
          _lastInitializedPageNum = pageNum;
          _initializationFailed = false;

          final langId = _getLangId(next);
          print(
            'DEBUG: SentenceReaderScreen: Delayed initialization for bookId=$bookId, pageNum=$pageNum, langId=$langId',
          );

          if (_lastTooltipsBookId != bookId) {
            _termTooltips.clear();
            _lastTooltipsBookId = bookId;
          }

          if (_isParsing) {
            print('DEBUG: Already parsing, skipping duplicate call');
          } else {
            _isParsing = true;
            Future(() {
              ref
                  .read(sentenceReaderProvider.notifier)
                  .parseSentencesForPage(langId)
                  .then((_) {
                    if (mounted) {
                      _isParsing = false;
                      final sentenceReader = ref.read(sentenceReaderProvider);
                      if (sentenceReader.customSentences.isNotEmpty) {
                        _hasInitialized = true;
                        _initializationFailed = false;
                        print('DEBUG: Initialization successful');
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
                    print('DEBUG: Error during delayed parsing: $e');
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
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildTopSection(textSettings, currentSentence),
          ),
          Expanded(flex: 7, child: _buildBottomSection(currentSentence)),
        ],
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
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => TermTooltipClass.close(),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Terms', style: Theme.of(context).textTheme.titleLarge),
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
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              ref.watch(sentenceReaderProvider).sentencePosition,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: ref.watch(sentenceReaderProvider).canGoPrevious
                  ? () => _goPrevious()
                  : null,
              iconSize: 24,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: ref.watch(sentenceReaderProvider).canGoNext
                  ? () => _goNext()
                  : null,
              iconSize: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _setupSentenceNavigationListener() {
    if (_sentenceNavigationListenerSetup) return;
    _sentenceNavigationListenerSetup = true;

    ref.listen<SentenceReaderState>(sentenceReaderProvider, (previous, next) {
      final newSentenceId = next.currentSentence?.id;
      if (newSentenceId != null && newSentenceId != _currentSentenceId) {
        _currentSentenceId = newSentenceId;
        print('DEBUG: Sentence changed to ID: $_currentSentenceId');
        _loadTooltipsForCurrentSentence();
      }
    });
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
      final Map<int, TermTooltip> newTooltips = {};
      for (final term in termsNeedingTooltips) {
        if (term.wordId != null && !_termTooltips.containsKey(term.wordId!)) {
          print(
            'DEBUG: Fetching tooltip for wordId=${term.wordId}, term="${term.text}"',
          );
          try {
            final termTooltip = await ref
                .read(readerProvider.notifier)
                .fetchTermTooltip(term.wordId!);
            if (termTooltip != null) {
              newTooltips[term.wordId!] = termTooltip;
            }
          } catch (e) {
            print(
              'DEBUG: Failed to fetch tooltip for wordId=${term.wordId}: $e',
            );
          }
        }
      }
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
    final sentenceReader = ref.read(sentenceReaderProvider);
    final settings = ref.read(settingsProvider);

    if (!sentenceReader.canGoNext) {
      print('DEBUG: No next sentence to preload');
      return;
    }

    final nextIndex = sentenceReader.currentSentenceIndex + 1;
    if (nextIndex >= sentenceReader.customSentences.length) {
      print('DEBUG: Next index out of bounds');
      return;
    }

    final nextSentence = sentenceReader.customSentences[nextIndex];

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

    final Map<int, TermTooltip> newTooltips = {};
    for (final term in termsNeedingTooltips) {
      if (term.wordId != null && !_termTooltips.containsKey(term.wordId!)) {
        if (!_canPreload()) {
          print('DEBUG: Stopping preload - not visible');
          return;
        }

        try {
          final termTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(term.wordId!);
          if (termTooltip != null) {
            newTooltips[term.wordId!] = termTooltip;
          }
        } catch (e) {
          print(
            'DEBUG: Failed to preload tooltip for wordId=${term.wordId}: $e',
          );
        }
      }
    }

    if (mounted && _canPreload() && newTooltips.isNotEmpty) {
      setState(() {
        _termTooltips.addAll(newTooltips);
      });
    }

    print('DEBUG: Finished preloading next sentence');
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
    await ref.read(sentenceReaderProvider.notifier).nextSentence();
    _saveSentencePosition();
  }

  Future<void> _goPrevious() async {
    await ref.read(sentenceReaderProvider.notifier).previousSentence();
    _saveSentencePosition();
  }

  void _saveSentencePosition() {
    final currentIndex = ref.read(sentenceReaderProvider).currentSentenceIndex;
    ref
        .read(settingsProvider.notifier)
        .updateCurrentBookSentenceIndex(currentIndex);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) async {
            if (didPop && settings.autoSave) {
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
              return TermFormWidget(
                termForm: _currentTermForm ?? termForm,
                contentService: repository.contentService,
                dictionaryService: DictionaryService(
                  fetchLanguageSettingsHtml: (langId) =>
                      repository.contentService.getLanguageSettingsHtml(langId),
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
                            _termTooltips[updatedForm.termId!] = freshTooltip;
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
                onCancel: () => Navigator.of(context).pop(),
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
              );
            },
          ),
        );
      },
    );
  }

  void _showParentTermForm(TermForm termForm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) async {
            if (didPop && settings.autoSave) {
              final updatedForm = termForm;
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
              TermForm? currentForm = termForm;
              return TermFormWidget(
                termForm: currentForm,
                contentService: repository.contentService,
                dictionaryService: DictionaryService(
                  fetchLanguageSettingsHtml: (langId) =>
                      repository.contentService.getLanguageSettingsHtml(langId),
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
                            _termTooltips[updatedForm.termId!] = freshTooltip;
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
                onCancel: () => Navigator.of(context).pop(),
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
              );
            },
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

  Future<void> flushCacheAndRebuild() async {
    _hasInitialized = false;
    _currentSentenceId = null;
    _sentenceNavigationListenerSetup = false;
    _settingsListenerSetup = false;
    _isParsing = false;
    _initializationFailed = false;
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
          .parseSentencesForPage(langId);
      await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();

      _currentSentenceId = null;
      _loadTooltipsForCurrentSentence();
    }
  }
}
