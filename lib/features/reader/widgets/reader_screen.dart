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
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(readerProvider.notifier).loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.pageData?.title ?? 'Reader'),
        actions: [
          if (state.pageData != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text(state.pageData!.pageIndicator)),
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
    );
  }

  void _handleTap(TextItem item) {
    print('Tapped: ${item.text}');
  }
}
