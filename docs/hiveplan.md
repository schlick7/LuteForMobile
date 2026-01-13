# Hive Migration Plan

## Overview

Switch `PageCacheService` and `SentenceCacheService` from SharedPreferences (JSON) to Hive CE for more efficient HTML caching. Also increase tooltip cache TTL from 48 hours to 14 days.

## TTL Summary

| Cache | Old TTL | New TTL | Max Size |
|-------|---------|---------|----------|
| Page | 24 hours | 14 days | 100MB |
| Sentence | 7 days | 14 days | 100MB |
| Tooltip | 48 hours | 14 days | 200MB |

## Cache Key Format

### Page Cache
- **Old**: `page_cache_{serverHash}_{bookId}_{pageNum}`
- **New**: Same (serverUrl already added in previous change)

### Sentence Cache
- **Old**: `sentence_cache_{bookId}_{pageNum}_{langId}_{threshold}`
- **New**: `sentence_cache_{serverHash}_{bookId}_{pageNum}_{langId}_{threshold}`

## Implementation Steps

### Step 1: Create Model Files

**`lib/features/reader/models/page_cache_entry.dart`** (new)
```dart
import 'package:hive_ce/hive.dart';

@HiveType(typeId: 2)
class PageCacheEntry extends HiveObject {
  @HiveField(0) String metadataHtml;
  @HiveField(1) String pageTextHtml;
  @HiveField(2) int timestamp;
  @HiveField(3) int sizeInBytes;
}
```

**`lib/features/reader/models/sentence_cache_entry.dart`** (new)
```dart
import 'package:hive_ce/hive.dart';
import '../models/paragraph.dart';

@HiveType(typeId: 3)
class SentenceCacheEntry extends HiveObject {
  @HiveField(0) List<CustomSentence> sentences;
  @HiveField(1) int timestamp;
  @HiveField(2) int sizeInBytes;
}
```

### Step 2: Rewrite PageCacheService

**`lib/features/reader/services/page_cache_service.dart`**

Key changes:
- Remove SharedPreferences, use Hive CE
- Add Hive box initialization (lazy)
- Add size tracking and 100MB LRU eviction
- Add serverUrl to cache key
- 14-day TTL
- Update `getCacheStats()` to return size-based stats

### Step 3: Rewrite SentenceCacheService

**`lib/features/reader/services/sentence_cache_service.dart`**

Key changes:
- Remove SharedPreferences, use Hive CE
- Add Hive box initialization (lazy)
- Add serverUrl to cache key
- Add size tracking and 100MB LRU eviction
- 14-day TTL
- Update `getCacheStats()` to return size-based stats

### Step 4: Register Hive Adapters

**`lib/hive_registrar.g.dart`** (auto-generated, run `flutter pub run build_runner build`)

Add registrations:
```dart
Hive.registerAdapter(PageCacheEntryAdapter());
Hive.registerAdapter(SentenceCacheEntryAdapter());
```

### Step 5: Update Tooltip Cache TTL

**`lib/core/cache/tooltip_cache_service.dart`**
```dart
static const Duration _ttl = Duration(days: 14); // was 48 hours
```

### Step 6: Update Callers

**`lib/features/reader/providers/reader_provider.dart`**
```dart
Future<void> clearPageCacheForBook(String serverUrl, int bookId) async {
  final cacheService = PageCacheService();
  await cacheService.clearBookCache(serverUrl, bookId);
}
```

**`lib/features/reader/providers/sentence_reader_provider.dart`**
- Add serverUrl parameter to `clearBookCache` calls

### Step 7: Cleanup

- Remove `CachedPageHtml` class
- Remove SharedPreferences imports from cache service files
- Remove `_lruKey` LRU list (Hive handles eviction)
- Clear SharedPreferences cache on first run

## Files Modified

| File | Action |
|------|--------|
| `lib/features/reader/models/page_cache_entry.dart` | Create |
| `lib/features/reader/models/sentence_cache_entry.dart` | Create |
| `lib/features/reader/services/page_cache_service.dart` | Rewrite |
| `lib/features/reader/services/sentence_cache_service.dart` | Rewrite |
| `lib/core/cache/tooltip_cache_service.dart` | Modify TTL |
| `lib/hive_registrar.g.dart` | Regenerate |
| `lib/features/reader/providers/reader_provider.dart` | Update signature |
| `lib/features/reader/providers/sentence_reader_provider.dart` | Add serverUrl |

## Migration

- On first run after migration, clear SharedPreferences cache entries
- No data migration from SharedPreferences to Hive (just clear it)
- Old cache entries will be orphaned and cleaned up naturally

## Estimated Cache Sizes

### Page Cache
- Typical page: 15KB-55KB HTML
- At 100MB: ~1800-6600 pages cached
- At 500 pages: ~7.5MB-27.5MB

### Sentence Cache
- Varies by book length and sentence threshold
- Size depends on language and parsing settings

## Testing Checklist

- [ ] Page cache stores and retrieves correctly
- [ ] Page cache respects 100MB limit with LRU eviction
- [ ] Page cache respects 14-day TTL
- [ ] Sentence cache stores and retrieves correctly
- [ ] Sentence cache respects 100MB limit with LRU eviction
- [ ] Sentence cache respects 14-day TTL
- [ ] Cache keys include serverUrl (prevents cross-server contamination)
- [ ] Tooltip cache TTL increased to 14 days
- [ ] Old SharedPreferences cache is cleared on first run
- [ ] Cache stats show correct size and entry counts
- [ ] Clearing book cache removes only that book's entries
- [ ] Clearing all cache removes all entries
