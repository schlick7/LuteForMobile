import '../../../core/network/content_service.dart';
import '../models/page_data.dart';

class ReaderRepository {
  final ContentService _contentService;
  final int defaultBookId;
  final int defaultPageId;

  ReaderRepository({
    required ContentService contentService,
    this.defaultBookId = 18,
    this.defaultPageId = 1,
  }) : _contentService = contentService;

  Future<PageData> getPage({int? bookId, int? pageNum}) async {
    final effectiveBookId = bookId ?? defaultBookId;
    final effectivePageNum = pageNum ?? defaultPageId;

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
