import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signals when the reader has completed initial page load and tooltip prefetching.
/// Used to coordinate app startup sequence - other operations wait for this.
class ReaderReadinessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() => state = true;
  void reset() => state = false;
}

final readerReadinessProvider = NotifierProvider<ReaderReadinessNotifier, bool>(
  () => ReaderReadinessNotifier(),
);

/// Signals when books loading is complete (from cache and/or network).
/// Auto backup triggers after this signal.
class BooksLoadingCompleteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markComplete() => state = true;
  void reset() => state = false;
}

final booksLoadingCompleteProvider =
    NotifierProvider<BooksLoadingCompleteNotifier, bool>(
      () => BooksLoadingCompleteNotifier(),
    );
