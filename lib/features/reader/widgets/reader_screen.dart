import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../models/text_item.dart';
import '../providers/reader_provider.dart';
import 'text_display.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends ConsumerState<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(readerProvider.notifier).loadPage();
    });
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
      body: _buildBody(state),
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
      onTap: (item) {
        _handleTap(item);
      },
      onDoubleTap: (item) {
        _handleDoubleTap(item);
      },
    );
  }

  void _handleTap(TextItem item) {
    print('Tapped: ${item.text}');
  }

  void _handleDoubleTap(TextItem item) {
    print('Double-tapped: ${item.text}');
  }

  void _goToPage(int pageNum) {
    final bookId = ref.read(readerProvider).pageData?.bookId ?? 18;
    ref
        .read(readerProvider.notifier)
        .loadPage(bookId: bookId, pageNum: pageNum);
  }
}
