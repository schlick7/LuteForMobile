import 'package:dio/dio.dart';
import '../../config/app_config.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.serverUrl,
              connectTimeout: AppConfig.defaultTimeout,
              receiveTimeout: AppConfig.defaultTimeout,
              headers: {'Content-Type': 'text/html'},
            ),
          ) {
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
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

  Future<Response<String>> getTermPopup(int termId) async {
    return await _dio.get<String>('/read/termpopup/$termId');
  }

  Future<Response<String>> getTermForm(int langId, String text) async {
    final encodedText = Uri.encodeComponent(text);
    return await _dio.get<String>('/read/termform/$langId/$encodedText');
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
    );
  }

  Future<Response<String>> editTerm(int termId, dynamic data) async {
    return await _dio.post<String>('/read/edit_term/$termId', data: data);
  }

  Future<Response<String>> getActiveBooks() async {
    return await _dio.get<String>('/book/datatables/active');
  }

  Future<Response<String>> getBookStats(int bookId) async {
    return await _dio.get<String>('/book/table_stats/$bookId');
  }
}
