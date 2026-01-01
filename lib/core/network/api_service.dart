import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService({required String baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'text/html'},
            ),
          ) {
    if (baseUrl.isEmpty) {
      throw Exception(
        'Server URL is not configured. Please set your server URL in settings.',
      );
    }
  }

  Future<Response<String>> getBookPage(int bookId, int pageNum) async {
    return await _dio.get<String>('/read/start_reading/$bookId/$pageNum');
  }

  Future<Response<String>> getBookPageRead(int bookId, int pageNum) async {
    return await _dio.get<String>('/read/$bookId/page/$pageNum');
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

  Future<Response<String>> getBookPageMetadata(int bookId, int pageNum) async {
    return await _dio.get<String>('/read/$bookId/page/$pageNum');
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
