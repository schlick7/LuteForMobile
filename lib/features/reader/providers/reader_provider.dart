import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../models/language_sentence_settings.dart';
import '../repositories/reader_repository.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_config.dart';
import 'sentence_reader_provider.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermTooltipLoading;
  final bool isTermFormLoading;
  final LanguageSentenceSettings? languageSentenceSettings;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermTooltipLoading = false,
    this.isTermFormLoading = false,
    this.languageSentenceSettings,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermTooltipLoading,
    bool? isTermFormLoading,
    LanguageSentenceSettings? languageSentenceSettings,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pageData: pageData ?? this.pageData,
      errorMessage: errorMessage,
      isTermTooltipLoading: isTermTooltipLoading ?? this.isTermTooltipLoading,
      isTermFormLoading: isTermFormLoading ?? this.isTermFormLoading,
      languageSentenceSettings:
          languageSentenceSettings ?? this.languageSentenceSettings,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    return const ReaderState();
  }

  ReaderRepository get _repository => ref.read(readerRepositoryProvider);

  Future<void> loadPage({
    required int bookId,
    int? pageNum,
    bool updateReaderState = true,
    bool showFullPageError = true, // New parameter to control error display
  }) async {
    if (!_repository.contentService.isConfigured) {
      if (updateReaderState) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Server URL not configured. Please set it in settings.',
        );
      }
      return;
    }

    if (updateReaderState) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final pageData = await _repository.getPage(
        bookId: bookId,
        pageNum: pageNum,
      );
      if (updateReaderState) {
        state = state.copyWith(isLoading: false, pageData: pageData);
      }
    } catch (e) {
      // Only show full page error for initial loading, not for navigation
      if (showFullPageError && updateReaderState) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      } else if (updateReaderState) {
        // For navigation errors, just log them but don't show full screen error
        print('Navigation error (not showing full screen): $e');
        // Keep the existing page data and just stop loading state
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> fetchLanguageSentenceSettings(int langId) async {
    try {
      final settings = await _repository.getLanguageSentenceSettings(langId);
      state = state.copyWith(languageSentenceSettings: settings);
    } catch (e) {
      state = state.copyWith(languageSentenceSettings: null);
    }
  }

  Future<TermTooltip?> fetchTermTooltip(int termId) async {
    try {
      final result = await _repository.getTermTooltip(termId);
      return result;
    } catch (e) {
      return null;
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

  Future<TermForm?> fetchTermFormById(int termId) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermFormByIdWithParentDetails(termId);
    } catch (e) {
      return null;
    } finally {
      state = state.copyWith(isTermFormLoading: false);
    }
  }

  Future<TermForm?> fetchTermFormWithDetails(int langId, String text) async {
    state = state.copyWith(isTermFormLoading: true);
    try {
      return await _repository.getTermFormWithParentDetails(langId, text);
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

  Future<bool> saveTerm(TermForm termForm) async {
    try {
      if (termForm.termId != null) {
        await _repository.editTerm(termForm.termId!, termForm.toFormData());
        updateTermStatus(termForm.termId!, termForm.status);
      } else {
        await _repository.saveTermForm(
          termForm.languageId,
          termForm.term,
          termForm.toFormData(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void updateTermStatus(int termId, String status) {
    final currentPageData = state.pageData;
    if (currentPageData == null) {
      return;
    }

    bool found = false;
    final updatedParagraphs = currentPageData.paragraphs.map((paragraph) {
      final updatedItems = paragraph.textItems.map((item) {
        if (item.wordId == termId) {
          found = true;
          final updated = item.copyWith(statusClass: 'status$status');
          return updated;
        }
        return item;
      }).toList();
      return paragraph.copyWith(textItems: updatedItems);
    }).toList();

    if (found) {
      state = state.copyWith(
        pageData: currentPageData.copyWith(paragraphs: updatedParagraphs),
      );

      ref
          .read(sentenceReaderProvider.notifier)
          .updateTermStatusInSentences(termId, status);
    }
  }
}

final apiConfigProvider = Provider<ApiConfig>((ref) {
  final settings = ref.watch(settingsProvider);
  return ApiConfig(baseUrl: settings.serverUrl);
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(apiConfigProvider);
  return ApiService(baseUrl: config.baseUrl);
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ContentService(apiService: apiService);
});

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(contentService: contentService);
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
