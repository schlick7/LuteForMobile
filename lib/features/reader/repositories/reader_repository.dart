import '../../../core/network/api_client.dart';
import '../../../core/network/html_parser.dart';
import '../../../config/app_config.dart';
import '../models/page_data.dart';

class ReaderRepository {
  final ApiClient _apiClient;
  final HtmlParser _htmlParser;

  ReaderRepository({ApiClient? apiClient, HtmlParser? htmlParser})
    : _apiClient = apiClient ?? ApiClient(),
      _htmlParser = htmlParser ?? HtmlParser();

  Future<PageData> getPage({int? bookId, int? pageNum}) async {
    final effectiveBookId = bookId ?? AppConfig.defaultBookId;
    final effectivePageNum = pageNum ?? AppConfig.defaultPageId;

    final path = '/read/start_reading/$effectiveBookId/$effectivePageNum';

    try {
      final response = await _apiClient.get(path);
      final htmlContent = response.data ?? '';

      return _htmlParser.parsePage(
        htmlContent,
        effectiveBookId,
        effectivePageNum,
      );
    } catch (e) {
      throw Exception('Failed to load page: $e');
    }
  }
}
