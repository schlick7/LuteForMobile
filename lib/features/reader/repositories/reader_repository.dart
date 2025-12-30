import '../../../core/network/content_service.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';

class ReaderRepository {
  final ContentService contentService;

  ReaderRepository({required ContentService contentService})
    : contentService = contentService;

  Future<PageData> getPage({required int bookId, required int pageNum}) async {
    try {
      return await contentService.getPageContent(bookId, pageNum);
    } catch (e) {
      throw Exception('Failed to load page: $e');
    }
  }

  Future<TermTooltip> getTermTooltip(int termId) async {
    try {
      return await contentService.getTermTooltip(termId);
    } catch (e) {
      throw Exception('Failed to load term tooltip: $e');
    }
  }

  Future<TermForm> getTermForm(int langId, String text) async {
    try {
      return await contentService.getTermForm(langId, text);
    } catch (e) {
      throw Exception('Failed to load term form: $e');
    }
  }

  Future<TermForm> getTermFormById(int termId) async {
    try {
      return await contentService.getTermFormById(termId);
    } catch (e) {
      throw Exception('Failed to load term form: $e');
    }
  }

  Future<TermForm> getTermFormWithParentDetails(int langId, String text) async {
    try {
      return await contentService.getTermFormWithParentDetails(langId, text);
    } catch (e) {
      throw Exception('Failed to load term form with parent details: $e');
    }
  }

  Future<TermForm> getTermFormByIdWithParentDetails(int termId) async {
    try {
      return await contentService.getTermFormByIdWithParentDetails(termId);
    } catch (e) {
      throw Exception('Failed to load term form with parent details: $e');
    }
  }

  Future<void> saveTermForm(
    int langId,
    String text,
    Map<String, dynamic> data,
  ) async {
    try {
      await contentService.saveTermForm(langId, text, data);
    } catch (e) {
      throw Exception('Failed to save term: $e');
    }
  }

  Future<void> editTerm(int termId, Map<String, dynamic> data) async {
    try {
      await contentService.editTerm(termId, data);
    } catch (e) {
      throw Exception('Failed to edit term: $e');
    }
  }

  Future<void> createTerm(int langId, String term) async {
    try {
      await contentService.createTerm(langId, term);
    } catch (e) {
      throw Exception('Failed to create term: $e');
    }
  }

  Future<void> saveAudioPlayerData({
    required int bookId,
    required Duration position,
    required List<double> bookmarks,
  }) async {
    try {
      await contentService.saveAudioPlayerData(
        bookId: bookId,
        position: position,
        bookmarks: bookmarks,
      );
    } catch (e) {
      throw Exception('Failed to save audio player data: $e');
    }
  }
}
