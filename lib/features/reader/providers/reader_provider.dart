import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/page_data.dart';
import '../repositories/reader_repository.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/api_service.dart';

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

final apiServiceProvider = Provider<ApiService>((ref) {
  final settings = ref.watch(settingsProvider);
  return ApiService(baseUrl: settings.serverUrl);
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ContentService(apiService: apiService);
});

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final settings = ref.watch(settingsProvider);
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(
    contentService: contentService,
    defaultBookId: settings.defaultBookId,
    defaultPageId: settings.defaultPageId,
  );
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
