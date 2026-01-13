# BooksCache Implementation Plan

## Overview

Implement Hive-based caching for the BooksScreen to improve load times and provide a better user experience. The caching follows a **stale-while-revalidate** pattern: show cached data instantly, then silently refresh from the API in the background.

## Caching Strategy by Data Type

| Data | Cache Duration | Update Pattern |
|------|---------------|----------------|
| **Book list metadata** (title, language, pages, etc.) | 7 days | Background refresh on each BooksScreen visit |
| **Term stats** (distinctTerms, statusDistribution, etc.) | 7 days | Background refresh on each BooksScreen visit |
| **Book page content** | Already cached via PageCacheService | LRU, 24-hour TTL |

## Data Flow

```
BooksScreen opens
    ↓
Load books from cache → Display immediately
    ↓
Background: Fetch fresh stats from API
    ↓
[If API succeeds]
    → Save fresh data to cache
    → Update UI silently
[If API fails]
    → Keep cached data as-is
    → No UI update, no cache deletion
```

## Cache Invalidation Logic

**Trigger: User finishes reading a book**

1. Identify book's language
2. Fetch fresh stats for ALL books in that language
3. On success: Update cache entries for all books in language
4. On failure: Do nothing, keep existing cache valid

## BooksCacheService API

```dart
class BooksCacheService {
  // Singleton
  static BooksCacheService getInstance();

  // Initialization
  Future<void> initialize();

  // Active books
  Future<List<Book>?> getActiveBooks();
  Future<void> saveActiveBooks(List<Book> books);

  // Archived books
  Future<List<Book>?> getArchivedBooks();
  Future<void> saveArchivedBooks(List<Book> books);

  // Language-based invalidation
  Future<void> invalidateLanguage(String langName);

  // Cache management
  Future<void> clearAll();
  Future<Map<String, dynamic>> getCacheStats();
}
```

## TTL Settings

| Cache Type | TTL | Rationale |
|------------|-----|-----------|
| Active books | 7 days | Reading progress changes slowly |
| Archived books | 14 days | Even less likely to change |
| Per-book stats | 7 days | Main use case |

**Cache behavior:**
- Cache validity: 7 days (configurable per language)
- Cache never deleted on failure: Only updated on successful fetch
- Cache deleted only: On successful refresh or manual clear

## Pull-to-Refresh Behavior

- On pull: Fetch fresh data, update cache on success
- If network fails: Show "Refresh failed" toast, keep cache intact

## Files to Create/Modify

### New Files
- `lib/features/books/models/book_cache_entry.dart` - Hive model for cached books
- `lib/core/cache/books_cache_service.dart` - Cache service implementation

### Modified Files
- `lib/hive_registrar.g.dart` - Add BookCacheEntryAdapter (typeId: 2)
- `lib/main.dart` - Initialize BooksCacheService
- `lib/features/books/repositories/books_repository.dart` - Integrate caching layer
- `lib/features/books/providers/books_provider.dart` - Update to use cache-first pattern

## Implementation Steps

1. Create `BookCacheEntry` model with `@HiveType(typeId: 2)`
2. Create `BooksCacheService` with singleton pattern
3. Update `hive_registrar.g.dart` to register the adapter
4. Initialize `BooksCacheService` in `main.dart`
5. Modify `BooksRepository` to check cache before network
6. Update `BooksNotifier` to emit cached data first, then background refresh
7. Add language-based cache invalidation on book read
8. Run `dart run hive_ce_generator` to generate adapter

## Box Configuration

```dart
static const String _boxName = 'books_cache';
static const Duration _activeBooksTtl = Duration(days: 7);
static const Duration _archivedBooksTtl = Duration(days: 14);
static const int _maxEntries = 1000; // Covers most libraries
```
