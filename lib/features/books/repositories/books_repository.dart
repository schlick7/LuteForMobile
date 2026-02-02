import '../../../core/network/content_service.dart';
import '../models/book.dart';
import '../../../core/cache/books_cache_service.dart';

class BooksRepository {
  final ContentService contentService;
  final BooksCacheService _cacheService;
  Map<String, int>? _languageNameToIdMap;

  BooksRepository({required this.contentService})
    : _cacheService = BooksCacheService.getInstance();

  Future<List<Book>> getActiveBooks() async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getAllActiveBooks();
      return _enrichBooksWithLanguageIds(books);
    } catch (e) {
      throw Exception('Failed to load active books: $e');
    }
  }

  Future<List<Book>> getArchivedBooks() async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getAllArchivedBooks();
      return _enrichBooksWithLanguageIds(books);
    } catch (e) {
      throw Exception('Failed to load archived books: $e');
    }
  }

  Future<List<Book>?> getActiveBooksFromCache() async {
    return await _cacheService.getActiveBooks();
  }

  Future<List<Book>?> getArchivedBooksFromCache() async {
    return await _cacheService.getArchivedBooks();
  }

  Future<void> saveBooksToCache({
    required List<Book> activeBooks,
    required List<Book> archivedBooks,
  }) async {
    await _cacheService.saveBooks(
      activeBooks: activeBooks,
      archivedBooks: archivedBooks,
    );
  }

  Future<void> invalidateLanguageCache(String langName) async {
    await _cacheService.invalidateLanguage(langName);
  }

  Future<void> _loadLanguageMapping() async {
    if (_languageNameToIdMap != null) return;

    try {
      final languages = await contentService.getLanguagesWithIds();
      _languageNameToIdMap = {for (var lang in languages) lang.name: lang.id};
      print(
        'DEBUG: Loaded ${languages.length} languages: $_languageNameToIdMap',
      );
    } catch (e) {
      print('Failed to load language mapping: $e');
      _languageNameToIdMap = {};
    }
  }

  List<Book> _enrichBooksWithLanguageIds(List<Book> books) {
    if (_languageNameToIdMap == null) return books;

    return books.map((book) {
      if (book.langId != null) return book;
      final langId = _languageNameToIdMap![book.language];
      print(
        'DEBUG: Enriching book "${book.title}" (language: ${book.language}) with langId: $langId',
      );
      return book.copyWith(langId: langId ?? 0);
    }).toList();
  }

  Future<void> refreshBookStats(int bookId, {Duration? timeout}) async {
    try {
      await contentService.refreshBookStats(bookId, timeout: timeout);
    } catch (e) {
      throw Exception('Failed to refresh book stats: $e');
    }
  }

  Future<void> invalidateAllBookStatsCache() async {
    try {
      await contentService.invalidateAllBookStatsCache();
    } catch (e) {
      throw Exception('Failed to invalidate all book stats cache: $e');
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
