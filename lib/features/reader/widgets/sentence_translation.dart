import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sentence_translation.dart';
import '../../settings/models/ai_settings.dart';
import '../../settings/providers/ai_settings_provider.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../core/network/dictionary_service.dart';
import '../../../core/network/tts_service.dart';
import '../../../core/providers/tts_provider.dart';

class SentenceTranslationWidget extends ConsumerStatefulWidget {
  final String sentence;
  final SentenceTranslation? translation;
  final String translationProvider;
  final VoidCallback? onTranslate;
  final VoidCallback onClose;
  final VoidCallback? onPreviousSentence;
  final VoidCallback? onNextSentence;
  final int languageId;
  final DictionaryService dictionaryService;

  const SentenceTranslationWidget({
    super.key,
    required this.sentence,
    this.translation,
    required this.translationProvider,
    this.onTranslate,
    required this.onClose,
    this.onPreviousSentence,
    this.onNextSentence,
    required this.languageId,
    required this.dictionaryService,
  });

  @override
  ConsumerState<SentenceTranslationWidget> createState() =>
      _SentenceTranslationWidgetState();
}

class _SentenceTranslationWidgetState
    extends ConsumerState<SentenceTranslationWidget> {
  late PageController _pageController;
  late TTSService _ttsService;
  List<DictionarySource> _dictionaries = [];
  int _currentPage = 0;
  final Map<int, InAppWebViewController> _webviewControllers = {};
  bool _hasLoaded = false;
  bool _isLoadingAI = false;
  String? _aiTranslation;
  String? _aiErrorMessage;
  bool _hasFetchedAI = false;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _pageController = PageController(initialPage: 0);
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    if (!mounted) return;

    final dictionaries = await widget.dictionaryService
        .getSentenceDictionariesForLanguage(widget.languageId);

    if (!mounted) return;

    final lastUsed = await widget.dictionaryService
        .getLastUsedSentenceDictionary(widget.languageId);

    if (!mounted) return;

    int initialPage = 0;
    if (lastUsed != null && dictionaries.isNotEmpty) {
      final index = dictionaries.indexWhere((d) => d.name == lastUsed);
      if (index >= 0) {
        initialPage = index;
      }
    }

    final aiSettings = ref.read(aiSettingsProvider);
    final aiConfig = aiSettings.promptConfigs[AIPromptType.sentenceTranslation];
    final shouldAddAI =
        aiSettings.provider != AIProvider.none && aiConfig?.enabled == true;

    final allDictionaries = List<DictionarySource>.from(dictionaries);
    if (shouldAddAI) {
      final modelName =
          aiSettings.providerConfigs[aiSettings.provider]?.model ?? 'gpt-4o';
      allDictionaries.add(
        DictionarySource(name: 'AI: $modelName', urlTemplate: '', isAI: true),
      );
    }

    setState(() {
      _dictionaries = allDictionaries;
      _currentPage = initialPage;
      _hasLoaded = true;
      _pageController.dispose();
      _pageController = PageController(initialPage: initialPage);
    });
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
      final aiSettings = ref.read(aiSettingsProvider);
      final language =
          aiSettings
              .promptConfigs[AIPromptType.sentenceTranslation]
              ?.language ??
          'Unknown';

      final translation = await aiService.translateSentence(
        widget.sentence,
        language,
      );

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

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dictionaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildOriginalSentence(context),
            const SizedBox(height: 12),
            _buildNoDictionariesState(context),
            const SizedBox(height: 8),
            _buildCloseButton(context),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildOriginalSentence(context),
          const SizedBox(height: 8),
          SizedBox(height: 300, child: _buildDictionaryContent(context)),
          const SizedBox(height: 8),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (_dictionaries.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: null,
            tooltip: 'Previous dictionary',
          ),
          Text(
            'No Dictionaries',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: null,
            tooltip: 'Next dictionary',
          ),
        ],
      );
    }

    final currentDict = _dictionaries[_currentPage];
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
            tooltip: 'Previous dictionary',
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
            onPressed: _currentPage < _dictionaries.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            tooltip: 'Next dictionary',
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalSentence(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Original',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.customColors.accentLabelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () {
                _ttsService.speak(widget.sentence);
              },
              icon: const Icon(Icons.volume_up),
              tooltip: 'Read sentence',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            widget.sentence,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildDictionaryContent(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) async {
        setState(() {
          _currentPage = index;
        });
        final currentDict = _dictionaries[index];
        if (currentDict.isAI) {
          _fetchAITranslation();
        } else {
          await widget.dictionaryService.rememberLastUsedSentenceDictionary(
            widget.languageId,
            _dictionaries[index].name,
          );
        }
      },
      itemCount: _dictionaries.length,
      itemBuilder: (context, index) {
        return _buildWebViewPage(context, _dictionaries[index]);
      },
    );
  }

  Widget _buildWebViewPage(BuildContext context, DictionarySource dictionary) {
    if (dictionary.isAI) {
      return _buildAIContent(context);
    }

    final url = widget.dictionaryService.buildUrl(
      widget.sentence,
      dictionary.urlTemplate,
    );

    return InAppWebView(
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
    );
  }

  Widget _buildAIContent(BuildContext context) {
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
              'Translation:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _aiTranslation),
              maxLines: null,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoDictionariesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
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

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(onPressed: widget.onClose, child: const Text('Close')),
    );
  }
}
