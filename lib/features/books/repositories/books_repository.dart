import '../../../core/network/content_service.dart';
import '../models/book.dart';

class BooksRepository {
  final ContentService contentService;

  BooksRepository({required this.contentService});

  Future<List<Book>> getActiveBooks() async {
    try {
      return await contentService.getAllActiveBooks();
    } catch (e) {
      throw Exception('Failed to load active books: $e');
    }
  }

  Future<List<Book>> getArchivedBooks() async {
    try {
      return await contentService.getAllArchivedBooks();
    } catch (e) {
      throw Exception('Failed to load archived books: $e');
    }
  }
}
