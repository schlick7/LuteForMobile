# Theme System Expansion - v1 Plan


## **Objective**
Add Light Mode theme alongside existing Dark Mode, with theme selector UI. Accent colors remain separate from theme selection.

## **v1 Scope**
- ✅ Dark mode (existing) and Light mode (new) presets
- ✅ Theme selector to switch between them
- ✅ Accent color theming remains unchanged
- ❌ Custom theme editor (deferred to v2)

---

## **Phase 1: Create Theme Data Structure** ✅ COMPLETED

### **New Files Created**

#### 1. `lib/shared/theme/theme_definitions.dart` ✅
- **ThemeType** enum: { dark, light }
- **TextColors** class: primary, secondary, disabled, headline, onPrimary, onSecondary, onPrimaryContainer, onSecondaryContainer, onTertiary, onTertiaryContainer
- **BackgroundColors** class: background, surface, surfaceVariant, surfaceContainerHighest
- **SemanticColors** class: success, onSuccess, warning, onWarning, error, onError, info, onInfo, connected, disconnected, aiProvider, localProvider
- **StatusColors** class: status0, status1, status2, status3, status4, status5, status98, status99, highlightedText
- **BorderColors** class: outline, outlineVariant, dividerColor
- **AudioColors** class: background, icon, bookmark, error, errorBackground
- **ErrorColors** class: error, onError (separate from semantic to allow different values per theme)
- **Material3ColorScheme** class: primary, secondary, tertiary, primaryContainer, secondaryContainer, tertiaryContainer (for Material 3 ColorScheme mapping)
- **AppThemeColorScheme** class: composition of all above color classes


#### 2. `lib/shared/theme/theme_presets.dart` ✅
- **darkThemePreset**: Complete dark theme colors (matching existing Lute theme) - includes all values from current `darkTheme()` in app_theme.dart
- **lightThemePreset**: Complete light theme colors (matching current `lightTheme()` in app_theme.dart with AppColors values)


## **Phase 2: Update Theme System** ✅ COMPLETED

### **3. Modify: `lib/shared/theme/app_theme.dart`** ✅

**Changes:**
- Import `theme_definitions.dart` and `theme_presets.dart`
- Add `AppThemeColorExtension` class at top of file
- Update `lightTheme()` to use `lightThemePreset` values instead of `AppColors` constants
- Update `darkTheme()` to use `darkThemePreset` values
- Add `AppThemeColorExtension` class at top of file with copyWith() and lerp() methods

### **4. Modify: `lib/shared/theme/theme_extensions.dart`** ✅

**Changes:**
- Add import: `import 'theme_presets.dart';`
- **DELETE** `AppColorSchemeExtension` on `ColorScheme` (deprecated)
- **DELETE** `CustomThemeColorsExtension` - use `ThemeExtension<CustomThemeExtension>` directly
- **KEEP** `AppTextThemeExtension` unchanged
- Add a new `BuildContext` extension to support accessing theme extensions with convenience methods:
  - `appColorScheme`
  - `audioPlayerBackground`, `audioPlayerIcon`
  - `status1-5,98,99,0`
  - `success`, `warning`, `error`, `info`
  - `connected`, `disconnected`
  - `aiProvider`, `localProvider`
  - `m3Primary`, `m3Secondary`, `m3Tertiary`, `m3PrimaryContainer`, `m3SecondaryContainer`, `m3TertiaryContainer`
  - `getStatusTextColor()`
  - `getStatusBackgroundColor()`
  - `getStatusColor()`
  - `getStatusColorWithOpacity()`

---

## **Phase 3: Update Settings Model & Provider** ✅ COMPLETED

### **5. Modify: `lib/features/settings/models/settings.dart`**

**Changes to `ThemeSettings` class:**
- Added `final ThemeType themeType = ThemeType.dark;`
- Updated `copyWith()` to include `ThemeType? themeType`
- Updated `operator ==` to include `themeType` and `customAccent*` colors
- Updated `hashCode` to include all new fields
- Kept `accentLabelColor` and `accentButtonColor` unchanged

### **6. Modify: `lib/features/settings/providers/settings_provider.dart`**

**Changes:**
- Added storage key: `static const String _themeTypeKey = 'themeType';`
- Added import: `import '../../../shared/theme/theme_definitions.dart';`
- Updated `_loadSettingsInBackground()` to load theme type with fallback
- Added `updateThemeType(ThemeType themeType)` method
- Added `resetThemeSettings()` method
- Backward compatibility: defaults to `ThemeType.dark` if not set or corrupted

---

## **Phase 4: Create Theme Selector UI** ⏳ PENDING

### **7. Create: `lib/features/settings/widgets/theme_selector_screen.dart`**

**UI Structure:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Mode'),
      ),
      body: ListView(
        children: [
          _buildThemeCard(
            context,
            ThemeType.dark,
            'Dark Mode',
            'Default dark theme for comfortable reading',
            settings.themeSettings.themeType == ThemeType.dark,
            ref,
          ),
          _buildThemeCard(
            context,
            ThemeType.light,
            'Light Mode',
            'Light theme for daytime reading',
            settings.themeSettings.themeType == ThemeType.light,
            ref,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    ThemeType themeType,
    String title,
    String description,
    bool isSelected,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: RadioListTile<ThemeType>(
        value: themeType,
        groupValue: ref.read(settingsProvider).themeSettings.themeType,
        onChanged: (value) async {
          if (value != null) {
            await ref.read(settingsProvider.notifier).updateThemeType(value);
          }
        },
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        selected: isSelected,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
```

### **8. Modify: `lib/features/settings/widgets/settings_screen.dart`**

**Changes:**
- Add "Theme" section before "Accent Colors" section:
  ```dart
  _buildSection(
    context,
    Icons.palette,
    'Theme',
    children: [
      ListTile(
        leading: Icon(Icons.brightness_4),
        title: Text('Theme Mode'),
        subtitle: Text(_getThemeLabel(settings.themeSettings.themeType)),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ThemeSelectorScreen()),
          );
        },
      ),
    ],
  ),
  ```

- Add helper method:
  ```dart
  String _getThemeLabel(ThemeType type) {
    switch (type) {
      case ThemeType.dark: return 'Dark Mode';
      case ThemeType.light: return 'Light Mode';
    }
  }
  ```

---

## **Phase 5: Apply Theme in App** ⏳ PENDING

### **9. Modify: `lib/app.dart`**

**Changes:**
- Add import: `import 'package:lute_for_mobile/shared/theme/theme_presets.dart';`
- Update `themeMode` selection logic to use `ThemeSettings.themeType`:
  ```dart
   Widget build(BuildContext context, WidgetRef ref) {
     final settings = ref.watch(settingsProvider);
     final themeSettings = settings.themeSettings;
     final themeType = themeSettings.themeType;

    return RestartWidget(
      child: MaterialApp(
        title: 'LuteForMobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(themeSettings),
        darkTheme: AppTheme.darkTheme(themeSettings),
        themeMode: themeType == ThemeType.light
            ? ThemeMode.light
            : ThemeMode.dark,
        home: const MainNavigation(),
      ),
    );
  }
  ```

---

## **v1 Color Values Reference**

### **Dark Theme Preset** (Matches Current `darkTheme()` Exactly)

| Category | Property | Color Value | Notes |
|----------|----------|--------------|-------|
| Text | primary | `0xFFE6E1E5` | Light grey font (from current darkTheme) |
| Text | secondary | `0xFFCAC4D0` | Lighter grey |
| Text | disabled | `0xFF938F99` | Muted grey |
| Text | headline | `0xFFE6E1E5` | Same as primary |
| Text | onPrimary | `0xFFFFFFFF` | White (from AppColors) |
| Text | onSecondary | `0xFFFFFFFF` | White (from AppColors) |
| Text | onPrimaryContainer | `0xFFEADDFF` | From AppColors |
| Text | onSecondaryContainer | `0xFFE8DEF8` | From AppColors |
| Text | onTertiary | `0xFFFFD8E4` | From AppColors |
| Text | onTertiaryContainer | `0xFFFFD8E4` | From AppColors |
| Background | background | `0xFF48484a` | Dark grey paper |
| Background | surface | `0xFF1E1E1E` | Cards |
| Background | surfaceVariant | `0xFF2A2A2A` | Variant surface |
| Background | surfaceContainerHighest | `0xFF49454F` | Headers/nav |
| Semantic | success | `0xFF419252` | Green |
| Semantic | onSuccess | `0xFFFFFFFF` | White |
| Semantic | warning | `0xFFBA8050` | Orange |
| Semantic | onWarning | `0xFFFFFFFF` | White |
| Semantic | error | `0xFFFFB4AB` | Red (from current darkTheme) |
| Semantic | onError | `0xFF690005` | Red (from current darkTheme) |
| Semantic | info | `0xFF8095FF` | Blue |
| Semantic | onInfo | `0xFFFFFFFF` | White |
| Semantic | connected | `0xFF419252` | Green |
| Semantic | disconnected | `0xFFBA1A1A` | Red |
| Provider | aiProvider | `0xFF6750A4` | Purple |
| Provider | localProvider | `0xFF1976D2` | Blue |
| Status | status0 | `0xFF8095FF` | Light blue (unknown) |
| Status | status1 | `0x99b46b7a` | Rosy brown (0.6 opacity) |
| Status | status2 | `0x99BA8050` | Burnt orange (0.6 opacity) |
| Status | status3 | `0x99BD9C7B` | Tan (0.6 opacity) |
| Status | status4 | `0x99756D6B` | Dark gray (0.6 opacity) |
| Status | status5 | `0x3377706E` | Gray (0.2 opacity) |
| Status | status98 | `transparent` | No color (ignored) |
| Status | status99 | `0xFF419252` | Green (known) |
| Status | highlightedText | `0xFFeff1f2` | Light text on colored bg |
| Border | outline | `0xFF938F99` | Standard border |
| Border | outlineVariant | `0xFF49454F` | Subtle border |
| Border | dividerColor | `0xFF49454F` | Divider |
| Audio | background | `0xFF6750A4` | Accent button color |
| Audio | icon | `Colors.white` | White icons |
| Audio | bookmark | `0xFFFFA000` | Amber |
| Audio | error | `0xFFD32F2F` | Red |
| Audio | errorBackground | `0x33FFCDD2` | Light red (0.2 opacity) |
| Error | error | `0xFFFFB4AB` | Matches semantic.error |
| Error | onError | `0xFF690005` | Matches semantic.onError |
| Material3 | primary | `0xFF6750A4` | From AppColors (overridden by accentButtonColor) |
| Material3 | secondary | `0xFF625B71` | From AppColors |
| Material3 | tertiary | `0xFF633B48` | From current darkTheme |
| Material3 | primaryContainer | `0xFF4F378B` | From current darkTheme |
| Material3 | secondaryContainer | `0xFF4A4458` | From current darkTheme |
| Material3 | tertiaryContainer | `0xFF8E7266` | From current darkTheme |

### **Light Theme Preset** (Matches Current `lightTheme()` Exactly)

| Category | Property | Color Value | Notes |
|----------|----------|--------------|-------|
| Text | primary | `0xFF1C1B1F` | From AppColors.textPrimary |
| Text | secondary | `0xFF49454F` | From AppColors.textSecondary |
| Text | disabled | `0xFF938F99` | From AppColors.textDisabled |
| Text | headline | `0xFF1C1B1F` | Same as primary |
| Text | onPrimary | `0xFFFFFFFF` | White (from AppColors) |
| Text | onSecondary | `0xFFFFFFFF` | White (from AppColors) |
| Text | onPrimaryContainer | `0xFF21005D` | From AppColors |
| Text | onSecondaryContainer | `0xFF1D192B` | From AppColors |
| Text | onTertiary | `0xFFFFFFFF` | From AppColors |
| Text | onTertiaryContainer | `0xFF31111D` | From AppColors |
| Background | background | `0xFFFFFBFE` | From AppColors.background |
| Background | surface | `0xFFFFFBFE` | From AppColors.surface |
| Background | surfaceVariant | `0xFFE7E0EC` | From AppColors.surfaceVariant |
| Background | surfaceContainerHighest | `0xFFE7E0EC` | From AppColors.surfaceVariant |
| Semantic | success | `0xFF419252` | Green |
| Semantic | onSuccess | `0xFFFFFFFF` | White |
| Semantic | warning | `0xFFBA8050` | Orange |
| Semantic | onWarning | `0xFFFFFFFF` | White |
| Semantic | error | `0xFFBA1A1A` | Red |
| Semantic | onError | `0xFFFFFFFF` | White |
| Semantic | info | `0xFF8095FF` | Blue |
| Semantic | onInfo | `0xFFFFFFFF` | White |
| Semantic | connected | `0xFF419252` | Green |
| Semantic | disconnected | `0xFFBA1A1A` | Red |
| Provider | aiProvider | `0xFF6750A4` | Purple |
| Provider | localProvider | `0xFF1976D2` | Blue |
| Status | status0 | `0xCC8095FF` | Light blue (0.8 opacity) |
| Status | status1 | `0x88b46b7a` | Rosy brown (0.53 opacity) |
| Status | status2 | `0x88BA8050` | Burnt orange (0.53 opacity) |
| Status | status3 | `0x88BD9C7B` | Tan (0.53 opacity) |
| Status | status4 | `0x88756D6B` | Dark gray (0.53 opacity) |
| Status | status5 | `0x4477706E` | Gray (0.26 opacity) |
| Status | status98 | `transparent` | No color (ignored) |
| Status | status99 | `0xFF419252` | Green (known) |
| Status | highlightedText | `0xFF2C2C2C` | Dark text on colored bg |
| Border | outline | `0xFF79747E` | From AppColors |
| Border | outlineVariant | `0xFFCAC4D0` | From AppColors |
| Border | dividerColor | `0xFFCAC4D0` | From AppColors |
| Audio | background | `0xFF6750A4` | Accent button color |
| Audio | icon | `Colors.white` | White icons |
| Audio | bookmark | `0xFFFFA000` | Amber |
| Audio | error | `0xFFD32F2F` | Red |
| Audio | errorBackground | `0x33FFCDD2` | Light red (0.2 opacity) |
| Error | error | `0xFFBA1A1A` | Red |
| Error | onError | `0xFFFFFFFF` | White |
| Material3 | primary | `0xFF6750A4` | From AppColors (overridden by accentButtonColor) |
| Material3 | secondary | `0xFF625B71` | From AppColors |
| Material3 | tertiary | `0xFF7D5260` | From AppColors |
| Material3 | primaryContainer | `0xFFEADDFF` | From AppColors |
| Material3 | secondaryContainer | `0xFFE8DEF8` | From AppColors |
| Material3 | tertiaryContainer | `0xFFFFD8E4` | From AppColors |

---

## **v1 File Summary**

### **New Files (3)**
1. `lib/shared/theme/theme_definitions.dart` - Data structures (with ErrorColors and Material3ColorScheme classes) ✅
2. `lib/shared/theme/theme_presets.dart` - Preset values (with all current colors exactly matched) ✅
3. `lib/features/settings/widgets/theme_selector_screen.dart` - UI ⏳

### **Modified Files (6)**
1. `lib/shared/theme/app_theme.dart` - Theme application (includes button themes, corrected ColorScheme mappings) ✅
2. `lib/shared/theme/theme_extensions.dart` - Theme extensions (DELETE ColorScheme extensions, ADD BuildContext extensions with error and m3* accessors) ✅
3. `lib/features/settings/models/settings.dart` - ThemeSettings model ⏳
4. `lib/features/settings/providers/settings_provider.dart` - Settings state ⏳
5. `lib/features/settings/widgets/settings_screen.dart` - Settings UI ⏳
6. `lib/app.dart` - App theme mode ⏳

### **Files to Delete After Phase 2 Complete (Post-Migration)**
⚠️ **DO NOT DELETE until ALL 17 files are migrated** to use new extensions:

1. `lib/shared/theme/colors.dart` - Old static color constants (AppColors)
2. `lib/shared/theme/status_colors.dart` - Old static status colors (AppStatusColors)

**Migration status:** These files can be deleted only after Phase 2 is complete and all files have been updated to use the new `context.appColorScheme.*` extensions instead of `AppColors.*` and `AppStatusColors.*` static references.

### **Files Requiring Manual Updates**

#### **Must Update All Color References**
1. `lib/features/reader/widgets/audio_player.dart` - All 14 hardcoded colors
2. `lib/features/settings/widgets/settings_screen.dart` - 10 `colorScheme.success/error/connected` references
3. `lib/features/reader/widgets/reader_screen.dart` - 4 `onSurfaceVariant` references
4. `lib/features/reader/widgets/dictionary_view.dart` - 1 `surfaceContainerHighest` reference
5. `lib/features/reader/widgets/term_form.dart` - 8 `colorScheme.*` references
6. `lib/features/reader/widgets/reader_drawer_settings.dart` - 3 `error` references
7. `lib/features/books/widgets/books_screen.dart` - 2 `onSurfaceVariant` references
8. `lib/features/books/widgets/book_details_dialog.dart` - 5 `colorScheme.*` references
9. `lib/features/books/widgets/book_card.dart` - 12 `colorScheme.*` + AppStatusColors references
10. `lib/shared/widgets/app_drawer.dart` - 2 `colorScheme.*` references
11. `lib/features/reader/widgets/text_display.dart` - 1 `getStatusTextColor` reference
12. `lib/features/reader/widgets/term_list_display.dart` - 1 `getStatusTextColor` reference
13. `lib/features/books/widgets/books_drawer_settings.dart` - 1 `outline` reference
14. `lib/shared/widgets/error_display.dart` - 1 `error` reference
15. `lib/shared/home_screen.dart` - 1 `inversePrimary` reference
16. `lib/features/reader/widgets/parent_search.dart` - 2 `colorScheme.*` + `getStatusTextColor` references
17. `lib/features/reader/widgets/sentence_translation.dart` - 5 `colorScheme.*` references

#### **Do NOT Change**
- `lib/features/settings/widgets/settings_screen.dart` line 732, 750: `Color(0xFFBDBDBD)` - This is a fallback color for the color picker UI, not a theme color
- `lib/features/settings/models/settings.dart` lines 167-168: Default accent colors - These are part of Settings model initialization, keep as is

### **No Changes Needed**
- Accent color functionality
- All other settings functionality
- AppColors and AppStatusColors (deprecated but still work)

### **Complete Color Migration Guide**

#### **Audio Player Widget (`lib/features/reader/widgets/audio_player.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).primaryColor` (line 62) | `context.audioPlayerBackground` (internally `context.appColorScheme.audio.background`) | Audio player container background |
| `Colors.grey[400]!` (line 63) | `context.appColorScheme.border.outline` | Bottom border color |
| `Colors.red[100]` (line 74) | `context.audioErrorBackground` (internally `context.appColorScheme.audio.errorBackground`) | Error container background |
| `Colors.red[700]` (line 77) | `context.audioError` (internally `context.appColorScheme.audio.error`) | Error text color |
| `Colors.white` (lines 76, 176, 244, 260, 270, 287, 293, 305, 325) | `context.audioPlayerIcon` (internally `context.appColorScheme.audio.icon`) | All white icons/text |
| `Colors.yellow[700]` (lines 157, 260) | `context.audioBookmark` (internally `context.appColorScheme.audio.bookmark`) | Bookmark indicators |
| `Colors.black.withOpacity(0.05)` (line 224) | `context.appColorScheme.border.outline.withValues(alpha: 0.1)` | Button background |
| `Colors.black.withOpacity(0.7)` (line 181) | `context.appColorScheme.text.disabled.withValues(alpha: 0.7)` | Text shadow |
| `Colors.black.withOpacity(0.1)` (line 228) | `context.appColorScheme.border.outline.withValues(alpha: 0.2)` | Button shadow |

#### **Settings Screen (`lib/features/settings/widgets/settings_screen.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.success` (lines 245, 323, 334, 344) | `context.success` (internally `context.appColorScheme.semantic.success`) | Success indicators |
| `Theme.of(context).colorScheme.error` (lines 246, 255, 324, 335, 345, 644) | `context.error` (internally `context.appColorScheme.semantic.error`) | Error indicators |
| `Theme.of(context).colorScheme.connected` (line 251) | `context.connected` (internally `context.appColorScheme.semantic.connected`) | Connection status |
| `Theme.of(context).colorScheme.primary` (lines 485, 500) | `Theme.of(context).colorScheme.primary` | Accent button color (no change) |
| `Theme.of(context).colorScheme.onSurface` (lines 710, 769) | `context.appColorScheme.text.primary` | Primary text color |
| `Theme.of(context).colorScheme.inversePrimary` (N/A - in home_screen) | See home_screen section below |  |

#### **Reader Screen (`lib/features/reader/widgets/reader_screen.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.onSurfaceVariant` (lines 292, 303, 329, 340) | `context.appColorScheme.text.secondary` | Secondary text |

#### **Dictionary View (`lib/features/reader/widgets/dictionary_view.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.surfaceContainerHighest` (line 105) | `context.appColorScheme.background.surfaceContainerHighest` | Background |

#### **Term Form (`lib/features/reader/widgets/term_form.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.surface` (lines 238, 261) | `context.appColorScheme.background.surface` | Card/modal background |
| `Theme.of(context).colorScheme.outline` (line 335) | `context.appColorScheme.border.outline` | Border color |
| `Theme.of(context).colorScheme.onPrimary` (line 376) | `context.appColorScheme.text.onPrimary` | Text on primary color |
| `Theme.of(context).colorScheme.onSurface` (lines 377, 467, 487) | `context.appColorScheme.text.primary` | Primary text |
| `Theme.of(context).colorScheme.getStatusColor(status)` (line 407) | `context.getStatusColor(status)` | Status color |
| `Theme.of(context).colorScheme.onPrimary` (line 420) | `context.appColorScheme.text.onPrimary` | Text on primary color |
| `Theme.of(context).colorScheme.getStatusTextColor(status)` (line 593) | `context.getStatusTextColor(status)` | Status text color |

#### **Reader Drawer Settings (`lib/features/reader/widgets/reader_drawer_settings.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.errorContainer` (line 102) | `context.appColorScheme.semantic.error.withValues(alpha: 0.1)` | Error container background |
| `Theme.of(context).colorScheme.error` (lines 112, 120) | `context.error` (internally `context.appColorScheme.semantic.error`) | Error color |

#### **Books Screen (`lib/features/books/widgets/books_screen.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.onSurfaceVariant` (lines 170, 181) | `context.appColorScheme.text.secondary` | Secondary text |

#### **Book Details Dialog (`lib/features/books/widgets/book_details_dialog.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.error` (lines 163, 394) | `context.error` (internally `context.appColorScheme.semantic.error`) | Error indicators |
| `Theme.of(context).colorScheme.onSurfaceVariant` (lines 295, 301, 339, 349) | `context.appColorScheme.text.secondary` | Secondary text |

#### **Book Card (`lib/features/books/widgets/book_card.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.primary` (line 48) | `Theme.of(context).colorScheme.primary` | Accent color (no change) |
| `Theme.of(context).colorScheme.primaryContainer` (line 68) | `context.appColorScheme.background.surface` | Badge background |
| `Theme.of(context).colorScheme.onPrimaryContainer` (line 74) | `context.appColorScheme.text.primary` | Badge text |
| `Theme.of(context).colorScheme.onSurfaceVariant` (lines 112, 118, 142, 148, 192, 237) | `context.appColorScheme.text.secondary` | Secondary text |
| `AppStatusColors.getStatusColor(statusNum.toString())` (line 336) | `context.getStatusColor(statusNum.toString())` | Status color |
| `AppStatusColors.status0-99` (lines 181-188) | `context.status0-99` (internally `context.appColorScheme.status.status0-99`) | Direct status colors |

#### **App Drawer (`lib/shared/widgets/app_drawer.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.surfaceContainerHighest` (line 43) | `context.appColorScheme.background.surfaceContainerHighest` | Header background |
| `Theme.of(context).colorScheme.primary` (line 91) | `Theme.of(context).colorScheme.primary` | Accent color (no change) |
| `Theme.of(context).colorScheme.onSurface` (line 92) | `context.appColorScheme.text.primary` | Primary text |

#### **Text Display (`lib/features/reader/widgets/text_display.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.getStatusTextColor(status)` (line 66) | `context.getStatusTextColor(status)` | Status text color |

#### **Term List Display (`lib/features/reader/widgets/term_list_display.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.getStatusTextColor(status)` (line 77) | `context.getStatusTextColor(status)` | Status text color |

#### **Books Drawer Settings (`lib/features/books/widgets/books_drawer_settings.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.outline` (line 76) | `context.appColorScheme.border.outline` | Border color |

#### **Error Display (`lib/shared/widgets/error_display.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.error` (line 20) | `context.error` (internally `context.appColorScheme.semantic.error`) | Error color |

#### **Home Screen (`lib/shared/home_screen.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.inversePrimary` (line 12) | `Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)` | App bar background tint |

#### **Parent Search (`lib/features/reader/widgets/parent_search.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.primaryContainer` (line 178) | `context.appColorScheme.background.surface` | Chip background |
| `Theme.of(context).colorScheme.onPrimaryContainer` (line 179) | `context.appColorScheme.text.primary` | Chip text |
| `Theme.of(context).colorScheme.getStatusTextColor(status)` (line 242) | `context.getStatusTextColor(status)` | Status text color |

#### **Sentence Translation (`lib/features/reader/widgets/sentence_translation.dart`)**
| Current | New | Notes |
|---------|-----|-------|
| `Theme.of(context).colorScheme.surface` (lines 94, 105, 127) | `context.appColorScheme.background.surface` | Card/container background |
| `Theme.of(context).colorScheme.surfaceContainerHighest` (line 177) | `context.appColorScheme.background.surfaceContainerHighest` | Header background |
| `Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)` (line 313) | `context.appColorScheme.border.outline.withValues(alpha: 0.3)` | Subtle border |

#### **AppColors and AppStatusColors Static References**
| File | Current Usage | New Usage |
|------|---------------|----------|
| `book_details_dialog.dart` | `AppStatusColors.getStatusColor()` | `context.getStatusColor()` |
| `book_details_dialog.dart` | `AppStatusColors.getStatusLabel()` | No change - uses labels only |
| `book_card.dart` | `AppStatusColors.status0-99` | `context.status0-99` (internally `context.appColorScheme.status.status0-99`) |
| `book_card.dart` | `AppColors.success` | `context.success` (internally `context.appColorScheme.semantic.success`) |
| `app_theme.dart` | All `AppColors.*` references | Replaced by preset values in Phase 2 |
| `theme_extensions.dart` | All `AppColors.*` and `AppStatusColors.*` | Deleted extension, use `context.appColorScheme.*` |

### **Additional Notes**
- **IMPORTANT**: All widgets currently using `Theme.of(context).colorScheme.status1`, `Theme.of(context).colorScheme.success`, etc. must be updated to use convenience methods like `context.status1`, `context.success` etc., which internally access the grouped properties (`context.appColorScheme.status.status1`, `context.appColorScheme.semantic.success`, etc.)
- These files need updates:
  - `lib/features/reader/widgets/text_display.dart`
  - `lib/features/reader/widgets/term_form.dart`
  - `lib/features/reader/widgets/term_list_display.dart`
  - `lib/features/reader/widgets/parent_search.dart`
  - And all other files using `Theme.of(context).colorScheme` custom properties
- `lib/features/reader/widgets/audio_player.dart` should be updated to use `context.audioPlayerBackground`, `context.audioPlayerIcon`, `context.audioBookmark`, `context.audioError`, `context.audioErrorBackground` instead of hardcoded colors (these access `context.appColorScheme.audio.*` properties internally)

---


## **v1 Implementation Order**

1. ✅ Create `theme_definitions.dart` with grouped color classes (TextColors, BackgroundColors, SemanticColors, StatusColors, BorderColors, AudioColors, **ErrorColors**, **Material3ColorScheme**) and AppThemeColorScheme
2. ✅ Create `theme_presets.dart` with darkThemePreset and lightThemePreset using grouped structure, including **error** and **material3** classes with values matching current app exactly
3. ✅ Add `AppThemeColorExtension` class to `app_theme.dart` with lerp support for grouped properties (including new ErrorColors and Material3ColorScheme)
4. ✅ Update `app_theme.dart` lightTheme() and darkTheme() methods to use preset values via grouped properties, **including button themes**
5. ⏳ Update `settings.dart` model with ThemeType field
6. ⏳ Update `settings_provider.dart` to save/load theme type
7. ✅ Update `theme_extensions.dart` - add import for `theme_presets.dart`, DELETE `AppColorSchemeExtension`, DELETE `CustomThemeColorsExtension`, ADD `BuildContextExtension` with convenience methods that delegate to grouped properties, **including error and m3* accessors**
8. ⏳ Create `theme_selector_screen.dart` (simple selector, no previews)
9. ⏳ Update `settings_screen.dart` to add Theme section
10. ⏳ Update `app.dart` to apply theme mode based on selection
11. **CRITICAL**: Update ALL 17 files listed in "Files Requiring Manual Updates" section to use new color extensions
12. Test thoroughly - verify both dark and light themes work correctly in all screens, ensuring **all current colors are preserved**

---

## **Complete AppColors to Preset Mapping Reference**

This table shows exactly where each `AppColors.*` constant maps to in the new preset structure:

| AppColors Constant | Light Preset Path | Dark Preset Path |
|---------------------|-------------------|------------------|
| `primary` | material3.primary (0xFF6750A4) | material3.primary (0xFF6750A4) |
| `onPrimary` | text.onPrimary (0xFFFFFFFF) | text.onPrimary (0xFFFFFFFF) |
| `primaryContainer` | material3.primaryContainer (0xFFEADDFF) | material3.primaryContainer (0xFF4F378B) |
| `onPrimaryContainer` | text.onPrimaryContainer (0xFF21005D) | text.onPrimaryContainer (0xFFEADDFF) |
| `secondary` | material3.secondary (0xFF625B71) | material3.secondary (0xFF625B71) |
| `onSecondary` | text.onSecondary (0xFFFFFFFF) | text.onSecondary (0xFFFFFFFF) |
| `secondaryContainer` | material3.secondaryContainer (0xFFE8DEF8) | material3.secondaryContainer (0xFF4A4458) |
| `onSecondaryContainer` | text.onSecondaryContainer (0xFF1D192B) | text.onSecondaryContainer (0xFFE8DEF8) |
| `tertiary` | material3.tertiary (0xFF7D5260) | material3.tertiary (0xFF633B48) |
| `onTertiary` | text.onTertiary (0xFFFFFFFF) | text.onTertiary (0xFFFFD8E4) |
| `tertiaryContainer` | material3.tertiaryContainer (0xFFFFD8E4) | material3.tertiaryContainer (0xFF8E7266) |
| `onTertiaryContainer` | text.onTertiaryContainer (0xFF31111D) | text.onTertiaryContainer (0xFFFFD8E4) |
| `surface` | background.surface (0xFFFFFBFE) | background.surface (0xFF1E1E1E) |
| `onSurface` | text.primary (0xFF1C1B1F) | text.primary (0xFFE6E1E5) |
| `surfaceVariant` | background.surfaceVariant (0xFFE7E0EC) | background.surfaceVariant (0xFF2A2A2A) |
| `onSurfaceVariant` | text.secondary (0xFF49454F) | text.secondary (0xFFCAC4D0) |
| `background` | background.background (0xFFFFFBFE) | background.background (0xFF48484a) |
| `onBackground` | text.primary (0xFF1C1B1F) | text.primary (0xFFE6E1E5) |
| `outline` | border.outline (0xFF79747E) | border.outline (0xFF938F99) |
| `outlineVariant` | border.outlineVariant (0xFFCAC4D0) | border.outlineVariant (0xFF49454F) |
| `success` | semantic.success (0xFF419252) | semantic.success (0xFF419252) |
| `onSuccess` | semantic.onSuccess (0xFFFFFFFF) | semantic.onSuccess (0xFFFFFFFF) |
| `warning` | semantic.warning (0xFFBA8050) | semantic.warning (0xFFBA8050) |
| `onWarning` | semantic.onWarning (0xFFFFFFFF) | semantic.onWarning (0xFFFFFFFF) |
| `error` | error.error (0xFFBA1A1A) | error.error (0xFFFFB4AB) |
| `onError` | error.onError (0xFFFFFFFF) | error.onError (0xFF690005) |
| `info` | semantic.info (0xFF8095FF) | semantic.info (0xFF8095FF) |
| `onInfo` | semantic.onInfo (0xFFFFFFFF) | semantic.onInfo (0xFFFFFFFF) |
| `connected` | semantic.connected (0xFF419252) | semantic.connected (0xFF419252) |
| `disconnected` | semantic.disconnected (0xFFBA1A1A) | semantic.disconnected (0xFFBA1A1A) |
| `aiProvider` | semantic.aiProvider (0xFF6750A4) | semantic.aiProvider (0xFF6750A4) |
| `localProvider` | semantic.localProvider (0xFF1976D2) | semantic.localProvider (0xFF1976D2) |
| `textPrimary` | text.primary (0xFF1C1B1F) | text.primary (0xFFE6E1E5) |
| `textSecondary` | text.secondary (0xFF49454F) | text.secondary (0xFFCAC4D0) |
| `textDisabled` | text.disabled (0xFF938F99) | text.disabled (0xFF938F99) |
| `accentLabel` | CustomThemeColors (separate) | CustomThemeColors (separate) |
| `accentButton` | CustomThemeColors (separate) | CustomThemeColors (separate) |

**Note:** `accentLabel` and `accentButton` remain in `CustomThemeColors` as user-customizable accent colors, separate from the preset theme colors.
