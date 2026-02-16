import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;
import '../../core/logger/api_logger.dart';
import '../../features/reader/models/page_data.dart';
import '../../features/reader/models/term_tooltip.dart';
import '../../features/reader/models/term_form.dart';
import '../../features/reader/models/language_sentence_settings.dart';
import '../../features/reader/services/page_cache_service.dart';
import '../../features/books/models/book.dart';
import '../../features/books/models/datatables_response.dart';
import '../../features/terms/models/term.dart';
import '../../shared/models/language.dart';
import '../../core/cache/term_cache_service.dart';
import '../../core/cache/models/term_cache_entry.dart';
import 'api_service.dart';
import 'html_parser.dart';
import 'concurrent_queue.dart';

enum ContentMode { reading, peeking, refresh }

class ContentService {
  final ApiService _apiService;
  final HtmlParser parser;
  final PageCacheService _pageCacheService;
  final TermCacheService _termCacheService;
  final ConcurrentQueue<TermParent> _parentFetchQueue;

  // 5-second cache for languages to prevent redundant API calls
  List<Language>? _cachedLanguages;
  DateTime? _languagesCacheTime;
  static const _languagesCacheTtl = Duration(seconds: 5);

  ContentService({required ApiService apiService, HtmlParser? htmlParser})
    : _apiService = apiService,
      parser = htmlParser ?? HtmlParser(),
      _pageCacheService = PageCacheService.getInstance(),
      _termCacheService = TermCacheService.getInstance(),
      _parentFetchQueue = ConcurrentQueue<TermParent>(
        maxConcurrent: 2,
        name: 'parentFetch',
      );

  bool get isConfigured => _apiService.isConfigured;

  Future<PageData?> getPageContent(
    int bookId, {
    int? pageNum,
    ContentMode mode = ContentMode.reading,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    String pageMetadataHtml;
    String pageTextHtml;

    if (useCache && !forceRefresh && pageNum != null) {
      // Cache-only mode: return cached data or null if not found
      final cached = await _pageCacheService.getFromCache(bookId, pageNum);
      if (cached != null) {
        pageMetadataHtml = cached.metadataHtml;
        pageTextHtml = cached.pageTextHtml;
      } else {
        // Cache miss - return null immediately without fetching
        return null;
      }
    } else {
      // Network mode: fetch from server and cache the result
      pageMetadataHtml = await _fetchMetadataHtml(bookId, pageNum);
      final metadataDocument = html_parser.parse(pageMetadataHtml);
      final actualPageNum =
          pageNum ?? _extractPageNumFromMetadata(metadataDocument);
      pageTextHtml = await _fetchPageTextHtml(bookId, actualPageNum, mode);

      // Always cache fresh data when we fetch it from server
      await _pageCacheService.saveToCache(
        bookId,
        actualPageNum,
        pageMetadataHtml,
        pageTextHtml,
      );
    }

    return parser.parsePage(pageTextHtml, pageMetadataHtml, bookId: bookId);
  }

  Future<String> _fetchMetadataHtml(int bookId, int? pageNum) async {
    final pageMetadataResponse = await _apiService.getBookPageStructure(
      bookId,
      pageNum,
    );
    return pageMetadataResponse.data ?? '';
  }

  Future<String> _fetchPageTextHtml(
    int bookId,
    int pageNum,
    ContentMode mode,
  ) async {
    final pageTextResponse = await _getPageHtml(bookId, pageNum, mode);
    return pageTextResponse.data ?? '';
  }

  int _extractPageNumFromMetadata(dynamic metadataDocument) {
    if (metadataDocument is! html.Document) return 1;
    final pageInput = metadataDocument.querySelector('#page_num');
    if (pageInput != null) {
      final value = pageInput.attributes['value'];
      return int.tryParse(value ?? '') ?? 1;
    }
    return 1;
  }

  Future<PageData> markPageDone(int bookId, int pageNum, bool restKnown) async {
    await _apiService.postPageDone(bookId, pageNum, restKnown);

    // Load from cache first for instant UX, then let background refresh update statuses
    final pageData = await getPageContent(
      bookId,
      pageNum: pageNum,
      mode: ContentMode.reading,
      useCache: true,
      forceRefresh: false,
    );

    if (pageData == null) {
      throw Exception('Page not found in cache after marking as done');
    }

    return pageData;
  }

  Future<void> markPageReadOnly(int bookId, int pageNum) async {
    await _apiService.postPageDone(bookId, pageNum, false);
  }

  Future<void> markPageKnownOnly(int bookId, int pageNum) async {
    await _apiService.postPageDone(bookId, pageNum, true);
  }

  /// Preloads a page by fetching it from the network and caching it.
  /// Does nothing if the page is already cached.
  /// This is used for precaching the next page for better UX.
  Future<void> preloadPage(int bookId, int pageNum) async {
    // Check if already cached - skip if it is
    final cached = await _pageCacheService.getFromCache(bookId, pageNum);
    if (cached != null) {
      ApiLogger.logCache(
        'preloadPage',
        details: 'CACHED - bookId=$bookId, page=$pageNum',
      );
      return;
    }

    // Not cached - fetch and cache it
    ApiLogger.logRequest(
      'preloadPage',
      details: 'FETCHING - bookId=$bookId, page=$pageNum',
    );

    try {
      final pageMetadataHtml = await _fetchMetadataHtml(bookId, pageNum);
      final metadataDocument = html_parser.parse(pageMetadataHtml);
      final actualPageNum = _extractPageNumFromMetadata(metadataDocument);
      final pageTextHtml = await _fetchPageTextHtml(
        bookId,
        actualPageNum,
        ContentMode.reading,
      );

      // Cache the fetched data
      await _pageCacheService.saveToCache(
        bookId,
        actualPageNum,
        pageMetadataHtml,
        pageTextHtml,
      );
    } catch (e) {
      ApiLogger.logError('preloadPage', e, details: 'pageNum=$pageNum');
    }
  }

  Future<Response<String>> _getPageHtml(
    int bookId,
    int pageNum,
    ContentMode mode,
  ) async {
    switch (mode) {
      case ContentMode.reading:
        return await _apiService.loadBookPageForReading(bookId, pageNum);
      case ContentMode.peeking:
        return await _apiService.peekBookPage(bookId, pageNum);
      case ContentMode.refresh:
        return await _apiService.refreshBookPage(bookId, pageNum);
    }
  }

  Future<TermTooltip> getTermTooltip(int termId) async {
    final response = await _apiService.getTermTooltip(termId);
    final htmlContent = response.data ?? '';
    return parser.parseTermTooltip(htmlContent);
  }

  /// Fetches a term tooltip and returns both the parsed TermTooltip object
  /// and the raw HTML string in a single API request.
  /// This is more efficient than calling getTermTooltip and getRawTermTooltipHtml
  /// separately when both are needed (e.g., during prefetching).
  Future<(TermTooltip tooltip, String html)> getTermTooltipWithHtml(
    int termId,
  ) async {
    final response = await _apiService.getTermTooltip(termId);
    final htmlContent = response.data ?? '';
    final tooltip = parser.parseTermTooltip(htmlContent);
    return (tooltip, htmlContent);
  }

  Future<String?> getRawTermTooltipHtml(int termId) async {
    try {
      final htmlContent = await _apiService.getRawTermTooltipHtml(termId);
      return htmlContent;
    } catch (e) {
      ApiLogger.logError('getRawTermTooltipHtml', e, details: 'termId=$termId');
      return null;
    }
  }

  Future<TermForm> getTermForm(int langId, String text) async {
    final response = await _apiService.getTermForm(langId, text);
    final htmlContent = response.data ?? '';
    return parser.parseTermForm(htmlContent, termId: null);
  }

  Future<TermForm> getTermFormById(int termId) async {
    final response = await _apiService.getTermFormById(termId);
    final htmlContent = response.data ?? '';
    return parser.parseTermForm(htmlContent, termId: termId);
  }

  Future<void> saveTermForm(
    int langId,
    String text,
    Map<String, dynamic> data,
  ) async {
    await _apiService.postTermForm(langId, text, data);
  }

  Future<void> editTerm(int termId, Map<String, dynamic> data) async {
    await _apiService.editTerm(termId, data);
  }

  Future<List<SearchResultTerm>> searchTerms(String text, int langId) async {
    final response = await _apiService.searchTerms(text, langId);
    final jsonString = response.data ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => SearchResultTerm.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TermForm> getTermFormWithParentDetails(int langId, String text) async {
    final termForm = await getTermForm(langId, text);
    if (termForm.parents.isEmpty) {
      return termForm;
    }

    final fetchFutures = termForm.parents.map((parent) {
      return _parentFetchQueue.enqueue(() async {
        final searchResults = await searchTerms(parent.term, langId);
        if (searchResults.isNotEmpty) {
          final result = searchResults.first;
          return TermParent(
            id: result.id,
            term: result.text,
            translation: result.translation,
            status: result.status,
            syncStatus: result.syncStatus,
          );
        }
        return parent;
      });
    }).toList();

    final parentsWithDetails = await Future.wait(fetchFutures);
    return termForm.copyWith(parents: parentsWithDetails.cast<TermParent>());
  }

  Future<TermForm> getTermFormByIdWithParentDetails(int termId) async {
    final termForm = await getTermFormById(termId);
    if (termForm.parents.isEmpty) {
      return termForm;
    }

    final fetchFutures = termForm.parents.map((parent) {
      return _parentFetchQueue.enqueue(() async {
        final searchResults = await searchTerms(
          parent.term,
          termForm.languageId,
        );
        if (searchResults.isNotEmpty) {
          final result = searchResults.first;
          return TermParent(
            id: result.id,
            term: result.text,
            translation: result.translation,
            status: result.status,
            syncStatus: result.syncStatus,
          );
        }
        return parent;
      });
    }).toList();

    final parentsWithDetails = await Future.wait(fetchFutures);
    return termForm.copyWith(parents: parentsWithDetails.cast<TermParent>());
  }

  Future<int?> createTerm(int langId, String term) async {
    try {
      final response = await _apiService.createTerm(langId, term);
      final htmlContent = response.data ?? '';

      final document = html_parser.parse(htmlContent);
      final termIdInput = document.querySelector('input[name="termid"]');

      if (termIdInput != null) {
        final id = termIdInput.attributes['value'];
        return int.tryParse(id ?? '');
      }

      return null;
    } catch (e) {
      ApiLogger.logError('createTerm', e);
      return null;
    }
  }

  Future<String> getLanguageSettingsHtml(int langId) async {
    final response = await _apiService.getLanguageSettings(langId);
    return response.data ?? '';
  }

  Future<DataTablesResponse<Book>> getActiveBooks({
    int start = 0,
    int length = 100,
    String? search,
    int draw = 1,
  }) async {
    final response = await _apiService.getActiveBooks(
      draw: draw,
      start: start,
      length: length,
      search: search,
    );

    final jsonString = response.data ?? '';
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return DataTablesResponse.fromJson(jsonData, (json) => Book.fromJson(json));
  }

  Future<DataTablesResponse<Book>> getArchivedBooks({
    int start = 0,
    int length = 100,
    String? search,
    int draw = 1,
  }) async {
    final response = await _apiService.getArchivedBooks(
      draw: draw,
      start: start,
      length: length,
      search: search,
    );

    final jsonString = response.data ?? '';
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return DataTablesResponse.fromJson(jsonData, (json) => Book.fromJson(json));
  }

  Future<List<Book>> getAllActiveBooks() async {
    final response = await getActiveBooks(start: 0, length: 10000);
    return response.data;
  }

  Future<List<Book>> getAllArchivedBooks() async {
    final response = await getArchivedBooks(start: 0, length: 10000);
    return response.data;
  }

  Future<void> refreshBookStats(int bookId, {Duration? timeout}) async {
    await _apiService.refreshBookStats(bookId, timeout: timeout);
  }

  Future<void> invalidateAllBookStatsCache() async {
    await _apiService.invalidateAllBookStatsCache();
  }

  Future<Book> getBookStats(int bookId) async {
    final response = await _apiService.getBookStats(bookId);
    final jsonString = response.data ?? '';

    try {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // The /book/table_stats/$bookId endpoint returns only stats data, not a full book object
      // Example response: {"distinctterms": 2390, "distinctunknowns": 0,
      //                   "status_distribution": "{\"0\": 0, \"1\": 1011, ...}", "unknownpercent": 0}
      // We need to create a minimal book object with just the stats data
      // This will be merged with existing book data in the repository layer

      // Parse the status distribution string into a map
      Map<String, dynamic> statusDistMap = {};
      if (jsonData['status_distribution'] != null &&
          jsonData['status_distribution'] != '') {
        try {
          statusDistMap = json.decode(jsonData['status_distribution']);
        } catch (e) {
          ApiLogger.logError('parseStatusDistribution', e);
        }
      }

      // Convert status distribution to the format expected by Book model
      List<int>? statusDistribution;
      if (statusDistMap.isNotEmpty) {
        statusDistribution = [
          statusDistMap['0'] ?? 0,
          statusDistMap['1'] ?? 0,
          statusDistMap['2'] ?? 0,
          statusDistMap['3'] ?? 0,
          statusDistMap['4'] ?? 0,
          statusDistMap['5'] ?? 0,
          statusDistMap['98'] ?? 0, // Ignored
          statusDistMap['99'] ?? 0, // Well-known
        ];
      }

      // Create a minimal book object with just the stats data
      // The other fields will be filled in by the repository layer
      return Book(
        id: bookId, // We only have the ID from the request
        title: '', // Will be filled in by repository
        language: '', // Will be filled in by repository
        langId: null, // Will be filled in by repository
        totalPages: 0, // Will be filled in by repository
        currentPage: 0, // Will be filled in by repository
        percent: 0, // Will be filled in by repository
        wordCount: 0, // Will be filled in by repository
        distinctTerms: jsonData['distinctterms'],
        unknownPct: (jsonData['unknownpercent'] is num)
            ? (jsonData['unknownpercent'] as num).toDouble()
            : null,
        statusDistribution: statusDistribution,
        tags: null, // Will be filled in by repository
        lastRead: null, // Will be filled in by repository
        isCompleted: false, // Will be filled in by repository
        audioFilename: null, // Will be filled in by repository
        lastStatsRefresh: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      ApiLogger.logError('getBookStats', e);
      rethrow;
    }
  }

  Future<void> archiveBook(int bookId) async {
    await _apiService.archiveBook(bookId);
  }

  Future<void> unarchiveBook(int bookId) async {
    await _apiService.unarchiveBook(bookId);
  }

  Future<void> deleteBook(int bookId) async {
    await _apiService.deleteBook(bookId);
  }

  Future<void> saveAudioPlayerData({
    required int bookId,
    required int page,
    required double position,
    required double duration,
    required List<double> bookmarks,
  }) async {
    await _apiService.postPlayerData(bookId, position, bookmarks);
  }

  Future<List<Language>> getLanguagesWithIds() async {
    // Check if we have a valid cached result (< 5 seconds old)
    if (_cachedLanguages != null && _languagesCacheTime != null) {
      final age = DateTime.now().difference(_languagesCacheTime!);
      if (age < _languagesCacheTtl) {
        return _cachedLanguages!;
      }
    }

    // Fetch from API and cache the result
    final response = await _apiService.getLanguages();
    final htmlContent = response.data ?? '';
    final languages = parser.parseLanguagesWithIds(htmlContent);

    _cachedLanguages = languages;
    _languagesCacheTime = DateTime.now();

    return languages;
  }

  Future<Language?> getLanguageById(int languageId) async {
    final languages = await getLanguagesWithIds();
    try {
      return languages.firstWhere((lang) => lang.id == languageId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Term>> getTermsDatatables({
    required int? langId,
    required String? search,
    required int page,
    required int pageSize,
    String? status,
    Set<String>? selectedStatuses,
  }) async {
    final response = await _apiService.getTermsDatatables(
      draw: page + 1,
      start: page * pageSize,
      length: pageSize,
      search: search,
      langId: langId,
      status: status != null ? int.tryParse(status) : null,
      selectedStatuses: selectedStatuses,
    );
    return parser.parseTermsFromDatatables(response.data ?? '');
  }

  Future<void> deleteTerm(int termId) async {
    await _apiService.deleteTerm(termId);
  }

  /// Fetches and parses all user settings from the settings page.
  /// This makes a single API call and returns a map of all settings,
  /// avoiding multiple redundant requests when different callers need
  /// different settings values.
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final response = await _apiService.getSettingsPage();
      final html = response.data ?? '';

      final match = RegExp(
        r'LUTE_USER_SETTINGS\s*=\s*(\{.*?)(?=\n\s*const LUTE_USER_HOTKEYS)',
        dotAll: true,
      ).firstMatch(html);

      if (match != null && match.groupCount >= 1) {
        final jsonStr = match.group(1)!;
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      ApiLogger.logError('getUserSettings', e);
    }
    return {};
  }

  /// Gets a single user setting value by key.
  /// Consider using [getUserSettings()] if you need multiple values
  /// to avoid redundant API calls.
  Future<String?> getUserSetting(String key) async {
    final settings = await getUserSettings();
    return settings[key]?.toString();
  }

  /// Gets the stats sample size setting.
  /// Consider using [getUserSettings()] if you need multiple values
  /// to avoid redundant API calls.
  Future<int> getStatsSampleSize() async {
    final settings = await getUserSettings();
    return int.tryParse(settings['stats_calc_sample_size']?.toString() ?? '') ??
        5;
  }

  Future<void> setUserSetting(String key, String value) async {
    await _apiService.setUserSetting(key, value);
  }

  Future<LanguageSentenceSettings> getLanguageSentenceSettings(
    int langId,
  ) async {
    try {
      final html = await getLanguageSettingsHtml(langId);

      final stopCharsMatch = RegExp(
        r'id="regexp_split_sentences"[^>]*value="([^"]*)"',
      ).firstMatch(html);
      final stopChars = stopCharsMatch?.group(1) ?? '.!?;:';

      final exceptionsMatch = RegExp(
        r'id="exceptions_split_sentences"[^>]*value="([^"]*)"',
      ).firstMatch(html);
      final exceptionsRaw = exceptionsMatch?.group(1) ?? '';
      final sentenceExceptions = exceptionsRaw
          .split('|')
          .where((w) => w.isNotEmpty)
          .toList();

      final parserMatch = RegExp(
        r'id="parser_type"[^>]*>\s*<option[^>]*value="([^"]*)"[^>]*selected',
      ).firstMatch(html);
      final parserType = parserMatch?.group(1) ?? 'spacedel';

      return LanguageSentenceSettings(
        languageId: langId,
        stopChars: stopChars,
        sentenceExceptions: sentenceExceptions,
        parserType: parserType,
      );
    } catch (e) {
      return LanguageSentenceSettings(
        languageId: langId,
        stopChars: '.!?;:',
        sentenceExceptions: [],
        parserType: 'spacedel',
      );
    }
  }

  /// Gets the current page number from the server for a book
  /// This is used to check if the server's current page matches the reader's page
  /// This uses the existing getBookPageStructure method which already calls the correct endpoint
  Future<int> getCurrentPageForBook(int bookId) async {
    try {
      final response = await _apiService.getBookPageStructure(bookId);
      final data = response.data;
      if (data != null) {
        // Parse the HTML response to extract current page
        final document = html_parser.parse(data);
        final pageInput = document.querySelector('#page_num');
        if (pageInput != null) {
          final value = pageInput.attributes['value'];
          if (value != null) {
            final pageInt = int.tryParse(value);
            if (pageInt != null) {
              return pageInt;
            }
          }
        }
      }
      return 1; // Default to page 1 if parsing fails
    } catch (e) {
      ApiLogger.logError('getCurrentPageForBook', e, details: 'bookId=$bookId');
      return 1; // Default to page 1 on error
    }
  }

  Future<Map<String, dynamic>> getStatsData() async {
    final response = await _apiService.getStatsData();
    final jsonString = response.data ?? '{}';
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return json;
  }

  Future<void> warmTermCache({int? langId}) async {
    try {
      await _termCacheService.initialize();

      int start = 0;
      const batchSize = 1000;
      bool hasMore = true;

      while (hasMore) {
        final response = await _apiService.fetchAllTerms(
          start: start,
          length: batchSize,
          langId: langId,
        );

        final jsonString = response.data ?? '{}';
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final data = json['data'] as List?;
        final recordsTotal = json['recordsTotal'] as int? ?? 0;

        if (data != null && data.isNotEmpty) {
          final terms = data
              .map(
                (t) => TermCacheEntry.fromServerJson(t as Map<String, dynamic>),
              )
              .toList();
          await _termCacheService.saveTerms(terms);
          start += batchSize;
          hasMore = start < recordsTotal;
        } else {
          hasMore = false;
        }
      }

      ApiLogger.logCache('TermCacheWarmed', details: '$start terms');
    } catch (e) {
      ApiLogger.logError('warmTermCache', e);
    }
  }

  Future<List<TermCacheEntry>> getCachedTerms() async {
    try {
      await _termCacheService.initialize();
      return await _termCacheService.getAllTerms();
    } catch (e) {
      ApiLogger.logError('getCachedTerms', e);
      return [];
    }
  }

  Future<List<TermCacheEntry>> searchCachedTerms(String query) async {
    try {
      await _termCacheService.initialize();
      return await _termCacheService.searchTerms(query);
    } catch (e) {
      ApiLogger.logError('searchCachedTerms', e, details: 'query=$query');
      return [];
    }
  }

  Future<TermCacheEntry?> getCachedTerm(int termId) async {
    try {
      await _termCacheService.initialize();
      return await _termCacheService.getTerm(termId);
    } catch (e) {
      ApiLogger.logError('getCachedTerm', e, details: 'termId=$termId');
      return null;
    }
  }

  Future<Map<String, dynamic>> getTermCacheStats() async {
    return await _termCacheService.getCacheStats();
  }

  Future<void> savePageToCache(
    int bookId,
    int pageNum,
    PageData pageData,
  ) async {
    ApiLogger.logState('savePageToCache', details: 'deprecated method called');
  }
}
