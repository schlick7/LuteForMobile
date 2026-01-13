# Reader Stats Row Implementation Plan

## Overview
Add a new stats row above the bottom navigator in the readscreen that displays:
- Today's wordcount for the current language
- Current language's status99 (known) terms count
- Language flag emoji next to the stats

Also implement auto-refresh of status99 count when a term is saved with status99 status.

---

## 1. Create Language Flag Mapper Utility

**Location:** `lib/shared/utils/language_flag_mapper.dart`
- Create new `utils` directory in `lib/shared/`
- Export `getFlagForLanguage(String languageName) → String?`
- Maps language → country code → flag emoji via Unicode regional indicators

**Implementation:**
```dart
String getFlagForLanguage(String languageName) {
  final countryCode = _languageToCountryCode(languageName);
  if (countryCode == null) return null;
  return _countryCodeToFlag(countryCode);
}

String _countryCodeToFlag(String countryCode) {
  // Convert 2-letter country code to regional indicator symbols
  final first = countryCode.codeUnitAt(0);
  final second = countryCode.codeUnitAt(1);
  return String.fromCharCodes([
    0x1F1E6 + (first - 0x41),
    0x1F1E6 + (second - 0x41),
  ]);
}
```

**Language to Country Mapping:**
- Japanese → JP
- Spanish → ES
- French → FR
- German → DE
- Chinese → CN
- Korean → KR
- Portuguese → PT
- Russian → RU
- Italian → IT
- English → US (or GB)
- ... and so on

---

## 2. Add Stats Row Widget

**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

Create new `_buildStatsRow()` method:

```dart
Widget _buildStatsRow() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // Language flag
        if (_currentLanguageFlag != null) Text(_currentLanguageFlag),
        const SizedBox(width: 8),
        // Today's wordcount
        Text("Today's Words: $_todayWordcount"),
        const Spacer(),
        // Known (status99) count
        Text("Known: $_status99Count"),
      ],
    ),
  );
}
```

**Data Sources:**
- **Today's wordcount:** From `statsProvider` → filter `LanguageReadingStats` by current language → find today's `DailyReadingStats.wordcount`
- **Status99 count:** From `termsProvider` state → `TermStats.status99`
- **Language name/flag:** From `readerProvider` → access language ID from `TextItem.langId`

---

## 3. Restructure Bottom Navigation

**File:** `lib/features/reader/widgets/sentence_reader_screen.dart`

Replace the current single `BottomAppBar` with a `Column`:

```dart
bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    _buildStatsRow(),
    _buildNavigationBar(),  // renamed from _buildBottomAppBar
  ],
),
```

**Changes:**
- Rename `_buildBottomAppBar()` to `_buildNavigationBar()`
- The stats row is always visible

---

## 4. Auto-Refresh Status99 on TermForm Save

**File:** `lib/features/reader/widgets/term_form.dart`

**Add new callback parameter:**
```dart
final void Function(int langId)? onStatus99Changed;
```

**In `_handleSave()`:**
```dart
void _handleSave() {
  final newStatus = _selectedStatus;
  final oldStatus = widget.termForm.status;

  final updatedForm = widget.termForm.copyWith(
    translation: _translationController.text.trim(),
    status: newStatus,
    // ... other fields
  );

  // Trigger refresh if status changed to 99
  if (oldStatus != '99' && newStatus == '99') {
    widget.onStatus99Changed?.call(widget.termForm.languageId);
  }

  widget.onSave(updatedForm);
}
```

**Callers to update (add `onStatus99Changed` callback):**
- `reader_screen.dart` (4 places)
- `sentence_reader_screen.dart` (4 places)

---

## 5. Trigger Stats Refresh

**In caller implementations:**

```dart
// When opening TermForm, pass the callback
onStatus99Changed: (langId) {
  ref.read(termsProvider.notifier)._loadStats(langId);
},
```

**Note:** `_loadStats` is currently private (`_loadStats(int? langId)`). Options:
1. Make it public: `loadStats(int langId)`
2. Create a public wrapper method
3. Use a listener approach

**Recommendation:** Make `_loadStats` public since it's already exposed through other mechanisms.

---

## Data Access Details

### Today's Wordcount
```dart
final statsState = ref.watch(statsProvider);
final currentLanguageStats = statsState.value?.languages.firstWhere(
  (l) => l.language == _currentLanguageName,
);
final todayStats = currentLanguageStats?.dailyStats.firstWhere(
  (s) => isToday(s.date),
);
final todayWordcount = todayStats?.wordcount ?? 0;
```

### Status99 Count
```dart
final termsState = ref.watch(termsProvider);
final status99Count = termsState.value?.stats.status99 ?? 0;
```

### Current Language
From `readerProvider`:
- `pageData` contains book info
- Language ID available from `TextItem.langId` in current sentence
- Need to look up language name from ID (may need additional provider/lookup)

---

## Files to Modify

1. **Create:** `lib/shared/utils/language_flag_mapper.dart`
2. **Modify:** `lib/features/reader/widgets/term_form.dart`
3. **Modify:** `lib/features/reader/widgets/sentence_reader_screen.dart`
4. **Modify:** `lib/features/reader/widgets/reader_screen.dart` (4 call sites)

---

## Testing Considerations

1. Stats row displays correctly when data is loading
2. Stats row displays zeros/defaults when no data available
3. Flag displays correctly for different languages
4. Auto-refresh triggers when saving term with status99
5. No refresh when saving term with other status
6. No crash when language not found in flag mapper
