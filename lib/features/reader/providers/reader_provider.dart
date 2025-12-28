import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/page_data.dart';
import '../models/term_popup.dart';
import '../models/term_form.dart';
import '../repositories/reader_repository.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/api_service.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermPopupLoading;
  final bool isTermFormLoading;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermPopupLoading = false,
    this.isTermFormLoading = false,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermPopupLoading,
    bool? isTermFormLoading,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pageData: pageData,
      errorMessage: errorMessage,
      isTermPopupLoading: isTermPopupLoading ?? this.isTermPopupLoading,
      isTermFormLoading: isTermFormLoading ?? this.isTermFormLoading,
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

  Future<TermPopup?> fetchTermPopup(int termId) async {
    state = state.copyWith(isTermPopupLoading: true);
    try {
      return await _repository.getTermPopup(termId);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermPopupLoading: false);
    }
  }

  Future<TermForm?> fetchTermForm(int langId, String text) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermForm(langId, text);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermFormLoading: false);
    }
  }

  Future<bool> saveTermForm(
    int langId,
    String text,
    Map<String, dynamic> data,
  ) async {
    try {
      await _repository.saveTermForm(langId, text, data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editTerm(int termId, Map<String, dynamic> data) async {
    try {
      await _repository.editTerm(termId, data);
      return true;
    } catch (e) {
      return false;
    }
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
