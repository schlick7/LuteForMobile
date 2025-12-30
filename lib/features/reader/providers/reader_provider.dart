import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../repositories/reader_repository.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/api_service.dart';

@immutable
class ReaderState {
  final bool isLoading;
  final PageData? pageData;
  final String? errorMessage;
  final bool isTermTooltipLoading;
  final bool isTermFormLoading;

  const ReaderState({
    this.isLoading = false,
    this.pageData,
    this.errorMessage,
    this.isTermTooltipLoading = false,
    this.isTermFormLoading = false,
  });

  ReaderState copyWith({
    bool? isLoading,
    PageData? pageData,
    String? errorMessage,
    bool? isTermTooltipLoading,
    bool? isTermFormLoading,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pageData: pageData ?? this.pageData,
      errorMessage: errorMessage,
      isTermTooltipLoading: isTermTooltipLoading ?? this.isTermTooltipLoading,
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

  Future<void> loadPage({required int bookId, required int pageNum}) async {
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

  Future<TermTooltip?> fetchTermTooltip(int termId) async {
    state = state.copyWith(isTermTooltipLoading: true);
    try {
      final result = await _repository.getTermTooltip(termId);
      return result;
    } catch (e) {
      print('fetchTermTooltip error: $e');
      return null;
    } finally {
      final newState = state.copyWith(isTermTooltipLoading: false);
      print(
        'State change: pageData=${newState.pageData != null}, errorMessage=${newState.errorMessage}',
      );
      state = newState;
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
        print('saveTerm: editing existing term ${termForm.termId}');
        await _repository.editTerm(termForm.termId!, termForm.toFormData());
        updateTermStatus(termForm.termId!, termForm.status);
      } else {
        print('saveTerm: creating new term "${termForm.term}" (no termId)');
        await _repository.saveTermForm(
          termForm.languageId,
          termForm.term,
          termForm.toFormData(),
        );
      }
      return true;
    } catch (e) {
      print('saveTerm error: $e');
      return false;
    }
  }

  void updateTermStatus(int termId, String status) {
    final currentPageData = state.pageData;
    if (currentPageData == null) {
      print('updateTermStatus: pageData is null');
      return;
    }

    print('updateTermStatus: looking for termId=$termId, status=$status');
    bool found = false;
    for (final paragraph in currentPageData.paragraphs) {
      for (final item in paragraph.textItems) {
        if (item.wordId == termId) {
          print('Found term! Current statusClass: ${item.statusClass}');
          found = true;
        }
      }
    }

    if (!found) {
      print('Term with id=$termId not found in page data');
    }

    final updatedParagraphs = currentPageData.paragraphs.map((paragraph) {
      final updatedItems = paragraph.textItems.map((item) {
        if (item.wordId == termId) {
          final updated = item.copyWith(statusClass: 'status$status');
          print(
            'Updated item statusClass from ${item.statusClass} to ${updated.statusClass}',
          );
          return updated;
        }
        return item;
      }).toList();
      return paragraph.copyWith(textItems: updatedItems);
    }).toList();

    state = state.copyWith(
      pageData: currentPageData.copyWith(paragraphs: updatedParagraphs),
    );
    print('updateTermStatus: state updated');
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
  final contentService = ref.watch(contentServiceProvider);
  return ReaderRepository(contentService: contentService);
});

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(() {
  return ReaderNotifier();
});
