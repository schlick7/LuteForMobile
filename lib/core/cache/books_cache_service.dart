import 'dart:async';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../features/books/models/book.dart';
import '../../features/books/models/book_cache_entry.dart';

class BooksCacheService {
  static const String _boxName = 'books_cache';
  static const Duration _activeBooksTtl = Duration(days: 7);
  static const Duration _archivedBooksTtl = Duration(days: 14);

  Box<BookCacheEntry>? _box;
  bool _isInitialized = false;

  static BooksCacheService? _instance;

  static BooksCacheService getInstance() {
    _instance ??= BooksCacheService._internal();
    return _instance!;
  }

  BooksCacheService._internal();

  factory BooksCacheService() {
    return getInstance();
  }

  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        await Hive.initFlutter();

        _box = await Hive.openBox<BookCacheEntry>(_boxName);

        await _cleanupExpiredEntries();

        _isInitialized = true;
        print('Books cache initialized successfully');
      } else {
        print('Books cache already initialized');
      }
    } catch (e) {
      print('Error initializing books cache: $e');
      rethrow;
    }
  }

  Future<List<Book>?> getActiveBooks() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        print('Warning: Books cache not initialized');
        return null;
      }

      final entry = _box!.get('books_data');
      if (entry == null) {
        return null;
      }

      if (entry.isExpired(_activeBooksTtl)) {
        await _box!.delete('books_data');
        return null;
      }

      return entry.activeBooks;
    } catch (e) {
      print('Error getting active books from cache: $e');
      return null;
    }
  }

  Future<List<Book>?> getArchivedBooks() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        print('Warning: Books cache not initialized');
        return null;
      }

      final entry = _box!.get('books_data');
      if (entry == null) {
        return null;
      }

      if (entry.isExpired(_archivedBooksTtl)) {
        await _box!.delete('books_data');
        return null;
      }

      return entry.archivedBooks;
    } catch (e) {
      print('Error getting archived books from cache: $e');
      return null;
    }
  }

  Future<void> saveBooks({
    required List<Book> activeBooks,
    required List<Book> archivedBooks,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        print('Warning: Books cache not initialized');
        return;
      }

      final entry = BookCacheEntry(
        activeBooks: activeBooks,
        archivedBooks: archivedBooks,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _box!.put('books_data', entry);
      print(
        'Saved ${activeBooks.length} active and ${archivedBooks.length} archived books to cache',
      );
    } catch (e) {
      print('Error saving books to cache: $e');
    }
  }

  Future<void> invalidateLanguage(String langName) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        print('Warning: Books cache not initialized');
        return;
      }

      final entry = _box!.get('books_data');
      if (entry == null) {
        return;
      }

      final updatedActiveBooks = entry.activeBooks
          .where((book) => book.language != langName)
          .toList();

      final updatedArchivedBooks = entry.archivedBooks
          .where((book) => book.language != langName)
          .toList();

      if (updatedActiveBooks.length != entry.activeBooks.length ||
          updatedArchivedBooks.length != entry.archivedBooks.length) {
        final newEntry = BookCacheEntry(
          activeBooks: updatedActiveBooks,
          archivedBooks: updatedArchivedBooks,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        await _box!.put('books_data', newEntry);
        print('Invalidated books for language: $langName');
      }
    } catch (e) {
      print('Error invalidating language cache: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        print('Warning: Books cache not initialized');
        return;
      }

      await _box!.clear();
      print('Books cache cleared successfully');
    } catch (e) {
      print('Error clearing books cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_box == null) {
        return {'error': 'Cache not initialized'};
      }

      final entry = _box!.get('books_data');
      if (entry == null) {
        return {
          'hasEntry': false,
          'activeBooksCount': 0,
          'archivedBooksCount': 0,
        };
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final activeAge = now - entry.timestamp;
      final archivedAge = now - entry.timestamp;

      return {
        'hasEntry': true,
        'activeBooksCount': entry.activeBooks.length,
        'archivedBooksCount': entry.archivedBooks.length,
        'timestamp': entry.timestamp,
        'activeAgeMs': activeAge,
        'archivedAgeMs': archivedAge,
        'activeTtlDays': _activeBooksTtl.inDays,
        'archivedTtlDays': _archivedBooksTtl.inDays,
        'isActiveExpired': activeAge > _activeBooksTtl.inMilliseconds,
        'isArchivedExpired': archivedAge > _archivedBooksTtl.inMilliseconds,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    try {
      if (_box == null) return;

      final entry = _box!.get('books_data');
      if (entry == null) return;

      final isActiveExpired = entry.isExpired(_activeBooksTtl);
      final isArchivedExpired = entry.isExpired(_archivedBooksTtl);

      if (isActiveExpired && isArchivedExpired) {
        await _box!.delete('books_data');
        print('Cleaned up expired books cache entry');
      }
    } catch (e) {
      print('Error cleaning up expired entries: $e');
    }
  }

  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
      _isInitialized = false;
    } catch (e) {
      print('Error closing books cache: $e');
    }
  }
}
