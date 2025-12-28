import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/page_data.dart';
import '../repositories/reader_repository.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;

  const ReaderState({this.isLoading = false, this.pageData, this.errorMessage});

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pageData: pageData,
      errorMessage: errorMessage,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  late ReaderRepository _repository;

  void setRepository(ReaderRepository repository) {
    _repository = repository;
  }

  @override
  ReaderState build() {
    _repository = ref.watch(readerRepositoryProvider);
    return const ReaderState();
  }

  Future<void> loadPage({int? bookId, int? pageNum}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final pageData = await _repository.getPage(
        bookId: bookId,
        pageNum: pageNum,
      );
      state = state.copyWith(isLoading: false, pageData: pageData);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return ReaderRepository();
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
