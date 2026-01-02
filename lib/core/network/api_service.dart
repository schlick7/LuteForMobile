import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

class ApiService {
  final Dio _dio;

  ApiService({required String baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'text/html'},
            ),
          ) {
    _addRetryInterceptor();
  }

  void _addRetryInterceptor() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
            if (retryCount < 3) {
              error.requestOptions.extra['retryCount'] = retryCount + 1;
              // Exponential backoff with reasonable delays
              final delay = Duration(milliseconds: 500 * (1 << retryCount));
              await Future.delayed(delay);
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                print('Retry attempt ${retryCount + 1} failed: $e');
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return true;
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return true;
    }
    if (error.type == DioExceptionType.unknown &&
        error.error?.toString().contains('errno=103') == true) {
      return true;
    }
    if (error.type == DioExceptionType.unknown &&
        error.error?.toString().contains('Connection reset') == true) {
      return true;
    }
    if (error.type == DioExceptionType.unknown &&
        error.error?.toString().contains('Software caused connection abort') ==
            true) {
      return true;
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    if (error.type == DioExceptionType.cancel) {
      // Sometimes requests get cancelled during app transitions
      return true;
    }
    return false;
  }

  bool get isConfigured => _dio.options.baseUrl.isNotEmpty;

  /// Loads a book page for active reading session.
  ///
  /// This method fetches the HTML content for a specific page and starts
  /// tracking the reading session by setting a start date. Use this when
  /// the user begins reading a new page or navigates to another page.
  ///
  /// Parameters:
  /// - [bookId]: The ID of the book to read from
  /// - [pageNum]: The page number to load
  ///
  /// Returns: HTML response containing the parsed page content with
  /// reading session tracking initialized
  ///
  /// See also:
  /// - [getBookPageStructure] - to get full HTML page with metadata
  /// - [peekBookPage] - to view a page without tracking
  /// - [refreshBookPage] - to reload current page without changing start date
  Future<Response<String>> loadBookPageForReading(
    int bookId,
    int pageNum,
  ) async {
    return await _dio.get<String>('/read/start_reading/$bookId/$pageNum');
  }

  Future<Response<String>> peekBookPage(int bookId, int pageNum) async {
    return await _dio.get<String>('/read/$bookId/peek/$pageNum');
  }

  Future<Response<String>> refreshBookPage(int bookId, int pageNum) async {
    return await _dio.get<String>('/read/refresh_page/$bookId/$pageNum');
  }

  Future<Response<String>> postPageDone(
    int bookId,
    int pageNum,
    bool restKnown,
  ) async {
    return await _dio.post<String>(
      '/read/page_done',
      data: {
        'bookid': bookId,
        'pagenum': pageNum,
        'restknown': restKnown ? 1 : 0,
      },
    );
  }

  Future<Response<String>> markPageRead(int bookId, int pageNum) async {
    return await postPageDone(bookId, pageNum, false);
  }

  Future<Response<String>> markPageKnown(int bookId, int pageNum) async {
    return await postPageDone(bookId, pageNum, true);
  }

  Future<Response<String>> getTermTooltip(int termId) async {
    final url = '/read/termpopup/$termId';
    print('DEBUG ApiService.getTermTooltip: Calling GET $url');
    return await _dio.get<String>(url);
  }

  Future<Response<String>> getTermForm(int langId, String text) async {
    final encodedText = Uri.encodeComponent(text);
    return await _dio.get<String>('/read/termform/$langId/$encodedText');
  }

  Future<Response<String>> getTermFormById(int termId) async {
    return await _dio.get<String>('/read/edit_term/$termId');
  }

  Future<Response<String>> postTermForm(
    int langId,
    String text,
    dynamic data,
  ) async {
    final encodedText = Uri.encodeComponent(text);
    return await _dio.post<String>(
      '/read/termform/$langId/$encodedText',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response<String>> editTerm(int termId, dynamic data) async {
    return await _dio.post<String>(
      '/read/edit_term/$termId',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response<String>> getActiveBooks({
    int draw = 1,
    int start = 0,
    int length = 100,
    String? search,
  }) async {
    final data = {
      'draw': draw,
      'start': start,
      'length': length,
      'columns[0][data]': '0',
      'columns[0][name]': 'BkTitle',
      'columns[0][searchable]': 'true',
      'columns[0][orderable]': 'true',
      'columns[0][search][value]': '',
      'columns[0][search][regex]': 'false',
      'columns[1][data]': '1',
      'columns[1][name]': 'LgName',
      'columns[1][searchable]': 'true',
      'columns[1][orderable]': 'true',
      'columns[1][search][value]': '',
      'columns[1][search][regex]': 'false',
      'columns[2][data]': '2',
      'columns[2][name]': 'TagList',
      'columns[2][searchable]': 'true',
      'columns[2][orderable]': 'true',
      'columns[2][search][value]': '',
      'columns[2][search][regex]': 'false',
      'columns[3][data]': '3',
      'columns[3][name]': 'WordCount',
      'columns[3][searchable]': 'true',
      'columns[3][orderable]': 'true',
      'columns[3][search][value]': '',
      'columns[3][search][regex]': 'false',
      'columns[4][data]': '4',
      'columns[4][name]': 'UnknownPercent',
      'columns[4][searchable]': 'false',
      'columns[4][orderable]': 'true',
      'columns[4][search][value]': '',
      'columns[4][search][regex]': 'false',
      'columns[5][data]': '5',
      'columns[5][name]': 'LastOpenedDate',
      'columns[5][searchable]': 'false',
      'columns[5][orderable]': 'true',
      'columns[5][search][value]': '',
      'columns[5][search][regex]': 'false',
      'search[value]': search ?? '',
      'search[regex]': 'false',
    };

    return await _dio.post<String>(
      '/book/datatables/active',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response<String>> getArchivedBooks({
    int draw = 1,
    int start = 0,
    int length = 100,
    String? search,
  }) async {
    final data = {
      'draw': draw,
      'start': start,
      'length': length,
      'columns[0][data]': '0',
      'columns[0][name]': 'BkTitle',
      'columns[0][searchable]': 'true',
      'columns[0][orderable]': 'true',
      'columns[0][search][value]': '',
      'columns[0][search][regex]': 'false',
      'columns[1][data]': '1',
      'columns[1][name]': 'LgName',
      'columns[1][searchable]': 'true',
      'columns[1][orderable]': 'true',
      'columns[1][search][value]': '',
      'columns[1][search][regex]': 'false',
      'columns[2][data]': '2',
      'columns[2][name]': 'TagList',
      'columns[2][searchable]': 'true',
      'columns[2][orderable]': 'true',
      'columns[2][search][value]': '',
      'columns[2][search][regex]': 'false',
      'columns[3][data]': '3',
      'columns[3][name]': 'WordCount',
      'columns[3][searchable]': 'true',
      'columns[3][orderable]': 'true',
      'columns[3][search][value]': '',
      'columns[3][search][regex]': 'false',
      'columns[4][data]': '4',
      'columns[4][name]': 'UnknownPercent',
      'columns[4][searchable]': 'false',
      'columns[4][orderable]': 'true',
      'columns[4][search][value]': '',
      'columns[4][search][regex]': 'false',
      'columns[5][data]': '5',
      'columns[5][name]': 'LastOpenedDate',
      'columns[5][searchable]': 'false',
      'columns[5][orderable]': 'true',
      'columns[5][search][value]': '',
      'columns[5][search][regex]': 'false',
      'search[value]': search ?? '',
      'search[regex]': 'false',
    };

    return await _dio.post<String>(
      '/book/datatables/Archived',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response<String>> getBookStats(int bookId) async {
    return await _dio.get<String>('/book/table_stats/$bookId');
  }

  /// Gets full HTML page structure for a book page.
  ///
  /// This method fetches the complete HTML page including metadata
  /// like title, page count, audio settings, and navigation elements.
  /// The text content placeholder (`<div id="thetext">`) will be empty.
  ///
  /// Use this to extract metadata (title, page count, audio info).
  /// Use [loadBookPageForReading] to get actual parsed text content.
  ///
  /// Parameters:
  /// - [bookId]: The ID of the book
  /// - [pageNum]: The page number (or leave out to get current page)
  ///
  /// Returns: Full HTML page structure with metadata elements
  ///
  /// See also:
  /// - [loadBookPageForReading] - to get actual page text content
  Future<Response<String>> getBookPageStructure(
    int bookId, [
    int? pageNum,
  ]) async {
    final path = pageNum != null
        ? '/read/$bookId/page/$pageNum'
        : '/read/$bookId';
    return await _dio.get<String>(path);
  }

  Future<Response<String>> searchTerms(String text, int langId) async {
    final encodedText = Uri.encodeComponent(text);
    return await _dio.get<String>('/term/search/$encodedText/$langId');
  }

  Future<Response<String>> createTerm(int langId, String term) async {
    final encodedTerm = Uri.encodeComponent(term);
    return await _dio.post<String>(
      '/read/termform/$langId/$encodedTerm',
      data: {'text': term},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response<String>> getLanguageSettings(int langId) async {
    return await _dio.get<String>('/language/edit/$langId');
  }

  Future<Response<String>> getLanguages() async {
    return await _dio.get<String>('/language/index');
  }

  Future<Response<String>> refreshBookStats(int bookId) async {
    return await _dio.get<String>('/book/table_stats/$bookId');
  }

  Future<Response<String>> archiveBook(int bookId) async {
    return await _dio.post<String>('/book/archive/$bookId');
  }

  Future<Response<String>> unarchiveBook(int bookId) async {
    return await _dio.post<String>('/book/unarchive/$bookId');
  }

  Future<Response<String>> deleteBook(int bookId) async {
    return await _dio.post<String>('/book/delete/$bookId');
  }

  Future<Response<String>> getBookEdit(int bookId) async {
    return await _dio.get<String>('/book/edit/$bookId');
  }

  Future<Response<String>> postPlayerData(
    int bookId,
    double position,
    List<double> bookmarks,
  ) async {
    final bookmarksString = jsonEncode(bookmarks);
    return await _dio.post<String>(
      '/read/save_player_data',
      data: {
        'bookid': bookId,
        'position': position,
        'bookmarks': bookmarksString,
      },
      options: Options(contentType: 'application/json'),
    );
  }
}
