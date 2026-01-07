import '../../../core/network/content_service.dart';
import '../models/book.dart';
import '../../../shared/models/language.dart';

class BooksRepository {
  final ContentService contentService;
  Map<String, int>? _languageNameToIdMap;

  BooksRepository({required this.contentService});

  Future<List<Book>> getActiveBooks() async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getAllActiveBooks();
      final enrichedBooks = _enrichBooksWithLanguageIds(books);
      return await _enrichBooksWithAudio(enrichedBooks);
    } catch (e) {
      throw Exception('Failed to load active books: $e');
    }
  }

  Future<List<Book>> getArchivedBooks() async {
    try {
      await _loadLanguageMapping();
      final books = await contentService.getAllArchivedBooks();
      final enrichedBooks = _enrichBooksWithLanguageIds(books);
      return await _enrichBooksWithAudio(enrichedBooks);
    } catch (e) {
      throw Exception('Failed to load archived books: $e');
    }
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
      final langId = _languageNameToIdMap![book.language];
      print(
        'DEBUG: Enriching book "${book.title}" (language: ${book.language}) with langId: $langId',
      );
      return book.copyWith(langId: langId ?? 0);
    }).toList();
  }

  Future<List<Book>> _enrichBooksWithAudio(List<Book> books) async {
    final enrichedBooks = <Book>[];
    for (final book in books) {
      final audioFilename = await contentService.getBookAudioFilename(book.id);
      enrichedBooks.add(book.copyWith(audioFilename: audioFilename));
    }
    return enrichedBooks;
  }

  Future<void> refreshBookStats(int bookId, {Duration? timeout}) async {
    try {
      await contentService.refreshBookStats(bookId, timeout: timeout);
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
