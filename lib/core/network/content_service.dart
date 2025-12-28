import 'package:dio/dio.dart';
import '../../features/reader/models/page_data.dart';
import 'api_service.dart';
import 'html_parser.dart';

enum ContentMode { reading, peeking, refresh }

class ContentService {
  final ApiService _apiService;
  final HtmlParser _htmlParser;

  ContentService({required ApiService apiService, HtmlParser? htmlParser})
    : _apiService = apiService,
      _htmlParser = htmlParser ?? HtmlParser();

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

    return _htmlParser.parsePage(
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
}
