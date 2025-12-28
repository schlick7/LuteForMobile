import '../../../core/network/content_service.dart';
import '../models/page_data.dart';
import '../models/term_popup.dart';
import '../models/term_form.dart';

class ReaderRepository {
  final ContentService _contentService;
  final int defaultBookId;
  final int defaultPageId;

  ReaderRepository({
    required ContentService contentService,
    this.defaultBookId = 18,
    this.defaultPageId = 1,
  }) : _contentService = contentService;

  Future<PageData> getPage({int? bookId, int? pageNum}) async {
    final effectiveBookId = bookId ?? defaultBookId;
    final effectivePageNum = pageNum ?? defaultPageId;

    try {
      return await _contentService.getPageContent(
        effectiveBookId,
        effectivePageNum,
      );
    } catch (e) {
      throw Exception('Failed to load page: $e');
    }
  }

  Future<TermPopup> getTermPopup(int termId) async {
    try {
      return await _contentService.getTermPopup(termId);
    } catch (e) {
      throw Exception('Failed to load term popup: $e');
    }
  }

  Future<TermForm> getTermForm(int langId, String text) async {
    try {
      return await _contentService.getTermForm(langId, text);
    } catch (e) {
      throw Exception('Failed to load term form: $e');
    }
  }

  Future<void> saveTermForm(
    int langId,
    String text,
    Map<String, dynamic> data,
  ) async {
    try {
      await _contentService.saveTermForm(langId, text, data);
    } catch (e) {
      throw Exception('Failed to save term: $e');
    }
  }

  Future<void> editTerm(int termId, Map<String, dynamic> data) async {
    try {
      await _contentService.editTerm(termId, data);
    } catch (e) {
      throw Exception('Failed to edit term: $e');
    }
  }
}
