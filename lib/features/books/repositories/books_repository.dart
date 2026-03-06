import '../../../core/network/content_service.dart';
import '../models/book.dart';
import '../models/book_create.dart';
import '../../../core/cache/books_cache_service.dart';

class BooksRepository {
  final ContentService contentService;
  final BooksCacheService _cacheService;
  Map<String, int>? _languageNameToIdMap;

  BooksRepository({
    required this.contentService,
    required BooksCacheService cacheService,
  }) : _cacheService = cacheService;

  void resetLanguageMap() {
    _languageNameToIdMap = null;
  }

  Future<List<Book>> getActiveBooks({
    int page = 0,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getActiveBooks(
        start: page * pageSize,
        length: pageSize,
        search: search,
      );
      return _enrichBooksWithLanguageIds(books.data);
    } catch (e) {
      throw Exception('Failed to load active books: $e');
    }
  }

  Future<List<Book>> getArchivedBooks({
    int page = 0,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getArchivedBooks(
        start: page * pageSize,
        length: pageSize,
        search: search,
      );
      return _enrichBooksWithLanguageIds(books.data);
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
      return book.copyWith(langId: langId ?? 0);
    }).toList();
  }

  Future<void> invalidateAllBookStatsCache({Duration? timeout}) async {
    try {
      await contentService.invalidateAllBookStatsCache(timeout: timeout);
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

  Future<BookImportPreview> previewBookImportFromUrl(String importUrl) async {
    try {
      return await contentService.previewBookImportFromUrl(importUrl);
    } catch (e) {
      throw Exception('Failed to import from URL: $e');
    }
  }

  Future<int> createBook(BookCreateRequest request) async {
    try {
      return await contentService.createBook(request);
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  Future<BookEditFormData> getBookEditForm(int bookId) async {
    try {
      return await contentService.getBookEditForm(bookId);
    } catch (e) {
      throw Exception('Failed to load book edit form: $e');
    }
  }

  Future<void> editBook(BookEditRequest request) async {
    try {
      await contentService.editBook(request);
    } catch (e) {
      throw Exception('Failed to edit book: $e');
    }
  }
}
