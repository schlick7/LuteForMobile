import '../../../core/network/content_service.dart';
import '../../../config/app_config.dart';
import '../models/page_data.dart';

class ReaderRepository {
  final ContentService _contentService;

  ReaderRepository({ContentService? contentService})
    : _contentService = contentService ?? ContentService();

  Future<PageData> getPage({int? bookId, int? pageNum}) async {
    final effectiveBookId = bookId ?? AppConfig.defaultBookId;
    final effectivePageNum = pageNum ?? AppConfig.defaultPageId;

    try {
      return await _contentService.getPageContent(
        effectiveBookId,
        effectivePageNum,
      );
    } catch (e) {
      throw Exception('Failed to load page: $e');
    }
  }
}
