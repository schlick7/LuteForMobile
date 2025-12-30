import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import '../../features/reader/models/page_data.dart';
import '../../features/reader/models/term_tooltip.dart';
import '../../features/reader/models/term_form.dart';
import '../../features/books/models/book.dart';
import '../../features/books/models/datatables_response.dart';
import 'api_service.dart';
import 'html_parser.dart';

enum ContentMode { reading, peeking, refresh }

class ContentService {
  final ApiService _apiService;
  final HtmlParser parser;

  ContentService({required ApiService apiService, HtmlParser? htmlParser})
    : _apiService = apiService,
      parser = htmlParser ?? HtmlParser();

  Future<PageData> getPageContent(
    int bookId,
    int pageNum, {
    ContentMode mode = ContentMode.reading,
  }) async {
    final pageTextResponse = await _getPageHtml(bookId, pageNum, mode);
    final pageTextHtml = pageTextResponse.data ?? '';

    final pageMetadataResponse = await _apiService.getBookPageMetadata(
      bookId,
      pageNum,
    );
    final pageMetadataHtml = pageMetadataResponse.data ?? '';

    return parser.parsePage(
      pageTextHtml,
      pageMetadataHtml,
      bookId: bookId,
      pageNum: pageNum,
    );
  }

  Future<PageData> markPageDone(int bookId, int pageNum, bool restKnown) async {
    await _apiService.postPageDone(bookId, pageNum, restKnown);

    return getPageContent(bookId, pageNum, mode: ContentMode.reading);
  }

  Future<Response<String>> _getPageHtml(
    int bookId,
    int pageNum,
    ContentMode mode,
  ) async {
    switch (mode) {
      case ContentMode.reading:
        return await _apiService.getBookPage(bookId, pageNum);
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
    final parentsWithDetails = <TermParent>[];
    for (final parent in termForm.parents) {
      final searchResults = await searchTerms(parent.term, langId);
      if (searchResults.isNotEmpty) {
        final result = searchResults.first;
        parentsWithDetails.add(
          TermParent(
            id: result.id,
            term: result.text,
            translation: result.translation,
            status: result.status,
            syncStatus: result.syncStatus,
          ),
        );
      } else {
        parentsWithDetails.add(parent);
      }
    }
    return termForm.copyWith(parents: parentsWithDetails);
  }

  Future<TermForm> getTermFormByIdWithParentDetails(int termId) async {
    final termForm = await getTermFormById(termId);
    if (termForm.parents.isEmpty) {
      return termForm;
    }
    final parentsWithDetails = <TermParent>[];
    for (final parent in termForm.parents) {
      final searchResults = await searchTerms(parent.term, termForm.languageId);
      if (searchResults.isNotEmpty) {
        final result = searchResults.first;
        parentsWithDetails.add(
          TermParent(
            id: result.id,
            term: result.text,
            translation: result.translation,
            status: result.status,
            syncStatus: result.syncStatus,
          ),
        );
      } else {
        parentsWithDetails.add(parent);
      }
    }
    return termForm.copyWith(parents: parentsWithDetails);
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
      print('Error creating term: $e');
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

  Future<void> refreshBookStats(int bookId) async {
    await _apiService.refreshBookStats(bookId);
  }
}
