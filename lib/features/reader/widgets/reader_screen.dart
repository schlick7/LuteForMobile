import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../models/page_data.dart';
import '../providers/reader_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/term_tooltip.dart';
import '../models/sentence_translation.dart';
import 'text_display.dart';
import 'term_form.dart';
import 'sentence_translation.dart';
import '../../../core/network/dictionary_service.dart';
import 'audio_player.dart';
import 'package:lute_for_mobile/app.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ReaderScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  double _tempTextSize = 18.0;
  double _tempLineSpacing = 1.5;
  String? _tempFont;
  double _tempFontWeight = 2.0;
  bool? _tempIsItalic;
  TermForm? _currentTermForm;
  int _buildCount = 0;
  bool _isDictionaryOpen = false;
  AppLifecycleState? _lastLifecycleState;
  bool _hasInitialized = false;
  bool _isUiVisible = true;
  Timer? _hideUiTimer;
  ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0.0;
  DateTime? _lastMarkPageTime;
  final List<String> _availableFonts = [
    'Roboto',
    'AtkinsonHyperlegibleNext',
    'Vollkorn',
    'LinBiolinum',
    'Literata',
  ];
  final List<FontWeight> _availableWeights = [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.normal,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.bold,
    FontWeight.w800,
  ];
  final List<String> _weightLabels = [
    'Extra Light',
    'Light',
    'Regular',
    'Medium',
    'Semi Bold',
    'Bold',
    'Extra Bold',
  ];

  FontWeight _getWeightFromIndex(double index) {
    final idx = index.round().clamp(0, _availableWeights.length - 1);
    return _availableWeights[idx];
  }

  String _getWeightLabel(double index) {
    final idx = index.round().clamp(0, _weightLabels.length - 1);
    return _weightLabels[idx];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasInitialized = true;
    _scrollController.addListener(_handleScrollPosition);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideUiTimer?.cancel();
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

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

  void _handleScrollPosition() {
    final textSettings = ref.read(textFormattingSettingsProvider);

    if (!textSettings.fullscreenMode) {
      _cancelHideTimer();
      _lastScrollPosition = _scrollController.offset;
      return;
    }

    final scrollPosition = _scrollController.offset;
    const topThreshold = 70.0;

    if (scrollPosition < topThreshold && scrollPosition < _lastScrollPosition) {
      if (!_isUiVisible) {
        _showUi();
      }
      _resetHideTimer();
    }

    _lastScrollPosition = scrollPosition;
  }

  void _showUi() {
    setState(() {
      _isUiVisible = true;
    });
    _startHideTimer();
  }

  void _hideUi() {
    setState(() {
      _isUiVisible = false;
    });
    _cancelHideTimer();
  }

  void _startHideTimer() {
    _hideUiTimer?.cancel();
    _hideUiTimer = Timer(const Duration(seconds: 2), _hideUi);
  }

  void _resetHideTimer() {
    _cancelHideTimer();
    _startHideTimer();
  }

  void _cancelHideTimer() {
    _hideUiTimer?.cancel();
    _hideUiTimer = null;
  }

  void _loadAudioIfNeeded() async {
    final pageData = ref.read(readerProvider).pageData;
    final settings = ref.read(settingsProvider);

    if (pageData == null || !settings.showAudioPlayer) return;

    if (pageData.hasAudio) {
      final audioUrl =
          '${settings.serverUrl}/useraudio/stream/${pageData.bookId}';
      await ref
          .read(audioPlayerProvider.notifier)
          .loadAudio(
            audioUrl: audioUrl,
            bookId: pageData.bookId,
            page: pageData.currentPage,
            bookmarks: pageData.audioBookmarks,
            audioCurrentPos: pageData.audioCurrentPos,
          );
    }
  }

  Future<void> reloadPage() async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData != null) {
      await ref
          .read(readerProvider.notifier)
          .loadPage(bookId: pageData.bookId, pageNum: pageData.currentPage);
      _loadAudioIfNeeded();
    }
  }

  Future<void> loadBook(int bookId, [int? pageNum]) async {
    print('DEBUG: loadBook called with bookId=$bookId, pageNum=$pageNum');
    try {
      await ref
          .read(readerProvider.notifier)
          .loadPage(bookId: bookId, pageNum: pageNum);
      _loadAudioIfNeeded();
    } catch (e, stackTrace) {
      print('ERROR: loadBook failed: $e');
      print('Stack trace: $stackTrace');

      final settings = ref.read(settingsProvider);
      if (settings.currentBookId == bookId) {
        ref.read(settingsProvider.notifier).clearCurrentBook();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(readerProvider.select((s) => s.isLoading));
    final errorMessage = ref.watch(
      readerProvider.select((s) => s.errorMessage),
    );
    final pageData = ref.watch(readerProvider.select((s) => s.pageData));
    final textSettings = ref.watch(textFormattingSettingsProvider);
    final settings = ref.watch(settingsProvider);
    _buildCount++;
    if (_buildCount > 1) {
      print(
        'DEBUG: ReaderScreen rebuild #$_buildCount (isLoading=$isLoading, error=${errorMessage != null}, hasPageData=${pageData != null})',
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, pageData, textSettings.fullscreenMode),
      body: Stack(
        children: [
          Column(
            children: [
              if (settings.showAudioPlayer && pageData?.hasAudio == true)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    top: textSettings.fullscreenMode && !_isUiVisible
                        ? MediaQuery.of(context).padding.top + kToolbarHeight
                        : 0,
                  ),
                  child: AudioPlayerWidget(
                    audioUrl:
                        '${settings.serverUrl}/useraudio/stream/${pageData!.bookId}',
                    bookId: pageData!.bookId,
                    page: pageData!.currentPage,
                    bookmarks: pageData?.audioBookmarks,
                  ),
                ),
              Expanded(child: _buildBody(isLoading, errorMessage, pageData)),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PageData? pageData,
    bool fullscreenMode,
  ) {
    if (fullscreenMode) {
      final topPadding = MediaQuery.of(context).padding.top;
      return PreferredSize(
        preferredSize: Size.fromHeight(
          _isUiVisible ? kToolbarHeight + topPadding : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: _isUiVisible ? kToolbarHeight + topPadding : 0,
          child: AppBar(
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
            title: Text(pageData?.title ?? 'Reader'),
            actions: [
              if (pageData != null && pageData!.pageCount > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: pageData!.currentPage > 1
                            ? () => _goToPage(pageData!.currentPage - 1)
                            : null,
                        tooltip: 'Previous page',
                      ),
                      Text(pageData!.pageIndicator),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: pageData!.currentPage < pageData!.pageCount
                            ? () => _goToPage(pageData!.currentPage + 1)
                            : null,
                        tooltip: 'Next page',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return AppBar(
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
      title: Text(pageData?.title ?? 'Reader'),
      actions: [
        if (pageData != null && pageData!.pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: pageData!.currentPage > 1
                      ? () => _goToPage(pageData!.currentPage - 1)
                      : null,
                  tooltip: 'Previous page',
                ),
                Text(pageData!.pageIndicator),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: pageData!.currentPage < pageData!.pageCount
                      ? () => _goToPage(pageData!.currentPage + 1)
                      : null,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPageControls(BuildContext context, PageData pageData) {
    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markPageKnown(),
                tooltip: 'All Known',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pageData.currentPage > 1
                    ? () => _goToPage(pageData.currentPage - 1)
                    : null,
                tooltip: 'Previous page',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  pageData.pageIndicator,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pageData.currentPage < pageData.pageCount
                    ? () => _goToPage(pageData.currentPage + 1)
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isLoading, String? errorMessage, PageData? pageData) {
    if (isLoading) {
      return const LoadingIndicator(message: 'Loading content...');
    }

    if (errorMessage != null) {
      return ErrorDisplay(
        message: errorMessage,
        onRetry: pageData != null
            ? () {
                ref.read(readerProvider.notifier).clearError();
                ref
                    .read(readerProvider.notifier)
                    .loadPage(
                      bookId: pageData.bookId,
                      pageNum: pageData.currentPage,
                    );
              }
            : null,
      );
    }

    if (pageData == null) {
      final settings = ref.read(settingsProvider);

      if (!settings.isUrlValid) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Server Connection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please configure your Lute server in settings.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(navigationProvider).navigateToScreen(2),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Book Loaded',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a book from the books screen to start reading.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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

    return GestureDetector(
      onTapDown: (_) => TermTooltipClass.close(),
      onTap: () {
        if (textSettings.fullscreenMode && !_isUiVisible) {
          _showUi();
        }
      },
      onHorizontalDragEnd: (details) async {
        if (pageData!.pageCount <= 1) return;

        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          if (pageData!.currentPage > 1) {
            _goToPage(pageData!.currentPage - 1);
          }
        } else if (velocity < 0) {
          if (pageData!.currentPage < pageData!.pageCount) {
            final textSettings = ref.read(textFormattingSettingsProvider);

            if (textSettings.swipeMarksRead) {
              try {
                await ref
                    .read(readerProvider.notifier)
                    .markPageRead(pageData!.bookId, pageData!.currentPage);
              } catch (e) {
                print('Error marking page as read: $e');
              }
            }

            await Future.delayed(const Duration(milliseconds: 400));
            _goToPage(pageData!.currentPage + 1);
          }
        }
      },
      child: TextDisplay(
        paragraphs: pageData!.paragraphs,
        scrollController: _scrollController,
        topPadding: textSettings.fullscreenMode && !_isUiVisible
            ? MediaQuery.of(context).padding.top
            : 0.0,
        bottomControlWidget: pageData.pageCount > 1
            ? _buildPageControls(context, pageData)
            : null,
        onTap: (item, position) {
          _handleTap(item, position);
        },
        onDoubleTap: (item) {
          _handleDoubleTap(item);
        },
        onLongPress: (item) {
          _handleLongPress(item);
        },
        textSize: textSettings.textSize,
        lineSpacing: textSettings.lineSpacing,
        fontFamily: textSettings.fontFamily,
        fontWeight: textSettings.fontWeight,
        isItalic: textSettings.isItalic,
      ),
    );
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
    // Only handle double tap for terms from the server (items with wordId)
    if (item.wordId == null) return;
    if (item.langId == null) return;

    print(
      '_handleDoubleTap: text="${item.text}", wordId=${item.wordId}, langId=${item.langId}',
    );

    try {
      final termForm = await ref
          .read(readerProvider.notifier)
          .fetchTermFormById(item.wordId!);
      if (termForm != null && mounted) {
        print(
          'Got termForm: term="${termForm.term}", termId=${termForm.termId}',
        );
        _showTermForm(termForm);
      }
    } catch (e) {
      print('_handleDoubleTap error: $e');
      return;
    }
  }

  void _handleLongPress(TextItem item) {
    // Only handle long press for terms from the server (items with wordId)
    if (item.wordId == null) return;
    if (item.langId == null) return;

    final sentence = _extractSentence(item);
    if (sentence.isNotEmpty) {
      _showSentenceTranslation(sentence, item.langId!);
    }
  }

  String _extractSentence(TextItem item) {
    final state = ref.read(readerProvider);
    if (state.pageData == null) return '';

    for (final paragraph in state.pageData!.paragraphs) {
      final sentenceItems = <TextItem>[];
      for (final textItem in paragraph.textItems) {
        if (textItem.sentenceId == item.sentenceId) {
          sentenceItems.add(textItem);
        } else if (sentenceItems.isNotEmpty) {
          break;
        }
      }
      if (sentenceItems.isNotEmpty) {
        return sentenceItems.map((i) => i.text).join();
      }
    }
    return '';
  }

  void _showTermForm(TermForm termForm) {
    _currentTermForm = termForm;
    _isDictionaryOpen = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: Navigator.of(context),
      ),
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: PopScope(
            canPop: true,
            onPopInvoked: (didPop) async {
              if (didPop && settings.autoSave) {
                final updatedForm = _currentTermForm ?? termForm;
                ref.read(readerProvider.notifier).saveTerm(updatedForm).then((
                  success,
                ) {
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save term')),
                    );
                  }
                });
              }
            },
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 500) {
                      Navigator.of(context).pop();
                    }
                  },
                  behavior: HitTestBehavior.translucent,
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
                          ref
                              .read(readerProvider.notifier)
                              .updateTermStatus(
                                updatedForm.termId!,
                                updatedForm.status,
                              );
                        }
                        Navigator.of(context).pop();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save term'),
                            ),
                          );
                        }
                      }
                    },
                    onCancel: () => Navigator.of(context).pop(),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: Navigator.of(context),
      ),
      builder: (context) {
        final repository = ref.read(readerRepositoryProvider);
        final settings = ref.read(termFormSettingsProvider);
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: PopScope(
            canPop: true,
            onPopInvoked: (didPop) async {
              if (didPop && settings.autoSave) {
                final updatedForm = _currentTermForm ?? termForm;
                ref.read(readerProvider.notifier).saveTerm(updatedForm).then((
                  success,
                ) {
                  if (success && mounted && updatedForm.termId != null) {
                    ref
                        .read(readerProvider.notifier)
                        .updateTermStatus(
                          updatedForm.termId!,
                          updatedForm.status,
                        );
                  }
                });
              }
            },
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 500) {
                      Navigator.of(context).pop();
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: TermFormWidget(
                    termForm: termForm,
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
                        Navigator.of(context).pop();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save term'),
                            ),
                          );
                        }
                      }
                    },
                    onCancel: () => Navigator.of(context).pop(),
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
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: Navigator.of(context),
      ),
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

  Future<void> _goToPage(int pageNum) async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    if (pageNum > pageData.currentPage) {
      try {
        await ref
            .read(readerProvider.notifier)
            .markPageRead(pageData.bookId, pageData.currentPage);
      } catch (e) {
        print('Error marking page as read: $e');
      }
    }

    ref
        .read(readerProvider.notifier)
        .loadPage(
          bookId: pageData.bookId,
          pageNum: pageNum,
          showFullPageError: false,
        );
  }

  void _showTextFormattingOptions() {
    final settings = ref.read(textFormattingSettingsProvider);

    _tempTextSize = settings.textSize;
    _tempLineSpacing = settings.lineSpacing;
    _tempFont = settings.fontFamily;
    _tempFontWeight = _availableWeights.indexOf(settings.fontWeight).toDouble();
    _tempIsItalic = settings.isItalic;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Text Formatting',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Text size slider
                    const Text('Text Size'),
                    Slider(
                      value: _tempTextSize,
                      min: 12,
                      max: 30,
                      divisions: 18,
                      label: _tempTextSize.round().toString(),
                      onChanged: (value) {
                        dialogSetState(() {
                          _tempTextSize = value;
                        });
                      },
                      onChangeEnd: (value) {
                        ref
                            .read(textFormattingSettingsProvider.notifier)
                            .updateTextSize(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Line spacing slider
                    const Text('Line Spacing'),
                    Slider(
                      value: _tempLineSpacing,
                      min: 0.6,
                      max: 2.0,
                      divisions: 14,
                      label: _tempLineSpacing.toStringAsFixed(1),
                      onChanged: (value) {
                        dialogSetState(() {
                          _tempLineSpacing = value;
                        });
                      },
                      onChangeEnd: (value) {
                        ref
                            .read(textFormattingSettingsProvider.notifier)
                            .updateLineSpacing(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Font dropdown
                    const Text('Font'),
                    DropdownButton<String>(
                      value: _tempFont ?? 'Roboto',
                      isExpanded: true,
                      items: _availableFonts.map((String font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(font),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          dialogSetState(() {
                            _tempFont = newValue;
                          });
                          ref
                              .read(textFormattingSettingsProvider.notifier)
                              .updateFontFamily(newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Font weight slider
                    const Text('Weight'),
                    Slider(
                      value: _tempFontWeight,
                      min: 0,
                      max: _availableWeights.length - 1,
                      divisions: _availableWeights.length - 1,
                      label: _getWeightLabel(_tempFontWeight),
                      onChanged: (value) {
                        dialogSetState(() {
                          _tempFontWeight = value;
                        });
                      },
                      onChangeEnd: (value) {
                        ref
                            .read(textFormattingSettingsProvider.notifier)
                            .updateFontWeight(_getWeightFromIndex(value));
                      },
                    ),
                    const SizedBox(height: 16),

                    // Italic toggle
                    Row(
                      children: [
                        const Text('Italic'),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _tempIsItalic ?? false,
                            onChanged: (value) {
                              dialogSetState(() {
                                _tempIsItalic = value;
                              });
                              ref
                                  .read(textFormattingSettingsProvider.notifier)
                                  .updateIsItalic(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Formatting applied!'),
                            ),
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markPageKnown() async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    try {
      await ref
          .read(readerProvider.notifier)
          .markPageKnown(pageData!.bookId, pageData!.currentPage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page marked as All Known'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error marking page as known: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark page as known: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
