import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../models/text_item.dart';
import '../models/term_popup.dart';
import '../models/term_form.dart';
import '../providers/reader_provider.dart';
import 'text_display.dart';
import 'term_tooltip.dart';
import 'term_form.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends ConsumerState<ReaderScreen> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(readerProvider.notifier).loadPage();
    });
  }

  @override
  void dispose() {
    _removeTermTooltip();
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

    return TextDisplay(
      paragraphs: state.pageData!.paragraphs,
      onTap: (item, position) {
        _handleTap(item, position);
      },
      onDoubleTap: (item) {
        _handleDoubleTap(item);
      },
    );
  }

  void _handleTap(TextItem item, Offset position) async {
    if (item.wordId == null) return;

    final termPopup = await ref
        .read(readerProvider.notifier)
        .fetchTermPopup(item.wordId!);
    if (termPopup != null && mounted) {
      _showTermTooltip(termPopup, position);
    }
  }

  void _handleDoubleTap(TextItem item) async {
    _removeTermTooltip();

    if (item.langId == null) return;

    final termForm = await ref
        .read(readerProvider.notifier)
        .fetchTermForm(item.langId!, item.text);
    if (termForm != null && mounted) {
      _showTermForm(termForm);
    }
  }

  void _showTermTooltip(TermPopup termPopup, Offset position) {
    _removeTermTooltip();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => TermTooltip(
        termPopup: termPopup,
        position: position,
        onDismiss: () {
          _removeTermTooltip();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeTermTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
              .saveTermForm(
                updatedForm.languageId,
                updatedForm.term,
                updatedForm.toFormData(),
              );
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
}
