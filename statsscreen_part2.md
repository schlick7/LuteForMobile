# StatsScreen Part 2: Navigation Integration

## Changes to `lib/app.dart`

**Add import:**
```dart
import 'package:lute_for_mobile/features/stats/widgets/stats_screen.dart';
```

**Update routeNames array (around line 236):**
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

**Update IndexedStack body (around line 338-362):**
Add StatsScreen at index 3, shift other screens accordingly.

**Update `_updateDrawerSettings()` (around line 280):**
```dart
case 3: // Stats - NEW
  ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
  break;
```

## Changes to `lib/shared/widgets/app_drawer.dart`

**Add nav item (around line 51, after Terms):**
```dart
_buildNavItem(context, Icons.bar_chart, 3, 'Stats'),
```

## Tasks

1. Import StatsScreen in `app.dart`
2. Add 'stats' to routeNames at index 3
3. Update IndexedStack to include StatsScreen
4. Update `_updateDrawerSettings()` switch case
5. Add Stats icon to AppDrawer navigation
6. Run `flutter analyze` to verify build
7. Test navigation flows
