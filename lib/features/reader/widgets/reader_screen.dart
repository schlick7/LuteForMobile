import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../providers/reader_provider.dart';
import '../widgets/term_tooltip.dart';
import 'text_display.dart';
import 'term_form.dart';
import '../../../core/network/dictionary_service.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ReaderScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _tempTextSize = 18.0;
  double _tempLineSpacing = 1.5;
  String? _tempFont;
  double _tempFontWeight = 2.0;
  bool? _tempIsItalic;
  TermForm? _currentTermForm;
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
    Future.microtask(() {
      ref.read(readerProvider.notifier).loadPage();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void reloadPage() {
    ref.read(readerProvider.notifier).loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);

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
        title: Text(state.pageData?.title ?? 'Reader'),
        actions: [
          if (state.pageData != null && state.pageData!.pageCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.pageData!.currentPage > 1
                        ? () => _goToPage(state.pageData!.currentPage - 1)
                        : null,
                    tooltip: 'Previous page',
                  ),
                  Text(state.pageData!.pageIndicator),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        state.pageData!.currentPage < state.pageData!.pageCount
                        ? () => _goToPage(state.pageData!.currentPage + 1)
                        : null,
                    tooltip: 'Next page',
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(children: [_buildBody(state)]),
    );
  }

  Widget _buildBody(ReaderState state) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading content...');
    }

    if (state.errorMessage != null) {
      return ErrorDisplay(
        message: state.errorMessage!,
        onRetry: () {
          ref.read(readerProvider.notifier).clearError();
          ref.read(readerProvider.notifier).loadPage();
        },
      );
    }

    if (state.pageData == null) {
      return const ErrorDisplay(message: 'No content available');
    }

    final textSettings = ref.watch(textFormattingSettingsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => TermTooltipClass.close(),
      child: TextDisplay(
        paragraphs: state.pageData!.paragraphs,
        onTap: (item, position) {
          _handleTap(item, position);
        },
        onDoubleTap: (item) {
          _handleDoubleTap(item);
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
    if (item.langId == null) return;

    try {
      TermForm? termForm;
      if (item.wordId != null) {
        termForm = await ref
            .read(readerProvider.notifier)
            .fetchTermFormById(item.wordId!);
      } else {
        termForm = await ref
            .read(readerProvider.notifier)
            .fetchTermFormWithDetails(item.langId!, item.text);
      }
      if (termForm != null && mounted) {
        _showTermForm(termForm);
      }
    } catch (e) {
      return;
    }
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
                print(
                  'onUpdate called with parents: ${updatedForm.parents.map((p) => p.term).toList()}',
                );
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

  void _goToPage(int pageNum) {
    final bookId = ref.read(readerProvider).pageData?.bookId ?? 18;
    ref
        .read(readerProvider.notifier)
        .loadPage(bookId: bookId, pageNum: pageNum);
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
                        Switch(
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
}
