import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/network/dictionary_service.dart';

class DictionaryView extends StatefulWidget {
  final String term;
  final List<DictionarySource> dictionaries;
  final int languageId;
  final VoidCallback onClose;
  final bool isVisible;
  final DictionaryService dictionaryService;

  const DictionaryView({
    super.key,
    required this.term,
    required this.dictionaries,
    required this.languageId,
    required this.onClose,
    required this.isVisible,
    required this.dictionaryService,
  });

  @override
  State<DictionaryView> createState() => _DictionaryViewState();
}

class _DictionaryViewState extends State<DictionaryView> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, InAppWebViewController> _webviewControllers = {};
  bool _hasLoaded = false;
  int _initialPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadInitialPage();
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
          _initialPage = index;
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dictionaries.isEmpty) {
      return _buildEmptyState(context);
    }

    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildNarrowHeader(context),
        const SizedBox(height: 8),
        Expanded(child: _buildSwipeableContent(context)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
    );
  }

  Widget _buildNarrowHeader(BuildContext context) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              const minVelocity = 300.0;

              if (velocity.abs() > minVelocity) {
                if (velocity > 0 && _currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (velocity < 0 &&
                    _currentPage < widget.dictionaries.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) async {
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
                return _buildWebViewPage(context, widget.dictionaries[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebViewPage(BuildContext context, DictionarySource dictionary) {
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
            onWebViewCreated: (controller) {
              _webviewControllers[dictionary.hashCode] = controller;
            },
          ),
        );
      },
    );
  }
}
