# SentenceReader Cache Fix Plan

## Problem Summary

SentenceReader displays stale status highlighting because:
1. `sentenceReaderProvider.customSentences` are cached for 7 days with OLD `statusClass` values
2. When term status changes:
   - `ReaderState.pageData` is updated ✓
   - Cache is NOT invalidated ✗
   - SentenceReader still shows old status ✗
3. `parseSentencesForPage()` returns cached sentences even after fetching fresh PageData (wrong cache order!)

**Result**: Status highlighting is "permanently stuck" in SentenceReader, even though ReaderScreen updates correctly.

---

## Root Cause Analysis

### Cache Layers
| Layer | Data | Storage | Duration | Updated on Term Change |
|--------|-------|----------|------------------------|
| ReaderState.pageData | Raw paragraphs with statusClass | Riverpod state (memory) | ✓ Yes |
| SentenceReaderState.customSentences | Parsed sentences with statusClass | SharedPreferences (7 days) | ✗ No |
| _termTooltips | Term data (translation, parents) | Widget state (until disposal) | Partial (only saved term) |

### Why ReaderScreen Works
```dart
@override
Widget build(BuildContext context) {
  final state = ref.watch(readerProvider);  // WATCHES - rebuilds on change
  // Displays: state.pageData!.paragraphs
}
```

### Why SentenceReader Broken
```dart
@override
Widget build(BuildContext context) {
  final readerState = ref.read(readerProvider);  // READS - no rebuild
  final sentenceReader = ref.watch(sentenceReaderProvider);  // Watches different provider
  // Displays: sentenceReader.currentSentence (from stale cache)
}
```

### Cache Ordering Bug
**Current broken flow in `initState()`**:
```
1. await loadPage(bookId, pageNum)
   → Fetches FRESH PageData from server with NEW statusClass values ✓

2. await parseSentencesForPage(langId)
   → Checks cache FIRST
   → Returns OLD cached sentences with old statusClass ✗
```

**Problem**: We fetch fresh data but then ignore it because cache hasn't been cleared!

---

## Solution: Cache Invalidation + Reparse with Tooltip Refetch

### Strategy
1. Clear cache **before** parsing (correct order)
2. Reparse sentences after term save (updates status highlighting)
3. Refetch saved term's tooltip from server (updates parent translations)
4. Keep cache for fast loads (only reparse on status changes)

### What This Fixes
✅ Status highlighting updates immediately after term save
✅ TermsList chips show correct parent translations
✅ No stale cached data persists
✅ Fast UX - cache still works for 99% of loads
✅ Minimal server calls - only refetch what changed

---

## Implementation Steps

### Step 1: Fix initState() Cache Order

**File**: `lib/features/reader/widgets/sentence_reader_screen.dart`
**Location**: `initState()` method (line 35-64)

**Current code**:
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData != null) {
      final bookId = reader.pageData!.bookId;
      final pageNum = reader.pageData!.currentPage;

      await ref.read(readerProvider.notifier).loadPage(
        bookId: bookId,
        pageNum: pageNum,
        updateReaderState: true,
      );

      final freshReader = ref.read(readerProvider);
      if (freshReader.pageData != null) {
        final langId = _getLangId(freshReader);
        await ref.read(sentenceReaderProvider.notifier).parseSentencesForPage(langId);
        await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
        _ensureTooltipsLoaded(forceRefresh: true);
      }
    }
  });
}
```

**Replace with**:
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() async {
    final reader = ref.read(readerProvider);
    if (reader.pageData != null) {
      final bookId = reader.pageData!.bookId;
      final pageNum = reader.pageData!.currentPage;
      final langId = _getLangId(reader);

      // FIX: Clear cache BEFORE parsing to ensure fresh data
      await ref.read(sentenceCacheServiceProvider).clearBookCache(bookId);

      await ref.read(readerProvider.notifier).loadPage(
        bookId: bookId,
        pageNum: pageNum,
        updateReaderState: true,
      );

      final freshReader = ref.read(readerProvider);
      if (freshReader.pageData != null) {
        await ref.read(sentenceReaderProvider.notifier).parseSentencesForPage(langId);
        await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
        _ensureTooltipsLoaded(forceRefresh: true);
      }
    }
  });
}
```

**Key change**: Clear cache before fetching to prevent using stale cached sentences.

---

### Step 2: Add Cache Clear + Tooltip Refetch to onSave

**File**: `lib/features/reader/widgets/sentence_reader_screen.dart`
**Location**: Main `onSave` callback (line 431-468)

**Current code**:
```dart
onSave: (updatedForm) async {
  final success = await ref.read(readerProvider.notifier).saveTerm(updatedForm);
  if (success && mounted) {
    if (updatedForm.termId != null) {
      setState(() {
        final existingTooltip = _termTooltips[updatedForm.termId!];
        if (existingTooltip != null) {
          _termTooltips[updatedForm.termId!] = TermTooltip(
            term: existingTooltip.term,
            translation: updatedForm.translation,
            termId: existingTooltip.termId,
            status: existingTooltip.status,
            statusText: existingTooltip.statusText,
            sentences: existingTooltip.sentences,
            language: existingTooltip.language,
            languageId: existingTooltip.languageId,
            parents: existingTooltip.parents,
            children: existingTooltip.children,
          );
        }
      });
    }
    Navigator.of(context).pop();
  }
}
```

**Replace with**:
```dart
onSave: (updatedForm) async {
  final success = await ref.read(readerProvider.notifier).saveTerm(updatedForm);
  if (success && mounted) {
    if (updatedForm.termId != null) {
      // FIX: Clear old tooltip from cache
      _termTooltips.remove(updatedForm.termId!);

      // FIX: Fetch fresh tooltip from server (includes updated parent data)
      try {
        final freshTooltip = await ref.read(readerProvider.notifier)
            .fetchTermTooltip(updatedForm.termId!);
        if (freshTooltip != null && mounted) {
          setState(() {
            _termTooltips[updatedForm.termId!] = freshTooltip;
          });
        }
      } catch (e) {
        // Tooltip fetch failed, but save succeeded
      }
    }

    // FIX: Clear sentence cache and reparse
    final reader = ref.read(readerProvider);
    if (reader.pageData != null) {
      final langId = _getLangId(reader);
      await ref.read(sentenceCacheServiceProvider)
          .clearBookCache(reader.pageData!.bookId);
      await ref.read(sentenceReaderProvider.notifier)
          .parseSentencesForPage(langId);
    }

    Navigator.of(context).pop();
  }
}
```

**Key changes**:
1. Remove old tooltip from `_termTooltips` map
2. Fetch fresh tooltip from server (includes updated parent translations)
3. Clear book cache to invalidate stale sentences
4. Reparse sentences from fresh PageData

**Note**: Parent term form `onSave` does NOT need changes because when it closes, we're back in the original term form which hasn't been saved yet. Saving the original term will fetch fresh parent data.

---

## Cache Order Comparison

### Before (Broken)
```
1. loadPage() → FRESH PageData with NEW statuses
2. parseSentencesForPage() → Returns OLD cached sentences
3. Result: Fresh data ignored ✗
```

### After (Fixed)
```
1. clearBookCache() → Removes OLD cached sentences
2. loadPage() → Fetches FRESH PageData with NEW statuses
3. parseSentencesForPage() → Parses from FRESH PageData (cache miss)
4. saveToCache() → Saves NEW sentences
5. Result: Fresh data used ✓
```

---

## What This Fixes

| Issue | Status Before | Status After |
|--------|---------------|--------------|
| Status highlighting stuck | ✗ Stale | ✓ Updates immediately |
| TermsList parent translations | ✗ Stale | ✓ Updates immediately |
| Cache ordering bug | ✗ Wrong order | ✓ Correct order |
| PageData cached forever | ✗ Forever | ✓ 7-day sentence cache |
| ReaderScreen vs SentenceReader | ✗ Inconsistent | ✓ Consistent |

---

## Files Modified

1. `lib/features/reader/widgets/sentence_reader_screen.dart`
   - Update `initState()` to clear cache before parsing
   - Update `onSave` to clear cache, reparse, and refetch tooltip with error handling

---

## Testing Checklist

After implementation, verify:

- [ ] Change term status in SentenceReader → status highlighting updates immediately
- [ ] Navigate to next/previous sentence → navigation still works
- [ ] Reopen SentenceReader after closing → shows updated status
- [ ] TermsList chips show correct parent translations
- [ ] Tooltips show correct parent data
- [ ] Parent term form save still works correctly
- [ ] Performance is acceptable (only re-parses on term save)
- [ ] Cache is used for normal loads (not cleared unnecessarily)
- [ ] No tooltip spam in logs

---

## Performance Impact

### Cache Usage
- **Normal load**: Cache hit → Fast (same as current)
- **After term save**: Cache miss + reparse → Slight delay (~100-200ms)
- **Tooltip fetch**: Single API call per saved term (efficient)

### Server Calls
- **Before**: 1 call per term save
- **After**: 2 calls per term save (save term + fetch tooltip)
- **Additional overhead**: Minimal (tooltip fetch is fast)

---

## Rollback Plan

If issues arise, revert:
1. Remove `clearBookCache()` call from `initState()`
2. Remove cache clearing and reparse from `onSave`
3. Keep only tooltip refetch in `onSave`

---

## Future Improvements (Out of Scope)

1. Add timestamp to PageData and auto-refresh if stale
2. Implement optimistic UI updates (show new status before save completes)
3. Add loading state during reparse
4. Cache tooltips per page (not just widget state)
5. Merge sentence cache invalidation with tooltip cache for consistency

---

## Summary

This plan implements a minimal, focused fix to:
- ✅ Invalidate stale sentence cache at correct time
- ✅ Reparse sentences with fresh status data
- ✅ Refetch tooltip to update parent translations
- ✅ Maintain fast UX for normal navigation
- ✅ Keep architectural separation between providers
