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

  Future<void> refreshBookStats(int bookId) async {
    try {
      await contentService.refreshBookStats(bookId);
    } catch (e) {
      throw Exception('Failed to refresh book stats: $e');
    }
  }

  Future<void> refreshAllBookStats(List<Book> books) async {
    for (final book in books) {
      if (!book.hasStats) {
        try {
          await refreshBookStats(book.id);
        } catch (e) {
          print('Failed to refresh stats for book ${book.id}: $e');
        }
      }
    }
  }

  Future<void> archiveBook(int bookId) async {
    try {
      await contentService.archiveBook(bookId);
    } catch (e) {
      throw Exception('Failed to archive book: $e');
    }
  }

  Future<void> unarchiveBook(int bookId) async {
    try {
      await contentService.unarchiveBook(bookId);
    } catch (e) {
      throw Exception('Failed to unarchive book: $e');
    }
  }

  Future<void> deleteBook(int bookId) async {
    try {
      await contentService.deleteBook(bookId);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }
}
