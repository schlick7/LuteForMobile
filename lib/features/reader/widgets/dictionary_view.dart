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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializePage();
  }

  Future<void> _initializePage() async {
    final lastUsed = await widget.dictionaryService.getLastUsedDictionary(
      widget.languageId,
    );

    if (lastUsed != null && widget.dictionaries.isNotEmpty) {
      final index = widget.dictionaries.indexWhere((d) => d.name == lastUsed);
      if (index >= 0 && index < widget.dictionaries.length) {
        setState(() {
          _currentPage = index;
        });
        _pageController.jumpToPage(index);
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
      mainAxisSize: MainAxisSize.min,
      children: [_buildNarrowHeader(context), _buildSwipeableContent(context)],
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Text(
        currentDict.name,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSwipeableContent(BuildContext context) {
    return SizedBox(
      height: 400,
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
  }

  Widget _buildWebViewPage(BuildContext context, DictionarySource dictionary) {
    final url = widget.dictionaryService.buildUrl(
      widget.term,
      dictionary.urlTemplate,
    );

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        sharedCookiesEnabled: true,
        cacheEnabled: true,
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        _webviewControllers[dictionary.hashCode] = controller;
      },
    );
  }
}
