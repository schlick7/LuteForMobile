# StatsScreen Implementation Plan

A comprehensive statistics screen for LuteForMobile following the existing codebase patterns (Riverpod, SharedPreferences caching, repository pattern).

## Three-Phase Approach

### Phase 1: Structure, Fetching, Caching/Saving
Create the feature directory structure, data models, repository, and provider. Add API endpoint to ContentService and ApiService. Implement SharedPreferences-based caching.

### Phase 2: Navigation Integration
Add StatsScreen to the app navigation drawer and main navigation controller. Verify the app builds successfully.

### Phase 3: UI Components & Charts
Implement the full UI with summary cards, filters, and charts using fl_chart.

---

## Phase 1: Structure, Fetching, Caching

### Directory Structure

```
lib/features/stats/
├── models/
│   ├── stats_data.dart           # DailyReadingStats model
│   ├── language_stats.dart       # LanguageReadingStats with aggregations
│   └── cached_stats.dart         # CachedStats for SharedPreferences
├── repositories/
│   └── stats_repository.dart     # Data fetching & caching logic
├── providers/
│   └── stats_provider.dart       # StatsNotifier state management
└── widgets/
    └── stats_screen.dart         # Main screen scaffold
```

### Key Design Decisions

**Caching Strategy:** Use SharedPreferences (already in pubspec.yaml) following the existing `PageCacheService` pattern from `lib/features/reader/services/page_cache_service.dart`.

**API Endpoint:** Add `/stats/data` endpoint to ApiService and ContentService. Response format:
```json
{
  "English": [{"readdate": "2025-09-02", "wordcount": 324, "runningTotal": 324}, ...],
  "Spanish": [...]
}
```

**State Management:** Use Riverpod Notifier pattern following `TermsProvider` in `lib/features/terms/providers/terms_provider.dart`.

### Data Gap Filling

The server only sends days with reading activity. Days with 0 words are omitted entirely.

**Example English data from server:**
| Date | wordcount | runningTotal |
|------|-----------|--------------|
| 9/12 | 283       | 69263        |
| 9/15 | 324       | 69587        |  <- gap of 2 days
| 9/20 | 1903      | 71490        |  <- gap of 4 days
| ...  | gap       | ...          |  <- gap of 2+ months!
| 1/4  | 18095     | 89585        |
| 1/5  | 504       | 90089        |
| 1/6  | 305       | 90394        |

**After filling gaps:**
| Date | wordcount | runningTotal | Note |
|------|-----------|--------------|------|
| 9/12 | 283       | 69263        | server data |
| 9/13 | 0         | 69263        | filled - carry over |
| 9/14 | 0         | 69263        | filled - carry over |
| 9/15 | 324       | 69587        | server data |
| 9/16 | 0         | 69587        | filled |
| ...  | 0         | 69587        | filled through |
| 9/20 | 1903      | 71490        | server data |

**Algorithm:**
1. Fetch all server data
2. Sort by date ascending
3. Find first date with data and last date (today)
4. Iterate each day from first to today
5. If date exists in server data → use it (ALWAYS trust server)
6. If date missing → wordcount=0, runningTotal=previousKnown.runningTotal
7. No calculations needed - just carry over values

**This must happen BEFORE any caching or aggregation calculations.**

### Files to Create (Phase 1)

| File | Purpose |
|------|---------|
| `lib/features/stats/models/stats_data.dart` | DailyReadingStats model |
| `lib/features/stats/models/language_stats.dart` | LanguageReadingStats with aggregations |
| `lib/features/stats/models/cached_stats.dart` | CachedStats for serialization |
| `lib/features/stats/repositories/stats_repository.dart` | Data layer with caching |
| `lib/features/stats/providers/stats_provider.dart` | State management |
| `lib/features/stats/widgets/stats_screen.dart` | Basic screen scaffold |

### API Changes Required

**In `lib/core/network/api_service.dart` (around line 475):**
```dart
Future<Response<String>> getStatsData() async {
  return await _dio.get('/stats/data');
}
```

**In `lib/core/network/content_service.dart` (around line 500):**
```dart
Future<Map<String, dynamic>> getStatsData() async {
  final response = await _apiService.getStatsData();
  final jsonString = response.data ?? '{}';
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return json;
}
```

### Caching Implementation

Following `PageCacheService` pattern with SharedPreferences:

```dart
// In stats_repository.dart
static const String _cacheKey = 'stats_data';
static const int _cacheExpirationHours = 1;

Future<CachedStats?> _loadFromCache() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(_cacheKey);
  return CachedStats.fromJsonString(jsonString);
}

Future<void> _saveToCache(Map<String, LanguageReadingStats> stats) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = CachedStats(lastUpdated: DateTime.now(), stats: stats);
  await prefs.setString(_cacheKey, cached.toJsonString());
}
```

### Phase 1 Tasks

1. Create `lib/features/stats/models/stats_data.dart`
2. Create `lib/features/stats/models/language_stats.dart`
3. Create `lib/features/stats/models/cached_stats.dart`
4. Add `getStatsData()` to `ApiService`
5. Add `getStatsData()` to `ContentService`
6. Create `lib/features/stats/repositories/stats_repository.dart`
7. Create `lib/features/stats/providers/stats_provider.dart`
8. Create basic `lib/features/stats/widgets/stats_screen.dart` scaffold
9. Verify project builds with `flutter analyze`

---

## Phase 2: Navigation Integration

### Changes to `lib/app.dart`

**Add import:**
```dart
import 'package:lute_for_mobile/features/stats/widgets/stats_screen.dart';
```

**Update routeNames array (line 236):**
```dart
final routeNames = [
  'reader',        // 0
  'books',         // 1
  'terms',         // 2
  'stats',         // 3 - NEW
  'help',          // 4 (was 3)
  'settings',      // 5 (was 4)
  'sentence-reader', // 6 (was 5)
];
```

**Update IndexedStack body (line 338-362):**
Add StatsScreen at index 3, shift other screens accordingly.

**Update `_updateDrawerSettings()` (line 280-317):**
Add case 3 for StatsScreen to set `null` drawer settings.

### Changes to `lib/shared/widgets/app_drawer.dart`

**Add nav item (around line 51):**
```dart
_buildNavItem(context, Icons.bar_chart, 3, 'Stats'),
```

### Phase 2 Tasks

1. Import StatsScreen in `app.dart`
2. Add 'stats' to routeNames
3. Update IndexedStack to include StatsScreen
4. Update `_updateDrawerSettings()` switch case
5. Add Stats icon to AppDrawer navigation
6. Run `flutter analyze` to verify build
7. Test navigation flows

---

## Phase 3: UI Components & Charts

### Widgets to Implement

| Widget | Purpose | Dependencies |
|--------|---------|--------------|
| `summary_cards.dart` | Quick stats overview (today, week, total) | - |
| `period_filter_widget.dart` | Time period selector (7d, 30d, 90d, 1y, all) | - |
| `language_filter_widget.dart` | Language dropdown selector | Languages from ContentService |
| `words_read_chart.dart` | Line chart for cumulative words | fl_chart |
| `term_status_chart.dart` | Pie chart for term distribution | fl_chart, TermStats |
| `language_breakdown_card.dart` | Per-language stats list | - |

### Chart Configuration (fl_chart)

**Line Chart (words_read_chart.dart):**
- X-axis: Date
- Y-axis: Cumulative word count
- Multi-language overlay with color-coded lines
- Interactive tooltips on tap

**Pie Chart (term_status_chart.dart):**
- Segments: Status 1-5, Status 99 (Well Known)
- Interactive tap to show count
- Legend with color coding

### Phase 3 Tasks

1. Create `summary_cards.dart`
2. Create `period_filter_widget.dart`
3. Create `language_filter_widget.dart`
4. Create `words_read_chart.dart`
5. Create `term_status_chart.dart`
6. Create `language_breakdown_card.dart`
7. Update `stats_screen.dart` to include all widgets
8. Add refresh indicator and pull-to-refresh
9. Test on both light/dark themes

---

## Dependencies

Already available in `pubspec.yaml`:
- `fl_chart: ^1.1.1` - Charts
- `shared_preferences: ^2.2.3` - Caching
- `flutter_riverpod: ^3.0.3` - State management
- `dio: ^5.9.0` - HTTP client

---

## Reference Files

- Existing pattern: `lib/features/terms/` - Similar feature structure
- Caching pattern: `lib/features/reader/services/page_cache_service.dart`
- State pattern: `lib/features/terms/providers/terms_provider.dart`
- Navigation: `lib/app.dart` and `lib/shared/widgets/app_drawer.dart`
- Charts: `fl_chart` package documentation

---

## Success Criteria

1. Phase 1: Project builds, stats data fetches from API, caching works
2. Phase 2: StatsScreen accessible from drawer, navigation works correctly
3. Phase 3: All charts render, data filters work, pull-to-refresh works
