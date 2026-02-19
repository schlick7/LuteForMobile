import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/books/providers/books_provider.dart';
import '../../features/reader/providers/reader_provider.dart';

final globalLoadingProvider = Provider<bool>((ref) {
  final booksState = ref.watch(booksProvider);
  final readerState = ref.watch(readerProvider);

  return booksState.isRefreshing ||
      readerState.isLoading ||
      readerState.isBackgroundRefreshing ||
      readerState.isPreloadingTooltips;
});
