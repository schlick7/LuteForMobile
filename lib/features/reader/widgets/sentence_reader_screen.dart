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

class SentenceReaderScreenState extends ConsumerState<SentenceReaderScreen> {
  TermForm? _currentTermForm;
  final Map<int, TermTooltip> _termTooltips = {};
  bool _tooltipsLoadInProgress = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final reader = ref.read(readerProvider);
      if (reader.pageData != null) {
        final langId = _getLangId(reader);

        await ref
            .read(sentenceReaderProvider.notifier)
            .parseSentencesForPage(langId);
        await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();

        _ensureTooltipsLoaded(forceRefresh: true);

        final bookId = reader.pageData!.bookId;
        final pageNum = reader.pageData!.currentPage;

        await ref
            .read(readerProvider.notifier)
            .loadPage(
              bookId: bookId,
              pageNum: pageNum,
              updateReaderState: false,
            );

        await ref
            .read(sentenceReaderProvider.notifier)
            .parseSentencesForPage(langId);

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _ensureTooltipsLoaded({bool forceRefresh = false}) {
    if (_tooltipsLoadInProgress) return;

    final allSentences = ref.read(sentenceReaderProvider).customSentences;
    final allTerms = <TextItem>[];

    for (final sentence in allSentences) {
      allTerms.addAll(sentence.uniqueTerms);
    }

    if (forceRefresh) {
      _termTooltips.clear();
    }

    final hasAllTooltips = allTerms.every(
      (term) => term.wordId == null || _termTooltips.containsKey(term.wordId),
    );

    if (hasAllTooltips && !forceRefresh) return;

    _loadAllTermTranslations();
  }

  Future<void> _loadAllTermTranslations() async {
    if (_tooltipsLoadInProgress) return;
    _tooltipsLoadInProgress = true;

    final allSentences = ref.read(sentenceReaderProvider).customSentences;
    final allTerms = <TextItem>[];

    for (final sentence in allSentences) {
      allTerms.addAll(sentence.uniqueTerms);
    }

    for (final term in allTerms) {
      if (term.wordId != null && !_termTooltips.containsKey(term.wordId!)) {
        try {
          final termTooltip = await ref
              .read(readerProvider.notifier)
              .fetchTermTooltip(term.wordId!);
          if (termTooltip != null && mounted) {
            setState(() {
              _termTooltips[term.wordId!] = termTooltip;
            });
          }
        } catch (e) {
          // Skip terms that fail to load
        }
      }
    }

    _tooltipsLoadInProgress = false;
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
    final pageTitle = ref.watch(
      readerProvider.select((state) => state.pageData?.title),
    );
    final readerState = ref.read(readerProvider);
    final sentenceReader = ref.watch(sentenceReaderProvider);

    if (readerState.isLoading) {
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

    _ensureTooltipsLoaded();

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
          Expanded(flex: 3, child: _buildTopSection(textSettings)),
          Expanded(flex: 7, child: _buildBottomSection()),
        ],
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildTopSection(dynamic textSettings) {
    final currentSentence = ref.watch(sentenceReaderProvider).currentSentence;

    if (currentSentence == null) {
      return const Center(child: Text('No sentence available'));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => TermTooltipClass.close(),
      child: Center(
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

  Widget _buildBottomSection() {
    final sentenceReader = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

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

  void _goNext() async {
    await ref.read(sentenceReaderProvider.notifier).nextSentence();
    _saveSentencePosition();
    _ensureTooltipsLoaded(forceRefresh: true);
  }

  void _goPrevious() async {
    await ref.read(sentenceReaderProvider.notifier).previousSentence();
    _saveSentencePosition();
    _ensureTooltipsLoaded(forceRefresh: true);
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
        return StatefulBuilder(
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
                  }
                  Navigator.of(context).pop();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save term')),
                    );
                  }
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
        return StatefulBuilder(
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
                  }
                  Navigator.of(context).pop();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save term')),
                    );
                  }
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
}
