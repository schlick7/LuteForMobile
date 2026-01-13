import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/utils/language_flag_mapper.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/terms/providers/terms_provider.dart';
import '../../../features/stats/providers/stats_provider.dart';
import '../../../features/stats/models/stats_data.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../models/page_data.dart';
import '../providers/reader_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/term_tooltip.dart';
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
  Timer? _glowTimer;
  int? _highlightedWordId;
  int? _highlightedParagraphId;
  int? _highlightedOrder;
  int? _originalWordId;
  TextItem? _originalTextItem;
  ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0.0;
  DateTime? _lastMarkPageTime;
  bool _isLastPageMarkedDone = false;
  int? _lastAttemptedBookId;
  int? _lastAttemptedPageNum;
  bool _isNavigatingForward = true;
  Key _pageKey = const ValueKey('page');
  Map<int, String> _languageIdToName = {};
  String _currentLanguageName = '';
  int? _lastStatsLangId;
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

  Future<void> _loadLanguageMapping() async {
    final repository = ref.read(readerRepositoryProvider);
    try {
      final languages = await repository.contentService.getLanguagesWithIds();
      setState(() {
        _languageIdToName = {for (var lang in languages) lang.id: lang.name};
      });
    } catch (e) {
      print('DEBUG: Failed to load language mapping: $e');
    }
  }

  void _updateLanguageStats() {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    int? langId;
    for (final paragraph in pageData.paragraphs) {
      for (final textItem in paragraph.textItems) {
        if (textItem.langId != null && textItem.langId != 0) {
          langId = textItem.langId;
          break;
        }
      }
      if (langId != null) break;
    }

    if (langId == null || langId == 0) return;

    final languageName = _languageIdToName[langId] ?? '';
    if (languageName != _currentLanguageName) {
      setState(() {
        _currentLanguageName = languageName;
      });
    }

    if (langId != _lastStatsLangId) {
      _lastStatsLangId = langId;
      ref.read(termsProvider.notifier).loadStats(langId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasInitialized = true;
    _scrollController.addListener(_handleScrollPosition);
    _loadLanguageMapping();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideUiTimer?.cancel();
    _glowTimer?.cancel();
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
      setState(() {
        _pageKey = ValueKey('${pageData.bookId}-${pageData.currentPage}');
        _isLastPageMarkedDone = false;
      });
      await ref
          .read(readerProvider.notifier)
          .loadPage(bookId: pageData.bookId, pageNum: pageData.currentPage);
      _loadAudioIfNeeded();
    }
  }

  Future<void> loadBook(int bookId, [int? pageNum]) async {
    print('DEBUG: loadBook called with bookId=$bookId, pageNum=$pageNum');
    setState(() {
      _pageKey = ValueKey('$bookId-${pageNum ?? 1}');
      _isLastPageMarkedDone = false;
      _lastAttemptedBookId = bookId;
      _lastAttemptedPageNum = pageNum;
    });
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

    final statsState = ref.watch(statsProvider);
    if (statsState.value == null) {
      ref.read(statsProvider.notifier).loadStats();
    }

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
                            ? () => _loadPageWithoutMarkingRead(
                                pageData!.currentPage - 1,
                              )
                            : null,
                        tooltip: 'Previous page',
                      ),
                      GestureDetector(
                        onDoubleTap: () => _showPageNavigationSlider(),
                        onLongPress: () => _showPageNavigationSlider(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(pageData!.pageIndicator),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: pageData!.currentPage < pageData!.pageCount
                            ? () => _loadPageWithoutMarkingRead(
                                pageData!.currentPage + 1,
                              )
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
                      ? () => _loadPageWithoutMarkingRead(
                          pageData!.currentPage - 1,
                        )
                      : null,
                  tooltip: 'Previous page',
                ),
                GestureDetector(
                  onDoubleTap: () => _showPageNavigationSlider(),
                  onLongPress: () => _showPageNavigationSlider(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(pageData!.pageIndicator),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: pageData!.currentPage < pageData!.pageCount
                      ? () => _loadPageWithoutMarkingRead(
                          pageData!.currentPage + 1,
                        )
                      : null,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final statsState = ref.watch(statsProvider);
    final termsState = ref.watch(termsProvider);
    final pageData = ref.read(readerProvider).pageData;

    if (pageData != null) {
      _updateLanguageStats();
    }

    final languageFlag = getFlagForLanguage(_currentLanguageName) ?? '';

    int todayWordcount = 0;
    int status99Count = termsState.stats.status99;

    if (statsState.value != null) {
      final today = DateTime.now();

      for (final langStats in statsState.value!.languages) {
        if (langStats.language == _currentLanguageName) {
          final todayStats = langStats.dailyStats.firstWhere(
            (s) =>
                s.date.year == today.year &&
                s.date.month == today.month &&
                s.date.day == today.day,
            orElse: () =>
                DailyReadingStats(date: today, wordcount: 0, runningTotal: 0),
          );
          todayWordcount = todayStats.wordcount;
          break;
        }
      }
    }

    final theme = Theme.of(context);

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
          Text("Known: $status99Count", style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPageControls(BuildContext context, PageData pageData) {
    final isLastPage = pageData.currentPage == pageData.pageCount;
    final theme = Theme.of(context);
    final showStatsBar = ref.read(settingsProvider).showStatsBar;

    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 4),
                        Text('All Known'),
                      ],
                    ),
                    onPressed: () => _markPageKnown(),
                    tooltip: 'All Known',
                  ),
                  const SizedBox(width: 24),
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
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (isLastPage)
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: _isLastPageMarkedDone
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _markLastPageDone(pageData),
                      tooltip: 'Mark as done',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _goToPage(pageData.currentPage + 1),
                      tooltip: 'Next page',
                    ),
                ],
              ),
              if (showStatsBar) _buildStatsRow(),
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
      final bookId = pageData?.bookId ?? _lastAttemptedBookId;
      final pageNum = pageData?.currentPage ?? _lastAttemptedPageNum;

      return ErrorDisplay(
        message: errorMessage,
        onRetry: bookId != null
            ? () {
                ref.read(readerProvider.notifier).clearError();
                ref
                    .read(readerProvider.notifier)
                    .loadPage(bookId: bookId, pageNum: pageNum);
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
                      ref.read(navigationProvider).navigateToScreen(5),
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
    final settings = ref.watch(settingsProvider);

    final hasGestureNav = MediaQuery.of(context).systemGestureInsets.bottom > 0;
    final textDisplay = TextDisplay(
      key: _pageKey,
      paragraphs: pageData!.paragraphs,
      scrollController: _scrollController,
      topPadding: textSettings.fullscreenMode && !_isUiVisible
          ? MediaQuery.of(context).padding.top
          : 0.0,
      bottomPadding: hasGestureNav ? 128 : 0,
      bottomControlWidget: _buildPageControls(context, pageData),
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
      highlightedWordId: _highlightedWordId,
      highlightedParagraphId: _highlightedParagraphId,
      highlightedOrder: _highlightedOrder,
    );

    return Stack(
      children: [
        GestureDetector(
          onTapDown: (_) => TermTooltipClass.close(),
          onTap: () {
            if (textSettings.fullscreenMode && !_isUiVisible) {
              _showUi();
            }
          },
          onHorizontalDragEnd: (details) async {
            if (pageData!.pageCount <= 1) return;

            final currentTextSettings = ref.read(
              textFormattingSettingsProvider,
            );

            if (!currentTextSettings.swipeNavigationEnabled) return;

            final velocity = details.primaryVelocity ?? 0;
            const minSwipeVelocity = 300.0;

            if (velocity.abs() < minSwipeVelocity) return;

            if (velocity > 0) {
              if (pageData!.currentPage > 1) {
                _loadPageWithoutMarkingRead(pageData!.currentPage - 1);
              }
            } else if (velocity < 0) {
              if (pageData!.currentPage < pageData!.pageCount) {
                final currentTextSettings = ref.read(
                  textFormattingSettingsProvider,
                );

                if (currentTextSettings.swipeMarksRead) {
                  ref
                      .read(readerProvider.notifier)
                      .markPageRead(pageData!.bookId, pageData!.currentPage);
                }

                _loadPageWithoutMarkingRead(pageData!.currentPage + 1);
              }
            }
          },
          child: settings.pageTurnAnimations
              ? _PageTransition(
                  isForward: _isNavigatingForward,
                  child: textDisplay,
                )
              : textDisplay,
        ),
        if (hasGestureNav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              onTap: () {
                if (textSettings.fullscreenMode && !_isUiVisible) {
                  _showUi();
                }
              },
              child: const SizedBox.shrink(),
            ),
          ),
      ],
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

    // Store original identifiers before opening term form
    _originalWordId = item.wordId;
    _originalTextItem = item;
    _highlightedWordId = null;
    _highlightedParagraphId = null;
    _highlightedOrder = null;

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

  void _triggerWordGlow() {
    final settings = ref.read(termFormSettingsProvider);

    // Only trigger if enabled and we have an original text item
    if (!settings.wordGlowEnabled || _originalTextItem == null) return;

    // Cancel any existing timer
    _glowTimer?.cancel();

    // Set highlight for this specific instance
    setState(() {
      _highlightedWordId = _originalTextItem!.wordId;
      _highlightedParagraphId = _originalTextItem!.paragraphId;
      _highlightedOrder = _originalTextItem!.order;
    });

    // Auto-dismiss after 150ms
    _glowTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _highlightedWordId = null;
          _highlightedParagraphId = null;
          _highlightedOrder = null;
        });
      }
    });
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
    bool _shouldAutoSaveOnClose = true;
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
              if (didPop && settings.autoSave && _shouldAutoSaveOnClose) {
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
                    onStatus99Changed: (langId) {
                      ref.read(termsProvider.notifier).loadStats(langId);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        _triggerWordGlow();
      }
    });
  }

  void _showParentTermForm(TermForm termForm) {
    _isDictionaryOpen = false;
    bool _shouldAutoSaveOnClose = true;
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
              if (didPop && settings.autoSave && _shouldAutoSaveOnClose) {
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
                    onStatus99Changed: (langId) {
                      ref.read(termsProvider.notifier).loadStats(langId);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        _triggerWordGlow();
      }
    });
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

    setState(() {
      _isNavigatingForward = pageNum > pageData.currentPage;
      _pageKey = ValueKey('${pageData.bookId}-$pageNum');
      _isLastPageMarkedDone = false;
      _lastAttemptedBookId = pageData.bookId;
      _lastAttemptedPageNum = pageNum;
      _highlightedWordId = null;
      _originalWordId = null;
    });

    if (pageNum > pageData.currentPage) {
      try {
        await ref
            .read(readerProvider.notifier)
            .markPageRead(pageData.bookId, pageData.currentPage);
      } catch (e) {
        print('Error marking page as read: $e');
      }
    }

    await ref
        .read(readerProvider.notifier)
        .loadPage(
          bookId: pageData.bookId,
          pageNum: pageNum,
          showFullPageError: false,
          useCache: true,
        );

    ref.read(statsProvider.notifier).loadStats();
  }

  Future<void> _loadPageWithoutMarkingRead(int pageNum) async {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    setState(() {
      _isNavigatingForward = pageNum > pageData.currentPage;
      _pageKey = ValueKey('${pageData.bookId}-$pageNum');
      _isLastPageMarkedDone = false;
      _lastAttemptedBookId = pageData.bookId;
      _lastAttemptedPageNum = pageNum;
      _highlightedWordId = null;
      _originalWordId = null;
    });

    await ref
        .read(readerProvider.notifier)
        .loadPage(
          bookId: pageData.bookId,
          pageNum: pageNum,
          showFullPageError: false,
          useCache: true,
        );

    ref.read(statsProvider.notifier).loadStats();
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

      if (pageData.currentPage < pageData.pageCount) {
        _goToPage(pageData.currentPage + 1);
      } else {
        ref
            .read(readerProvider.notifier)
            .loadPage(
              bookId: pageData.bookId,
              pageNum: pageData.currentPage,
              showFullPageError: false,
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

  Future<void> _markLastPageDone(PageData pageData) async {
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

  void _showPageNavigationSlider() {
    final pageData = ref.read(readerProvider).pageData;
    if (pageData == null) return;

    double tempPage = pageData.currentPage.toDouble();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page ${tempPage.toInt()} of ${pageData.pageCount}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Slider(
                    value: tempPage,
                    min: 1,
                    max: pageData.pageCount.toDouble(),
                    divisions: pageData.pageCount - 1,
                    label: tempPage.toInt().toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempPage = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _goToPage(tempPage.toInt());
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }
}
