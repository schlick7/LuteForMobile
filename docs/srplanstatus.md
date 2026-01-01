# SentenceReaderScreen Lazy Loading - Implementation Status

## Overview
Transform SentenceReaderScreen from eager-loading (ALL tooltips at startup) to lazy-loading (current sentence only, with next sentence preloading).

---

## Implementation Progress

### ✅ Phase 1: Add Screen Visibility Tracking
**File:** `lib/app.dart`

**Status:** COMPLETE

**Changes made:**
- Created `CurrentScreenRouteNotifier` class with Notifier pattern
- Created `currentScreenRouteProvider` provider
- Updated `_handleNavigateToScreen()` to track current screen route
- Removed direct SentenceReaderScreen initialization code (now handled by SentenceReaderScreen itself)
- Removed unused `_getLangId()` method
- Removed unused imports

**Verification:**
```bash
flutter analyze lib/app.dart 2>&1 | grep error
# No errors found
```

---

### ⏳ Phase 2: Modify SentenceReaderScreen State Management
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Add `WidgetsBindingObserver` mixin to class
- Add `flutter/services.dart` import
- Add new state variables:
  - `bool _hasInitialized = false;`
  - `int? _currentSentenceId;`
  - `AppLifecycleState? _lastLifecycleState;`
- Remove `_lastTooltipsPageNum` (unused)
- Add lifecycle listener methods
- Add `_canPreload()` method

---

### ⏳ Phase 3: Lazy Initialization in Build Method
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Add visibility check: `final isVisible = currentScreenRoute == 'sentence-reader'`
- Update initialization condition to include `isVisible && !_hasInitialized`
- Replace `_ensureTooltipsLoaded()` call with new lazy loading flow
- Add `ref.listen<ReaderState>()` for delayed page loading
- Set up listeners on initialization

---

### ⏳ Phase 4: Current Sentence Tooltip Loading With Filtering
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Create `_setupSentenceNavigationListener()` method
- Create `_extractTermsNeedingTooltips()` helper with status filtering
- Create `_loadTooltipsForCurrentSentence()` method

---

### ⏳ Phase 5: Next Sentence Preloading With Filtering
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Create `_preloadNextSentence()` method
- Add visibility checks to stop preload when not visible

---

### ⏳ Phase 6: Simplify Navigation Handlers
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** ALREADY DONE

**Note:** Navigation handlers already simplified - no changes needed

---

### ⏳ Phase 7: Update flushCacheAndRebuild
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Reset `_hasInitialized` and `_currentSentenceId`
- Clear tooltips cache properly
- Replace eager loading with lazy loading call

---

### ⏳ Phase 8: Add Lifecycle Listener to initState
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Update `initState()` to call `_setupAppLifecycleListener()`

---

### ⏳ Phase 9: Handle "Show Known Terms" Toggle Changes
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Create `_setupSettingsListener()` method (called from Phase 3 initialization)

---

### ⏳ Phase 10: Handle Term Updates and Refresh Affected Terms
**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

**Status:** NOT STARTED

**Planned changes:**
- Update term save callbacks to refresh affected parent/child terms
- Create `_refreshAffectedTermTooltips()` helper method

---

## Overall Progress: 10% (1 of 10 phases complete)

## Notes
- Phase 1 verified and compiling successfully
- Remaining phases focus on `sentence_reader_screen.dart` only
