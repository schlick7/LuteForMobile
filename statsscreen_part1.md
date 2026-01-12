# StatsScreen Part 1: Structure, Fetching, Caching

## Directory Structure

```
lib/features/stats/
├── models/
│   ├── stats_data.dart           # DailyReadingStats model
│   ├── language_stats.dart       # LanguageReadingStats with gap-filling
│   └── cached_stats.dart         # CachedStats for SharedPreferences
├── repositories/
│   └── stats_repository.dart     # Data fetching & caching logic
├── providers/
│   └── stats_provider.dart       # StatsNotifier state management
└── widgets/
    └── stats_screen.dart         # Basic screen scaffold
```

## Data Gap Filling

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

## API Changes (COMPLETED)

**`lib/core/network/api_service.dart`:**
```dart
Future<Response<String>> getStatsData() async {
  return await _dio.get('/stats/data');
}
```

**`lib/core/network/content_service.dart`:**
```dart
Future<Map<String, dynamic>> getStatsData() async {
  final response = await _apiService.getStatsData();
  final jsonString = response.data ?? '{}';
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return json;
}
```

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/stats/models/stats_data.dart` | DailyReadingStats model |
| `lib/features/stats/models/language_stats.dart` | LanguageReadingStats with gap-filling |
| `lib/features/stats/models/cached_stats.dart` | CachedStats + StatsCacheService |
| `lib/features/stats/repositories/stats_repository.dart` | Data layer with caching |
| `lib/features/stats/providers/stats_provider.dart` | State management |
| `lib/features/stats/widgets/stats_screen.dart` | Basic screen scaffold |

## Dependencies

Already in `pubspec.yaml`:
- `shared_preferences: ^2.2.3` - Caching
- `flutter_riverpod: ^3.0.3` - State management
- `dio: ^5.9.0` - HTTP client
