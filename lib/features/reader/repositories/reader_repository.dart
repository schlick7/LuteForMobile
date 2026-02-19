import '../../../core/network/content_service.dart';
import '../models/page_data.dart';
import '../models/term_tooltip.dart';
import '../models/term_form.dart';
import '../models/language_sentence_settings.dart';

class ReaderRepository {
  final ContentService contentService;

  ReaderRepository({required ContentService contentService})
    : contentService = contentService;

  Future<PageData?> getPage({
    required int bookId,
    int? pageNum,
    ContentMode mode = ContentMode.reading,
    bool useCache = true,
    bool forceRefresh = false,
    String? cachedMetadataHtml,
  }) async {
    try {
      return await contentService.getPageContent(
        bookId,
        pageNum: pageNum,
        mode: mode,
        useCache: useCache,
        forceRefresh: forceRefresh,
        cachedMetadataHtml: cachedMetadataHtml,
      );
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

  /// Fetches a term tooltip and returns both the parsed object and raw HTML.
  /// This is more efficient than calling getTermTooltip and getRawTermTooltipHtml
  /// separately, as it only makes one API request.
  Future<(TermTooltip tooltip, String html)?> getTermTooltipWithHtml(
    int termId,
  ) async {
    try {
      return await contentService.getTermTooltipWithHtml(termId);
    } catch (e) {
      print('Failed to load term tooltip with HTML: $e');
      return null;
    }
  }

  Future<LanguageSentenceSettings> getLanguageSentenceSettings(
    int langId,
  ) async {
    try {
      return await contentService.getLanguageSentenceSettings(langId);
    } catch (e) {
      throw Exception('Failed to load language sentence settings: $e');
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
    required int page,
    required double position,
    required double duration,
    required List<double> bookmarks,
  }) async {
    try {
      await contentService.saveAudioPlayerData(
        bookId: bookId,
        page: page,
        position: position,
        duration: duration,
        bookmarks: bookmarks,
      );
    } catch (e) {
      throw Exception('Failed to save audio player data: $e');
    }
  }

  /// Gets the current page number from the server for a book
  /// This is used to check if the server's current page matches the reader's page
  Future<int> getCurrentPageForBook(int bookId) async {
    try {
      return await contentService.getCurrentPageForBook(bookId);
    } catch (e) {
      throw Exception('Failed to get current page for book: $e');
    }
  }

  Future<void> markPageRead(int bookId, int pageNum) async {
    try {
      await contentService.markPageReadOnly(bookId, pageNum);
    } catch (e) {
      throw Exception('Failed to mark page as read: $e');
    }
  }

  Future<void> markPageKnown(int bookId, int pageNum) async {
    try {
      await contentService.markPageKnownOnly(bookId, pageNum);
    } catch (e) {
      throw Exception('Failed to mark page as known: $e');
    }
  }

  Future<void> savePageToCache(
    int bookId,
    int pageNum,
    PageData pageData,
  ) async {
    try {
      await contentService.savePageToCache(bookId, pageNum, pageData);
    } catch (e) {
      print('Failed to save page to cache: $e');
    }
  }

  /// Preloads a page by fetching it from the network and caching it.
  /// Does nothing if the page is already cached.
  /// This is used for precaching the next page for better UX.
  ///
  /// [cachedMetadataHtml] - Optional metadata from current page to reuse
  Future<void> preloadPage(
    int bookId,
    int pageNum, {
    String? cachedMetadataHtml,
  }) async {
    try {
      await contentService.preloadPage(
        bookId,
        pageNum,
        cachedMetadataHtml: cachedMetadataHtml,
      );
    } catch (e) {
      // Silently fail - preloading is best effort
      print('Failed to preload page $pageNum: $e');
    }
  }
}
