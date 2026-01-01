# SentenceReaderScreen Lazy Loading Implementation Plan

## Overview
Transform SentenceReaderScreen from eager-loading (ALL tooltips at startup) to lazy-loading (current sentence only, with next sentence preloading). Add visibility awareness so tooltips only load when SentenceReader is actually visible. Optimize tooltip loading by filtering out terms that don't need tooltips (unknown, ignored, hidden known terms).

---

## Phase 1: Add Screen Visibility Tracking

**File: `lib/app.dart`**

1. **Create new provider after `navigationProvider`:**
    ```dart
    final currentScreenRouteProvider = StateProvider<String>((ref) => 'reader');
    ```

2. **Update `_handleNavigateToScreen` to track current screen:**
    ```dart
    void _handleNavigateToScreen(int index) {
      setState(() {
        _currentIndex = index;
      });
      
      // Map index to route name for better maintainability
      final routeNames = ['reader', 'books', 'settings', 'sentence-reader'];
      final currentRoute = routeNames[index];
      ref.read(currentScreenRouteProvider.notifier).state = currentRoute;

      _updateDrawerSettings();

      // Remove this block - SentenceReaderScreen handles it now:
      // if (index == 3) {
      //   Future.microtask(() async {
      //     final reader = ref.read(readerProvider);
      //     if (reader.pageData != null) {
      //       final langId = _getLangId(reader);
      //       await ref
      //           .read(sentenceReaderProvider.notifier)
      //           .parseSentencesForPage(langId);
      //       await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
      //     }
      //   });
      // }
    }
    ```

---

## Phase 2: Modify SentenceReaderScreen State Management

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Remove old tracking variables and methods:**
    - Delete `_ensureTooltipsLoaded()` method (lines 46-68)
    - Delete `_loadAllTermTranslations()` method (lines 104-168)

2. **Keep existing tracking variables:**
    ```dart
    int? _lastInitializedBookId;
    int? _lastInitializedPageNum;
    int? _lastTooltipsBookId;
    // Removed: _lastTooltipsPageNum (unused)
    ```

3. **Add new state variables:**
    ```dart
    bool _hasInitialized = false;
    int? _currentSentenceId;
    ```

4. **Add app lifecycle state tracking:**
    ```dart
    import 'package:flutter/services.dart';

    AppLifecycleState? _lastLifecycleState;

    void _setupAppLifecycleListener() {
      WidgetsBinding.instance.addObserver(this);
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);
      _lastLifecycleState = state;
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

    bool _canPreload() {
      return ref.read(currentScreenRouteProvider) == 'sentence-reader' &&
          _lastLifecycleState != AppLifecycleState.paused;
    }
    ```

**Note:** `_hasInitialized` tracks whether the screen has been initialized for visibility purposes. The book/page tracking variables (`_lastInitializedBookId`, `_lastInitializedPageNum`) handle cache invalidation when switching books or pages.

---

## Phase 3: Lazy Initialization in Build Method

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Modify build method to only initialize when visible:**
    ```dart
    @override
    Widget build(BuildContext context) {
      _mainBuildCount++;
      print('DEBUG: SentenceReaderScreen main build #$_mainBuildCount');

      final currentScreenRoute = ref.watch(currentScreenRouteProvider);
      final isVisible = currentScreenRoute == 'sentence-reader';

      final pageTitle = ref.watch(readerProvider.select((state) => state.pageData?.title));
      final readerState = ref.read(readerProvider);
      final sentenceReader = ref.watch(sentenceReaderProvider);
      final currentSentence = sentenceReader.currentSentence;

      // Initialize only when visible and has data
      if (isVisible && readerState.pageData != null && !_hasInitialized && !readerState.isLoading) {
        final bookId = readerState.pageData!.bookId;
        final pageNum = readerState.pageData!.currentPage;

        if (_lastInitializedBookId != bookId || _lastInitializedPageNum != pageNum) {
          _lastInitializedBookId = bookId;
          _lastInitializedPageNum = pageNum;
          _hasInitialized = true;

          final langId = _getLangId(readerState);
          print('DEBUG: SentenceReaderScreen: Initializing sentence parsing for bookId=$bookId, pageNum=$pageNum, langId=$langId');

          if (_lastTooltipsBookId != bookId) {
            _termTooltips.clear();
            _lastTooltipsBookId = bookId;
          }

          Future(() {
            ref
                  .read(sentenceReaderProvider.notifier)
                  .parseSentencesForPage(langId)
                  .then((_) {
                if (mounted) {
                  ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
                  // Set up sentence navigation listener
                  _setupSentenceNavigationListener();
                  // Set up settings toggle listener
                  _setupSettingsListener();
                  // Load tooltips for current sentence
                  _loadTooltipsForCurrentSentence();
                }
              });
          });
        }
      }

       if (readerState.isLoading || sentenceReader.isParsing) {
         // ... rest of build
       }
       // ... rest of build

       // Listen for page data becoming available after screen is visible
       // (e.g., user opens SentenceReader first, then loads a book)
       ref.listen<ReaderState>(
         readerProvider,
         (previous, next) {
           final prevPage = previous?.pageData;
           final nextPage = next.pageData;

           if (prevPage == null && nextPage != null &&
               _lastInitializedBookId != nextPage.bookId &&
               isVisible) {
             // Page loaded after screen was visible, trigger initialization
             final bookId = nextPage.bookId;
             final pageNum = nextPage.currentPage;

             if (_lastInitializedBookId != bookId || _lastInitializedPageNum != pageNum) {
               _lastInitializedBookId = bookId;
               _lastInitializedPageNum = pageNum;
               _hasInitialized = true;

               final langId = _getLangId(next);
               print('DEBUG: SentenceReaderScreen: Delayed initialization for bookId=$bookId, pageNum=$pageNum, langId=$langId');

               if (_lastTooltipsBookId != bookId) {
                 _termTooltips.clear();
                 _lastTooltipsBookId = bookId;
               }

               Future(() {
                 ref
                       .read(sentenceReaderProvider.notifier)
                       .parseSentencesForPage(langId)
                       .then((_) {
                     if (mounted) {
                       ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
                       _setupSentenceNavigationListener();
                       _setupSettingsListener();
                       _loadTooltipsForCurrentSentence();
                     }
                   });
               });
             }
           }
         },
       );
    }
    ```

**Note:** Settings listener is set up once during initialization (not duplicated elsewhere). If visibility check fails (user navigated away), initialization won't happen until they return. The additional `ref.listen` at the end handles the edge case where the user opens SentenceReader before a book is loaded.

---

## Phase 4: Current Sentence Tooltip Loading With Filtering

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Create `_setupSentenceNavigationListener` method:**
    ```dart
    void _setupSentenceNavigationListener() {
      ref.listen<SentenceReaderState>(
        sentenceReaderProvider,
        (previous, next) {
          final newSentenceId = next.currentSentence?.id;
          if (newSentenceId != null && newSentenceId != _currentSentenceId) {
            _currentSentenceId = newSentenceId;
            print('DEBUG: Sentence changed to ID: $_currentSentenceId');
            _loadTooltipsForCurrentSentence();
          }
        },
      );
    }
    ```

2. **Create helper method to filter terms needing tooltips:**
    ```dart
    List<TextItem> _extractTermsNeedingTooltips(
      CustomSentence sentence,
      {required bool showKnownTerms}
    ) {
      final Map<int, TextItem> termsNeedingTooltips = {};

      for (final item in sentence.textItems) {
        if (item.wordId != null) {
          final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
          final status = statusMatch?.group(1) ?? '0';

          // Skip unknown (status0) - no tooltip data exists
          if (status == '0') {
            continue;
          }

          // Skip ignored (status98) - never displayed
          if (status == '98') {
            continue;
          }

          // Skip known (status99) unless toggle is on
          if (!showKnownTerms && status == '99') {
            continue;
          }

          // Only load tooltips for learning (status1-5) and known (99 when enabled)
          termsNeedingTooltips[item.wordId!] = item;
        }
      }

      return termsNeedingTooltips.values.toList();
    }
    ```

3. **Create `_loadTooltipsForCurrentSentence` method with filtering:**
    ```dart
    Future<void> _loadTooltipsForCurrentSentence() async {
      if (_tooltipsLoadInProgress) return;

      final sentenceReader = ref.read(sentenceReaderProvider);
      final currentSentence = sentenceReader.currentSentence;
      final settings = ref.read(settingsProvider);

      if (currentSentence == null) return;

      // Filter terms that actually need tooltips
      final termsNeedingTooltips = _extractTermsNeedingTooltips(
        currentSentence,
        showKnownTerms: settings.showKnownTermsInSentenceReader,
      );

      print('DEBUG: Loading tooltips for sentence ID: ${currentSentence.id}');
      print('DEBUG: Terms needing tooltips: ${termsNeedingTooltips.length} (out of ${currentSentence.uniqueTerms.length} total)');

      _tooltipsLoadInProgress = true;

      try {
        for (final term in termsNeedingTooltips) {
          if (term.wordId != null && !_termTooltips.containsKey(term.wordId!)) {
            print('DEBUG: Fetching tooltip for wordId=${term.wordId}, term="${term.text}"');
            try {
              final termTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(term.wordId!);
              if (termTooltip != null && mounted) {
                setState(() {
                  _termTooltips[term.wordId!] = termTooltip;
                });
              }
            } catch (e) {
              print('DEBUG: Failed to fetch tooltip for wordId=${term.wordId}: $e');
            }
          }
        }
      } finally {
        _tooltipsLoadInProgress = false;
        print('DEBUG: Finished loading tooltips for sentence ID: ${currentSentence.id}');
      }

      // Preload next sentence after current is done
      if (_canPreload()) {
        _preloadNextSentence();
      }
    }
    ```

---

## Phase 5: Next Sentence Preloading With Filtering

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Create `_preloadNextSentence` method with filtering:**
    ```dart
    Future<void> _preloadNextSentence() async {
      final sentenceReader = ref.read(sentenceReaderProvider);
      final settings = ref.read(settingsProvider);

      if (!sentenceReader.canGoNext) {
        print('DEBUG: No next sentence to preload');
        return;
      }

      final nextIndex = sentenceReader.currentSentenceIndex + 1;
      if (nextIndex >= sentenceReader.customSentences.length) {
        print('DEBUG: Next index out of bounds');
        return;
      }

      final nextSentence = sentenceReader.customSentences[nextIndex];

      // Filter terms for preloading
      final termsNeedingTooltips = _extractTermsNeedingTooltips(
        nextSentence,
        showKnownTerms: settings.showKnownTermsInSentenceReader,
      );

      if (termsNeedingTooltips.isEmpty) {
        print('DEBUG: Next sentence has no terms needing tooltips - skipping preload');
        return;
      }

      print('DEBUG: Preloading tooltips for next sentence ID: ${nextSentence.id} (${termsNeedingTooltips.length} terms)');

      for (final term in termsNeedingTooltips) {
        if (term.wordId != null && !_termTooltips.containsKey(term.wordId!)) {
          // Skip if not visible anymore
          if (!_canPreload()) {
            print('DEBUG: Stopping preload - not visible');
            return;
          }

          try {
            final termTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(term.wordId!);
            if (termTooltip != null && mounted && _canPreload()) {
              setState(() {
                _termTooltips[term.wordId!] = termTooltip;
              });
            }
          } catch (e) {
            print('DEBUG: Failed to preload tooltip for wordId=${term.wordId}: $e');
          }
        }
      }

      print('DEBUG: Finished preloading next sentence');
    }
    ```

---

## Phase 6: Simplify Navigation Handlers

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Update `_goNext` method:**
    ```dart
    Future<void> _goNext() async {
      await ref.read(sentenceReaderProvider.notifier).nextSentence();
      _saveSentencePosition();
      // Tooltip loading handled by listener from Phase 4
    }
    ```

2. **Update `_goPrevious` method:**
    ```dart
    Future<void> _goPrevious() async {
      await ref.read(sentenceReaderProvider.notifier).previousSentence();
      _saveSentencePosition();
      // Tooltip loading handled by listener from Phase 4
    }
    ```

---

## Phase 7: Update flushCacheAndRebuild

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Modify `flushCacheAndRebuild` - clear tooltips and reinitialize:**
    ```dart
    Future<void> flushCacheAndRebuild() async {
      _hasInitialized = false;
      _currentSentenceId = null;
      final reader = ref.read(readerProvider);
      if (reader.pageData == null) return;

      final bookId = reader.pageData!.bookId;
      final pageNum = reader.pageData!.currentPage;
      final langId = _getLangId(reader);

      print('DEBUG SentenceReaderScreen.flushCacheAndRebuild: Clearing cache for bookId=$bookId');
      await ref.read(sentenceCacheServiceProvider).clearBookCache(bookId);

      // Clear all tooltips cache
      _termTooltips.clear();
      _lastTooltipsBookId = null;

      print('DEBUG SentenceReaderScreen.flushCacheAndRebuild: Reloading page bookId=$bookId, pageNum=$pageNum');
      await ref
          .read(readerProvider.notifier)
          .loadPage(bookId: bookId, pageNum: pageNum, updateReaderState: true);

      final freshReader = ref.read(readerProvider);
      if (freshReader.pageData != null) {
        print('DEBUG SentenceReaderScreen.flushCacheAndRebuild: Parsing sentences for langId=$langId');
        await ref
            .read(sentenceReaderProvider.notifier)
            .parseSentencesForPage(langId);
        await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();

        // Reset and reload tooltips for current sentence
        _currentSentenceId = null;
        _loadTooltipsForCurrentSentence();
      }
    }
    ```

    **Note:** Status changes don't change sentence structure, only highlighting. No need to reparse sentences. Only reload tooltips to reflect new status filtering.

---

## Phase 8: Add Lifecycle Listener to initState

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Update `initState` to setup lifecycle listener:**
    ```dart
    @override
    void initState() {
      super.initState();
      _setupAppLifecycleListener();
    }
    ```

---

## Phase 9: Handle "Show Known Terms" Toggle Changes

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

**Note:** Settings listener is set up once during Phase 3 initialization. This section documents the implementation that's called during init.

1. **Add listener for settings toggle (called from Phase 3):**
    ```dart
    void _setupSettingsListener() {
      ref.listen<Settings>(
        settingsProvider.select((s) => s.showKnownTermsInSentenceReader),
        (previous, next) {
          if (previous != next) {
            print('DEBUG: Show known terms toggle changed: $previous -> $next');
            // Reload tooltips to include/exclude known terms
            _loadTooltipsForCurrentSentence();
          }
        },
      );
    }
    ```

    **Note:** When toggle changes, reload tooltips for current sentence to include/exclude known terms as appropriate.
    - **IMPORTANT:** TermListDisplay already handles the UI filtering via `extractUniqueTerms()` which skips status99 when `showKnownTerms=false`. The reload here ensures tooltips are cached for display when the toggle is ON.

---

## Phase 10: Handle Term Updates and Refresh Affected Terms

**File: `lib/features/reader/widgets/sentence_reader_screen.dart`**

1. **Update term save callback in `_showTermForm`:**
    ```dart
    onSave: (updatedForm) async {
      final success = await ref
          .read(readerProvider.notifier)
          .saveTerm(updatedForm);
      if (success && mounted) {
        if (updatedForm.termId != null) {
          _termTooltips.remove(updatedForm.termId!);

          try {
            final freshTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(updatedForm.termId!);
            if (freshTooltip != null && mounted) {
              setState(() {
                _termTooltips[updatedForm.termId!] = freshTooltip;
              });

              // Refresh affected terms after short delay (let modal close smoothly)
              await Future.delayed(const Duration(milliseconds: 100));
              await _refreshAffectedTermTooltips(freshTooltip);
            }
          } catch (e) {}
        }

        Navigator.of(context).pop();
      }
      // ... rest of callback
    },
    ```

2. **Update parent term save callback in `_showParentTermForm`:**
    ```dart
    onSave: (updatedForm) async {
      final success = await ref
          .read(readerProvider.notifier)
          .saveTerm(updatedForm);
      if (success && mounted) {
        if (updatedForm.termId != null) {
          setState(() {
            final existingTooltip =
                  _termTooltips[updatedForm.termId!];
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

          try {
            final freshTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(updatedForm.termId!);
            if (freshTooltip != null && mounted) {
              setState(() {
                _termTooltips[updatedForm.termId!] = freshTooltip;
              });

              // Refresh affected terms after short delay
              await Future.delayed(const Duration(milliseconds: 100));
              await _refreshAffectedTermTooltips(freshTooltip);
            }
          } catch (e) {}
        }

        Navigator.of(context).pop();
      }
      // ... rest of callback
    },
    ```

3. **Add helper method to refresh affected terms:**
    ```dart
    Future<void> _refreshAffectedTermTooltips(TermTooltip updatedTermTooltip) async {
      final sentenceReader = ref.read(sentenceReaderProvider);
      final currentSentence = sentenceReader.currentSentence;

      if (currentSentence == null) return;

      // Build map of term text → wordId for current sentence (case-insensitive match)
      final currentSentenceTerms = <String, int>{};
      for (final item in currentSentence.textItems) {
        if (item.wordId != null) {
          currentSentenceTerms[item.text.toLowerCase()] = item.wordId!;
        }
      }

      // Refresh tooltips for PARENTS in current sentence
      for (final parent in updatedTermTooltip.parents) {
        final parentTermLower = parent.term.toLowerCase();

        if (currentSentenceTerms.containsKey(parentTermLower)) {
          final parentWordId = currentSentenceTerms[parentTermLower];

          print('DEBUG: Refreshing tooltip for affected PARENT term: "${parent.term}" (wordId=$parentWordId)');

          try {
            final parentTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(parentWordId);

            if (parentTooltip != null && mounted) {
              setState(() {
                _termTooltips[parentWordId] = parentTooltip;
              });
            }
          } catch (e) {
            print('DEBUG: Failed to refresh tooltip for parent wordId=$parentWordId: $e');
          }
        }
      }

      // Refresh tooltips for CHILDREN in current sentence
      for (final child in updatedTermTooltip.children) {
        final childTermLower = child.term.toLowerCase();

        if (currentSentenceTerms.containsKey(childTermLower)) {
          final childWordId = currentSentenceTerms[childTermLower];

          print('DEBUG: Refreshing tooltip for affected CHILD term: "${child.term}" (wordId=$childWordId)');

          try {
            final childTooltip = await ref
                  .read(readerProvider.notifier)
                  .fetchTermTooltip(childWordId);

            if (childTooltip != null && mounted) {
              setState(() {
                _termTooltips[childWordId] = childTooltip;
              });
            }
          } catch (e) {
            print('DEBUG: Failed to refresh tooltip for child wordId=$childWordId: $e');
          }
        }
      }
    }
    ```

    **Rationale for refreshing both parents and children:**
    - When a term is updated, its tooltip data changes (translation, status, etc.)
    - Tooltip includes both `parents` and `children` lists showing relationships
    - **Parents affected**: Child terms display parent info in their tooltips
    - **Children affected**: Parent terms may include child in their data
    - Must refresh both directions to keep UI consistent
    - Only refresh terms that exist in current sentence (terms not displayed can wait)
    - 100ms delay lets modal close smoothly before triggering refreshes

---

## Expected Behavior After Implementation

### Scenario 1: App Startup
1. App loads → User sees ReaderScreen (route 'reader')
2. SentenceReaderScreen (route 'sentence-reader') is built but **NOT initialized**
3. **Zero API calls** for tooltips until user opens SentenceReader

### Scenario 2: User Opens SentenceReader
1. User navigates to SentenceReader
2. `currentScreenRoute` becomes 'sentence-reader'
3. SentenceReaderScreen detects visibility
4. Parses sentences for current page (reuses PageData from readerProvider, no API call)
5. Loads tooltips for **current sentence only** (filtered: skips status0, status98, status99 if toggle off)
6. After current sentence finishes → starts preloading next sentence

### Scenario 3: User Navigates Between Sentences
1. User clicks "Next" → moves to next sentence
2. Listener detects sentence change
3. Loads tooltips for new current sentence (filtered)
4. Previous sentence's tooltips remain cached in `_termTooltips`
5. Starts preloading next sentence after current finishes

### Scenario 4: User Leaves SentenceReader
1. User navigates back to ReaderScreen
2. `currentScreenRoute` becomes 'reader'
3. Preloading of next sentence stops immediately
4. No more API calls until user returns to SentenceReader

### Scenario 5: User Minimizes App
1. User minimizes app
2. `_lastLifecycleState` becomes `paused`
3. Preloading stops immediately
4. Resumes when user reopens app (if still on SentenceReader)

### Scenario 6: User Updates a Term
1. User edits term (e.g., changes translation)
2. Term is saved to server
3. Old tooltip is removed from cache
4. Fresh tooltip is fetched and cached
5. 100ms delay lets modal close
6. Parent terms in current sentence are refreshed
7. Child terms in current sentence are refreshed
8. UI updates automatically - all tooltips show correct data

### Scenario 7: User Toggles "Show Known Terms"
1. User toggles setting ON
2. Listener detects change
3. Reloads tooltips for current sentence (includes known terms)
4. UI shows known terms in bottom section

### Scenario 8: User Toggles "Show Known Terms" OFF
1. User toggles setting OFF
2. Listener detects change
3. Reloads tooltips for current sentence (excludes known terms)
4. Known terms hidden from bottom section (tooltips remain cached but not displayed)

---

## Data Flow Verification

### ReaderScreen → SentenceReaderScreen Data Reuse
1. **ReaderScreen** fetches PageData from API → stores in `readerProvider`
2. **SentenceReaderScreen** reads `reader.pageData.paragraphs` (no API call)
3. Uses `SentenceParser` to transform paragraphs into sentences
4. Caches parsed sentences
5. Never refetches PageData from server

### Tooltip Loading Optimization
- **Current sentence only**: Loads tooltips immediately for current sentence
- **Previous sentences**: Already cached in `_termTooltips` map
- **Next sentence**: Preloads in background after current finishes
- **Visibility aware**: Stops preloading if user leaves screen or minimizes app
- **Status filtering**: Skips unknown (status0), ignored (status98), and known (status99 when toggle off)

### API Call Reduction with Filtering

**Example: Page with 100 terms**
- 60 status0 (unknown): NO tooltips
- 10 status98 (ignored): NO tooltips
- 10 status99 (known): NO tooltips (toggle OFF) / YES tooltips (toggle ON)
- 20 status1-5 (learning): YES tooltips

**Before**: Loads tooltips for 100 terms
**After**: Loads tooltips for 20-30 terms
**Savings: 70-80% reduction!**

---

## Files Modified

1. `lib/app.dart` - Add screen route provider, update navigation handler
2. `lib/features/reader/widgets/sentence_reader_screen.dart` - Complete overhaul:
   - Lazy initialization with visibility tracking
   - Current sentence tooltip loading with status filtering
   - Next sentence preloading with status filtering
   - Settings toggle handling
   - Affected terms refresh on term updates
   - App lifecycle awareness
   - Removed unnecessary sentence cache clearing

---

## Benefits

1. **Massive reduction in API calls (70-80%)** - Only loads tooltips for terms with actual learning data (status1-5, not status0)
2. **Better UX** - Current sentence loads immediately, next sentence preloads in background
3. **No wasted resources** - Skips unknown/ignored/hidden terms completely
4. **Maintains state** - Previous sentences remain cached in `_termTooltips`
5. **Responsive to visibility** - Stops preloading if user leaves SentenceReader or minimizes app
6. **Data reuse** - PageData from ReaderScreen is reused, no duplicate API calls
7. **Smart caching** - Known term tooltips remain cached even when status changes to 99
8. **Toggle-aware** - Reloads tooltips when "Show Known Terms" setting changes
9. **Consistent term data** - Refreshes affected parent/child terms when a term is updated
10. **Smooth UX** - 100ms delay prevents jarring UI updates during term save
11. **Maintainable screen tracking** - Uses route names instead of hardcoded indices
