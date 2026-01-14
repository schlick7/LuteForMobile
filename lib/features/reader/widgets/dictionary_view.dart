import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dictionary_service.dart';
import '../../settings/models/ai_settings.dart';
import '../../settings/providers/ai_settings_provider.dart';
import '../../../core/providers/ai_provider.dart';
import '../providers/current_book_provider.dart';

enum DictionaryTabType { dictionary, ai }

enum AITabType { translation, virtualDictionary }

class DictionaryView extends ConsumerStatefulWidget {
  final String term;
  final String? sentence;
  final List<DictionarySource> dictionaries;
  final int languageId;
  final VoidCallback onClose;
  final bool isVisible;
  final DictionaryService dictionaryService;
  final void Function(String)? onAddAITranslation;

  const DictionaryView({
    super.key,
    required this.term,
    this.sentence,
    required this.dictionaries,
    required this.languageId,
    required this.onClose,
    required this.isVisible,
    required this.dictionaryService,
    this.onAddAITranslation,
  });

  @override
  ConsumerState<DictionaryView> createState() => _DictionaryViewState();
}

class _DictionaryViewState extends ConsumerState<DictionaryView> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, InAppWebViewController> _webviewControllers = {};
  bool _hasLoaded = false;
  DictionaryTabType _currentTab = DictionaryTabType.dictionary;
  AITabType _currentAITab = AITabType.translation;
  String? _aiTranslation;
  String? _aiErrorMessage;
  bool _isLoadingAI = false;
  bool _hasFetchedAI = false;
  String? _virtualDictionaryContent;
  String? _virtualDictionaryError;
  bool _isLoadingVirtualDict = false;
  bool _hasFetchedVirtualDict = false;
  final Set<int> _preloadedPages = {};
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadInitialPage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPage() async {
    if (!mounted) return;

    final lastUsed = await widget.dictionaryService.getLastUsedDictionary(
      widget.languageId,
    );

    if (!mounted) return;

    if (lastUsed != null && widget.dictionaries.isNotEmpty) {
      final index = widget.dictionaries.indexWhere((d) => d.name == lastUsed);
      if (index >= 0) {
        setState(() {
          _currentPage = index;
        });
        _pageController.dispose();
        _pageController = PageController(initialPage: index);
      }
    }

    setState(() {
      _hasLoaded = true;
    });
  }

  bool _shouldShowAITab() {
    final aiSettings = ref.watch(aiSettingsProvider);
    final provider = aiSettings.provider;
    final termConfig = aiSettings.promptConfigs[AIPromptType.termTranslation];
    return provider != AIProvider.none && termConfig?.enabled == true;
  }

  bool _shouldShowVirtualDictionary() {
    final aiSettings = ref.watch(aiSettingsProvider);
    final provider = aiSettings.provider;
    final virtualDictConfig =
        aiSettings.promptConfigs[AIPromptType.termExplanation];
    return provider != AIProvider.none && virtualDictConfig?.enabled == true;
  }

  Future<void> _fetchAITranslation() async {
    if (_isLoadingAI || _hasFetchedAI) return;

    setState(() {
      _isLoadingAI = true;
      _aiTranslation = null;
      _aiErrorMessage = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final currentBookState = ref.read(currentBookProvider);
      final language =
          currentBookState.languageName ??
          currentBookState.book?.language ??
          'Unknown';

      final translation = await aiService.translateTerm(widget.term, language);

      if (mounted) {
        setState(() {
          _isLoadingAI = false;
          _aiTranslation = translation;
          _hasFetchedAI = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
          _aiErrorMessage = e.toString();
          _hasFetchedAI = true;
        });
      }
    }
  }

  Future<void> _fetchVirtualDictionary() async {
    if (_isLoadingVirtualDict || _hasFetchedVirtualDict) return;

    setState(() {
      _isLoadingVirtualDict = true;
      _virtualDictionaryContent = null;
      _virtualDictionaryError = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final currentBookState = ref.read(currentBookProvider);
      final language = currentBookState.languageName ?? 'Unknown';

      final content = await aiService.getTermExplanation(
        widget.term,
        language,
        sentence: widget.sentence,
      );

      if (mounted) {
        setState(() {
          _isLoadingVirtualDict = false;
          _virtualDictionaryContent = content;
          _hasFetchedVirtualDict = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVirtualDict = false;
          _virtualDictionaryError = e.toString();
          _hasFetchedVirtualDict = true;
        });
      }
    }
  }

  void _handleAddToTranslation() {
    if (_aiTranslation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No AI translation available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.onAddAITranslation == null) return;

    final cleanTranslation = _aiTranslation!.replaceAll('\n', ' ');
    widget.onAddAITranslation!(cleanTranslation);
  }

  Future<void> _preloadAdjacentPages() async {
    if (_isPreloading || !mounted || widget.dictionaries.isEmpty) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted || !widget.isVisible) {
      return;
    }

    _isPreloading = true;

    final pagesToPreload = <int>[];

    if (_currentPage > 0 && !_preloadedPages.contains(_currentPage - 1)) {
      pagesToPreload.add(_currentPage - 1);
    }

    if (_currentPage < widget.dictionaries.length - 1 &&
        !_preloadedPages.contains(_currentPage + 1)) {
      pagesToPreload.add(_currentPage + 1);
    }

    if (pagesToPreload.isEmpty) {
      _isPreloading = false;
      return;
    }

    for (final pageIndex in pagesToPreload) {
      if (!mounted) break;

      try {
        _pageController.jumpToPage(pageIndex);
        _preloadedPages.add(pageIndex);

        if (!mounted) break;

        _pageController.jumpToPage(_currentPage);
      } catch (e) {
        if (kDebugMode) {
          print('Error preloading page $pageIndex: $e');
        }
      }
    }

    _isPreloading = false;
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAITab = _shouldShowAITab();
    final shouldShowVirtualDict = _shouldShowVirtualDictionary();

    if (widget.dictionaries.isEmpty && !shouldShowAITab) {
      return _buildEmptyState(context);
    }

    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shouldShowAITab && _currentTab == DictionaryTabType.ai) {
      if (_currentAITab == AITabType.translation && !_hasFetchedAI) {
        _fetchAITranslation();
      } else if (_currentAITab == AITabType.virtualDictionary &&
          !_hasFetchedVirtualDict) {
        _fetchVirtualDictionary();
      }
    }

    return Column(
      children: [
        _buildTabHeader(context, shouldShowAITab, shouldShowVirtualDict),
        const SizedBox(height: 8),
        Expanded(
          child: shouldShowAITab
              ? _buildTabContent(context, shouldShowVirtualDict)
              : _buildSwipeableContent(context),
        ),
      ],
    );
  }

  Widget _buildTabHeader(
    BuildContext context,
    bool shouldShowAITab,
    bool shouldShowVirtualDict,
  ) {
    if (!shouldShowAITab) {
      return _buildNarrowHeader(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTab(
                  context,
                  DictionaryTabType.dictionary,
                  'Dictionary',
                ),
              ),
              Expanded(child: _buildTab(context, DictionaryTabType.ai, 'AI')),
            ],
          ),
        ),
        if (shouldShowVirtualDict && _currentTab == DictionaryTabType.ai)
          _buildAISubTabs(context),
      ],
    );
  }

  Widget _buildAISubTabs(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          _buildAITab(context, AITabType.translation, 'Translation'),
          const SizedBox(width: 16),
          _buildAITab(context, AITabType.virtualDictionary, 'Explanation'),
        ],
      ),
    );
  }

  Widget _buildAITab(BuildContext context, AITabType tab, String label) {
    final isSelected = _currentAITab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAITab = tab;
          if (tab == AITabType.translation && !_hasFetchedAI) {
            _fetchAITranslation();
          } else if (tab == AITabType.virtualDictionary &&
              !_hasFetchedVirtualDict) {
            _fetchVirtualDictionary();
          }
        });
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, DictionaryTabType tab, String label) {
    final isSelected = _currentTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tab;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool shouldShowVirtualDict) {
    switch (_currentTab) {
      case DictionaryTabType.dictionary:
        if (widget.dictionaries.isEmpty) {
          return _buildNoDictionariesState(context);
        }
        return Column(
          children: [
            _buildNarrowHeader(context),
            const SizedBox(height: 8),
            Expanded(child: _buildSwipeableContent(context)),
          ],
        );
      case DictionaryTabType.ai:
        return _buildAIContent(context, shouldShowVirtualDict);
    }
  }

  Widget _buildAIContent(BuildContext context, bool shouldShowVirtualDict) {
    if (_currentAITab == AITabType.virtualDictionary) {
      return _buildVirtualDictionaryContent(context);
    }
    return _buildAITranslationContent(context);
  }

  Widget _buildVirtualDictionaryContent(BuildContext context) {
    if (_isLoadingVirtualDict) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_virtualDictionaryError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Virtual Dictionary Failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _virtualDictionaryError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchVirtualDictionary,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_virtualDictionaryContent != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Explanation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Term: ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.term,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _virtualDictionaryContent!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchVirtualDictionary,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAITranslationContent(BuildContext context) {
    if (_isLoadingAI) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_aiErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'AI Translation Failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _aiErrorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAITranslation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_aiTranslation != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Term: ${widget.term}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Translation:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _aiTranslation!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _handleAddToTranslation,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add to'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchAITranslation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoDictionariesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No dictionaries configured',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
    );
  }

  Widget _buildNarrowHeader(BuildContext context) {
    if (widget.dictionaries.isEmpty) return const SizedBox.shrink();

    final currentDict = widget.dictionaries[_currentPage];
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: _currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          Expanded(
            child: Text(
              currentDict.name,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: _currentPage < widget.dictionaries.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableContent(BuildContext context) {
    if (widget.dictionaries.isEmpty) return const SizedBox.shrink();

    return PageView.builder(
      controller: _pageController,
      allowImplicitScrolling: true,
      onPageChanged: (index) async {
        if (_isPreloading) return;
        setState(() {
          _currentPage = index;
        });
        await widget.dictionaryService.rememberLastUsedDictionary(
          widget.languageId,
          widget.dictionaries[index].name,
        );
      },
      itemCount: widget.dictionaries.length,
      itemBuilder: (context, index) {
        return _buildWebViewPage(context, widget.dictionaries[index], index);
      },
    );
  }

  Widget _buildWebViewPage(
    BuildContext context,
    DictionarySource dictionary,
    int index,
  ) {
    final url = widget.dictionaryService.buildUrl(
      widget.term,
      dictionary.urlTemplate,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialSettings: InAppWebViewSettings(
              sharedCookiesEnabled: true,
              cacheEnabled: true,
              javaScriptEnabled: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory(() => VerticalDragGestureRecognizer()),
            },
            onWebViewCreated: (controller) {
              _webviewControllers[dictionary.hashCode] = controller;
            },
            onLoadStop: (controller, url) {
              if (index == _currentPage) {
                _preloadAdjacentPages();
              }
            },
          ),
        );
      },
    );
  }
}
