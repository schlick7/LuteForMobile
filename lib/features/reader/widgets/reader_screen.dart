import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../models/text_item.dart';
import '../models/term_form.dart';
import '../providers/reader_provider.dart';
import '../widgets/term_tooltip.dart';
import 'text_display.dart';
import 'term_form.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _textSize = 18.0;
  double _lineSpacing = 1.5;
  String _selectedFont = 'Roboto';
  final List<String> _availableFonts = [
    'Roboto',
    'Georgia',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Verdana',
  ];

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
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            switch (value) {
              case 'text_formatting':
                _showTextFormattingOptions();
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'text_formatting',
                child: Text('Text Formatting'),
              ),
            ];
          },
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
        textSize: _textSize,
        lineSpacing: _lineSpacing,
        fontFamily: _selectedFont,
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
            .fetchTermForm(item.langId!, item.text);
      }
      if (termForm != null && mounted) {
        _showTermForm(termForm);
      }
    } catch (e) {
      return;
    }
  }

  void _showTermForm(TermForm termForm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TermFormWidget(
        termForm: termForm,
        onSave: (updatedForm) async {
          final success = await ref
              .read(readerProvider.notifier)
              .saveTerm(updatedForm);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Term saved successfully')),
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save term')),
              );
            }
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _goToPage(int pageNum) {
    final bookId = ref.read(readerProvider).pageData?.bookId ?? 18;
    ref
        .read(readerProvider.notifier)
        .loadPage(bookId: bookId, pageNum: pageNum);
  }

  void _showTextFormattingOptions() {
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
                      value: _textSize,
                      min: 12,
                      max: 24,
                      divisions: 12,
                      label: _textSize.round().toString(),
                      onChanged: (value) {
                        dialogSetState(() {
                          _textSize = value;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Line spacing slider
                    const Text('Line Spacing'),
                    Slider(
                      value: _lineSpacing,
                      min: 1.0,
                      max: 2.0,
                      divisions: 10,
                      label: _lineSpacing.toStringAsFixed(1),
                      onChanged: (value) {
                        dialogSetState(() {
                          _lineSpacing = value;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Font dropdown
                    const Text('Font'),
                    DropdownButton<String>(
                      value: _selectedFont,
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
                            _selectedFont = newValue;
                          });
                          setState(() {});
                        }
                      },
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
