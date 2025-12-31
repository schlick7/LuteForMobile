# SentenceReader Tap Issue - Investigation Status

## Problem Summary

**Issue**: Terms in the SentenceReader's sentence display (top section) cannot be tapped or double-tapped.
- TermsList (bottom section) works fine - tapping terms opens tooltips and term forms
- ReaderScreen works fine - all term interactions work
- SentenceReader sentence display (top) - NO response when tapping terms, NO logs appear

## Initial Attempts (Failed)

### Attempt 1: Added wrapping GestureDetector with Stack
- Wrapped sentence in Stack with background tap handler
- **Result**: No change

### Attempt 2: Removed outer GestureDetector entirely
- Removed all wrapping gesture detectors
- **Result**: No change

### Attempt 3: Wrapped with GestureDetector + SingleChildScrollView (Option A)
- Matched ReaderScreen's structure: `GestureDetector` → `SingleChildScrollView` → `Padding` → `SentenceReaderDisplay`
- **Result**: No change

## Deep Dive Investigation

### Key Finding: Root Cause Location

**File**: `lib/features/reader/widgets/text_display.dart`, lines 93-99

```dart
if (item.wordId != null) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (details) => onTap?.call(item, details.globalPosition),
    onLongPress: () => onLongPress?.call(item),
    child: textWidget,
  );
}
return textWidget;  // NO GESTURES if wordId is null!
```

**CRITICAL**: If `wordId` is null, text is NOT wrapped in GestureDetector, making it completely non-interactive. This explains:
- No tap events fired
- No logs when clicking (no callback to call)
- TermsList works (shows unique terms which have wordId)
- ReaderScreen works (TextItems have wordId)

### Data Flow Comparison

**ReaderScreen (WORKING)**:
```
HTML → HtmlParser._extractTextItems() → TextItem[] with wordId
→ readerProvider.pageData.paragraphs
→ TextDisplay (uses same TextItems)
→ GestureDetector created (wordId != null) ✓
```

**SentenceReaderScreen (BROKEN)**:
```
HTML → HtmlParser._extractTextItems() → TextItem[] with wordId
→ readerProvider.pageData.paragraphs
→ SentenceParser.parsePage()
→ CustomSentence.textItems
→ sentenceReaderProvider.customSentences
→ SentenceReaderDisplay → TextDisplay.buildInteractiveWord()
→ ? GestureDetector (if wordId != null) ✗
```

### Possible Failure Points

1. **HTML Parsing** - Does `data-wid` attribute exist in HTML?
2. **Sentence Parsing** - Does parser preserve wordId values?
3. **Cache Serialization** - Does JSON save/load preserve wordId?
4. **Cache Key Mismatch** - Is cache returning old data even after clearing?

### Code Flow in SentenceReaderScreen.initState()

**Order of operations** (sentence_reader_screen.dart lines 37-64):
```
1. Get bookId, pageNum, langId from current pageData
2. clearBookCache(bookId) ← Should remove old cached sentences
3. loadPage(bookId, pageNum, updateReaderState: true) ← Fetches fresh PageData
4. parseSentencesForPage(langId) ← Parses sentences from PageData
   - Checks cache FIRST (sentence_reader_provider.dart lines 85-104)
   - If cache hit: Returns old sentences
   - If cache miss: Parses fresh from reader.pageData!.paragraphs
5. loadSavedPosition()
6. _ensureTooltipsLoaded(forceRefresh: true)
```

**Potential Issue**: If cache clearing fails or uses wrong key, step 4 might return old cached sentences with incorrect wordId values.

## Debug Logging Added

To trace where `wordId` becomes null, added logging to:

### 1. HTML Parsing (`lib/core/network/html_parser.dart`)
```dart
// Line 109: After each TextItem is created
print('DEBUG HTML parse: text="$dataText", wordId=$wordId');

// Line 112: After all TextItems created
print('DEBUG HTML parse: Total ${textItems.length} TextItems created');
```

### 2. Sentence Parsing (`lib/features/reader/providers/sentence_reader_provider.dart`)
```dart
// Line 92-97: After sentences are parsed
print('DEBUG: Parsed ${sentences.length} sentences');
if (sentences.isNotEmpty && sentences[0].textItems.isNotEmpty) {
  final firstItem = sentences[0].textItems[0];
  print('DEBUG: After parse - first textItem text="${firstItem.text}", wordId=${firstItem.wordId}');
}
```

### 3. Cache Deserialization (`lib/features/reader/services/sentence_cache_service.dart`)
```dart
// Line 43: After cache is loaded
if (sentences.isNotEmpty && sentences[0].textItems.isNotEmpty) {
  print('DEBUG: Cache loaded - first item text="${sentences[0].textItems[0].text}", wordId=${sentences[0].textItems[0].wordId}');
}
```

### 4. Cache Clearing (`lib/features/reader/services/sentence_cache_service.dart`)
```dart
// Line 77-83: When clearing cache
print('DEBUG clearBookCache: Looking for keys with prefix "$_cachePrefix${bookId}_"');
var removedCount = 0;
for (final key in keys) {
  if (key.startsWith('$_cachePrefix${bookId}_')) {
    await prefs.remove(key);
    print('DEBUG clearBookCache: Removed key "$key"');
    removedCount++;
  }
}
print('DEBUG clearBookCache: Removed $removedCount keys for bookId=$bookId');
```

### 5. TextDisplay Gesture Creation (`lib/features/reader/widgets/text_display.dart`)
```dart
// Line 93: When creating GestureDetectors
print('DEBUG: Creating GestureDetector for "${item.text}", wordId=${item.wordId}');

// Line 100: When SKIPPING GestureDetectors
print('DEBUG: SKIPPING GestureDetector for "${item.text}" - wordId is null');
```

### 6. SentenceReaderScreen.init (`lib/features/reader/widgets/sentence_reader_screen.dart`)
```dart
// Line 44-58: During initialization
print('DEBUG SentenceReaderScreen.initState: Clearing cache for bookId=$bookId');
print('DEBUG SentenceReaderScreen.initState: Loading page bookId=$bookId, pageNum=$pageNum');
print('DEBUG SentenceReaderScreen.initState: Parsing sentences for langId=$langId');
```

## What to Look For in Logs

### Expected Logs for Working Scenario:

**ReaderScreen load**:
```
DEBUG HTML parse: text="The", wordId=123
DEBUG HTML parse: text="cat", wordId=456
...
DEBUG: Creating GestureDetector for "The", wordId=123
DEBUG: Creating GestureDetector for "cat", wordId=456
```

**SentenceReaderScreen load** (if working):
```
DEBUG SentenceReaderScreen.initState: Clearing cache for bookId=1
DEBUG clearBookCache: Removed 3 keys for bookId=1
DEBUG SentenceReaderScreen.initState: Loading page bookId=1, pageNum=1
DEBUG HTML parse: text="The", wordId=123
DEBUG HTML parse: text="cat", wordId=456
...
DEBUG SentenceReaderScreen.initState: Parsing sentences for langId=2
DEBUG: cachedSentences=NOT FOUND
DEBUG: Parsed 5 sentences
DEBUG: After parse - first textItem text="The", wordId=123
DEBUG: Creating GestureDetector for "The", wordId=123
DEBUG: Creating GestureDetector for "cat", wordId=456
```

### Likely Broken Scenario Logs:

**Scenario A - Cache returning old data**:
```
DEBUG SentenceReaderScreen.initState: Clearing cache for bookId=1
DEBUG clearBookCache: Removed 0 keys for bookId=1  ← PROBLEM: Cache not cleared!
DEBUG SentenceReaderScreen.initState: Loading page bookId=1, pageNum=1
DEBUG HTML parse: text="The", wordId=123
...
DEBUG SentenceReaderScreen.initState: Parsing sentences for langId=2
DEBUG: cachedSentences=FOUND (5)  ← PROBLEM: Using old cached data!
DEBUG: Cache loaded - first item text="oldword", wordId=null  ← PROBLEM: Old data!
DEBUG: SKIPPING GestureDetector for "The" - wordId is null
```

**Scenario B - wordId always null in HTML**:
```
DEBUG HTML parse: text="The", wordId=null  ← PROBLEM: HTML has no data-wid!
DEBUG HTML parse: text="cat", wordId=null
...
```

**Scenario C - Parser losing wordId**:
```
DEBUG HTML parse: text="The", wordId=123
DEBUG HTML parse: text="cat", wordId=456
...
DEBUG: After parse - first textItem text="The", wordId=null  ← PROBLEM: Lost wordId!
DEBUG: SKIPPING GestureDetector for "The" - wordId is null
```

## Files Modified

1. `lib/core/network/html_parser.dart` - Added debug logging after HTML parsing
2. `lib/features/reader/providers/sentence_reader_provider.dart` - Added debug logging after sentence parsing
3. `lib/features/reader/services/sentence_cache_service.dart` - Added debug logging for cache operations
4. `lib/features/reader/widgets/text_display.dart` - Added debug logging for gesture creation
5. `lib/features/reader/widgets/sentence_reader_screen.dart` - Added debug logging during initialization

## Next Steps

1. **Run app and navigate to SentenceReader**
2. **Watch console logs** for debug messages
3. **Identify** where `wordId` becomes null:
   - After HTML parsing?
   - After sentence parsing?
   - After cache load?
   - Or never even has wordId?

4. **Based on findings, apply fix**:
   - If HTML issue: Check server response for `data-wid` attribute
   - If parser issue: Fix SentenceParser to preserve wordId
   - If cache issue: Fix cache key generation or clearing
   - If JSON issue: Fix TextItem/CustomSentence serialization

## Hypotheses

### Most Likely: Cache Key Mismatch

**Hypothesis**: Cache clearing uses wrong key pattern, so old data persists even after clearing.

**Cache Key**: `sentence_cache_${bookId}_${pageNum}_${langId}_${threshold}`

**Cache Clear**: Removes keys starting with `sentence_cache_${bookId}_`

This should match, but maybe threshold value differs between save and load?

### Second Most Likely: JSON Serialization Issue

**Hypothesis**: CustomSentence or TextItem serialization/deserialization is corrupting wordId.

**Check**: `TextItem.toJson()` and `TextItem.fromJson()` in text_item.dart lines 49-73
- wordId is correctly saved and loaded
- But maybe some other field is causing issues?

### Third Most Likely: HTML data-wid Missing

**Hypothesis**: Server HTML for sentence pages doesn't include `data-wid` attribute, or it's different from paragraph pages.

**Check**: Run ReaderScreen and SentenceReader on same page - compare HTML logs.

## Current Status

**Debug logging added**: ✓
**Root cause identified**: wordId=null prevents GestureDetector creation
**Actual cause of wordId=null**: Unknown - needs runtime investigation

**Next action**: Run app, check logs, identify where wordId becomes null
