# Theme System Expansion - v1 Plan

## **Objective**
Add Light Mode theme alongside existing Dark Mode, with theme selector UI. Accent colors remain separate from theme selection.

## **v1 Scope**
- ✅ Dark mode (existing) and Light mode (new) presets
- ✅ Theme selector to switch between them
- ✅ Accent color theming remains unchanged
- ❌ Custom theme editor (deferred to v2)

---

## **Phase 1: Create Theme Data Structure**

### **New Files to Create**

#### 1. `lib/shared/theme/theme_definitions.dart`

```dart
import 'package:flutter/material.dart';

enum ThemeType { dark, light }

enum StatusMode { background, text }

@immutable
class AppThemeColorScheme {
  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textHeadline;
  final Color textOnPrimary;
  final Color textOnSecondary;
  
  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainerHighest;
  final Color bookCardBackground;
  final Color tooltipBackground;
  
  // Semantic colors
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color error;
  final Color onError;
  final Color info;
  final Color onInfo;
  final Color connected;
  final Color disconnected;
  
  // Provider colors
  final Color aiProviderBadge;
  final Color localProviderBadge;
  
  // Status colors
  final Color status0;
  final Color status1;
  final Color status2;
  final Color status3;
  final Color status4;
  final Color status5;
  final Color status98;
  final Color status99;
  final Color statusHighlightedText;
  
  // Border colors
  final Color outline;
  final Color outlineVariant;
  final Color dividerColor;
  
  // Audio player colors
  final Color audioPlayerBackground;
  final Color audioPlayerIcon;
  final Color audioBookmark;
  final Color audioError;
  final Color audioErrorBackground;
  
  const AppThemeColorScheme({
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textHeadline,
    required this.textOnPrimary,
    required this.textOnSecondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainerHighest,
    required this.bookCardBackground,
    required this.tooltipBackground,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.info,
    required this.onInfo,
    required this.connected,
    required this.disconnected,
    required this.aiProviderBadge,
    required this.localProviderBadge,
    required this.status0,
    required this.status1,
    required this.status2,
    required this.status3,
    required this.status4,
    required this.status5,
    required this.status98,
    required this.status99,
    required this.statusHighlightedText,
    required this.outline,
    required this.outlineVariant,
    required this.dividerColor,
    required this.audioPlayerBackground,
    required this.audioPlayerIcon,
    required this.audioBookmark,
    required this.audioError,
    required this.audioErrorBackground,
  });
  
  AppThemeColorScheme copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textHeadline,
    Color? textOnPrimary,
    Color? textOnSecondary,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceContainerHighest,
    Color? bookCardBackground,
    Color? tooltipBackground,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? error,
    Color? onError,
    Color? info,
    Color? onInfo,
    Color? connected,
    Color? disconnected,
    Color? aiProviderBadge,
    Color? localProviderBadge,
    Color? status0,
    Color? status1,
    Color? status2,
    Color? status3,
    Color? status4,
    Color? status5,
    Color? status98,
    Color? status99,
    Color? statusHighlightedText,
    Color? outline,
    Color? outlineVariant,
    Color? dividerColor,
    Color? audioPlayerBackground,
    Color? audioPlayerIcon,
    Color? audioBookmark,
    Color? audioError,
    Color? audioErrorBackground,
  }) {
    return AppThemeColorScheme(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textHeadline: textHeadline ?? this.textHeadline,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnSecondary: textOnSecondary ?? this.textOnSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      bookCardBackground: bookCardBackground ?? this.bookCardBackground,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      connected: connected ?? this.connected,
      disconnected: disconnected ?? this.disconnected,
      aiProviderBadge: aiProviderBadge ?? this.aiProviderBadge,
      localProviderBadge: localProviderBadge ?? this.localProviderBadge,
      status0: status0 ?? this.status0,
      status1: status1 ?? this.status1,
      status2: status2 ?? this.status2,
      status3: status3 ?? this.status3,
      status4: status4 ?? this.status4,
      status5: status5 ?? this.status5,
      status98: status98 ?? this.status98,
      status99: status99 ?? this.status99,
      statusHighlightedText: statusHighlightedText ?? this.statusHighlightedText,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      dividerColor: dividerColor ?? this.dividerColor,
      audioPlayerBackground: audioPlayerBackground ?? this.audioPlayerBackground,
      audioPlayerIcon: audioPlayerIcon ?? this.audioPlayerIcon,
      audioBookmark: audioBookmark ?? this.audioBookmark,
      audioError: audioError ?? this.audioError,
      audioErrorBackground: audioErrorBackground ?? this.audioErrorBackground,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppThemeColorScheme &&
        other.textPrimary == textPrimary &&
        other.textSecondary == textSecondary &&
        other.textDisabled == textDisabled &&
        other.textHeadline == textHeadline &&
        other.textOnPrimary == textOnPrimary &&
        other.textOnSecondary == textOnSecondary &&
        other.background == background &&
        other.surface == surface &&
        other.surfaceVariant == surfaceVariant &&
        other.surfaceContainerHighest == surfaceContainerHighest &&
        other.bookCardBackground == bookCardBackground &&
        other.tooltipBackground == tooltipBackground &&
        other.success == success &&
        other.onSuccess == onSuccess &&
        other.warning == warning &&
        other.onWarning == onWarning &&
        other.error == error &&
        other.onError == onError &&
        other.info == info &&
        other.onInfo == onInfo &&
        other.connected == connected &&
        other.disconnected == disconnected &&
        other.aiProviderBadge == aiProviderBadge &&
        other.localProviderBadge == localProviderBadge &&
        other.status0 == status0 &&
        other.status1 == status1 &&
        other.status2 == status2 &&
        other.status3 == status3 &&
        other.status4 == status4 &&
        other.status5 == status5 &&
        other.status98 == status98 &&
        other.status99 == status99 &&
        other.statusHighlightedText == statusHighlightedText &&
        other.outline == outline &&
        other.outlineVariant == outlineVariant &&
        other.dividerColor == dividerColor &&
        other.audioPlayerBackground == audioPlayerBackground &&
        other.audioPlayerIcon == audioPlayerIcon &&
        other.audioBookmark == audioBookmark &&
        other.audioError == audioError &&
        other.audioErrorBackground == audioErrorBackground;
  }
  
  @override
  int get hashCode => Object.hash(
    textPrimary,
    textSecondary,
    textDisabled,
    textHeadline,
    textOnPrimary,
    textOnSecondary,
    background,
    surface,
    surfaceVariant,
    surfaceContainerHighest,
    bookCardBackground,
    tooltipBackground,
    success,
    onSuccess,
    warning,
    onWarning,
    error,
    onError,
    info,
    onInfo,
    connected,
    disconnected,
    aiProviderBadge,
    localProviderBadge,
    status0,
    status1,
    status2,
    status3,
    status4,
    status5,
    status98,
    status99,
    statusHighlightedText,
    outline,
    outlineVariant,
    dividerColor,
    audioPlayerBackground,
    audioPlayerIcon,
    audioBookmark,
    audioError,
    audioErrorBackground,
  );
}
```

#### 2. `lib/shared/theme/theme_presets.dart`

```dart
import 'package:flutter/material.dart';
import 'theme_definitions.dart';

/// Dark theme preset - extracted from existing app colors
final AppThemeColorScheme darkThemePreset = AppThemeColorScheme(
  // Text colors
  textPrimary: const Color(0xFFE6E1E5),
  textSecondary: const Color(0xFFCAC4D0),
  textDisabled: const Color(0xFF938F99),
  textHeadline: const Color(0xFFE6E1E5),
  textOnPrimary: const Color(0xFFFFFFFF),
  textOnSecondary: const Color(0xFFFFFFFF),
  
  // Background colors
  background: const Color(0xFF48484a), // Dark grey paper from Lute theme
  surface: const Color(0xFF1E1E1E), // Cards
  surfaceVariant: const Color(0xFF2A2A2A),
  surfaceContainerHighest: const Color(0xFF49454F), // Headers/navigation
  bookCardBackground: const Color(0xFF1E1E1E),
  tooltipBackground: const Color(0xFF1E1E1E),
  
  // Semantic colors
  success: const Color(0xFF419252),
  onSuccess: const Color(0xFFFFFFFF),
  warning: const Color(0xFFBA8050),
  onWarning: const Color(0xFFFFFFFF),
  error: const Color(0xFFBA1A1A),
  onError: const Color(0xFFFFFFFF),
  info: const Color(0xFF8095FF),
  onInfo: const Color(0xFFFFFFFF),
  connected: const Color(0xFF419252),
  disconnected: const Color(0xFFBA1A1A),
  
  // Provider colors
  aiProviderBadge: const Color(0xFF6750A4),
  localProviderBadge: const Color(0xFF1976D2),
  
  // Status colors (from AppStatusColors)
  status0: const Color(0xFF8095FF), // Light blue - unknown
  status1: const Color(0x99b46b7a), // Rosy brown (0.6 opacity)
  status2: const Color(0x99BA8050), // Burnt orange (0.6 opacity)
  status3: const Color(0x99BD9C7B), // Tan (0.6 opacity)
  status4: const Color(0x99756D6B), // Dark gray (0.6 opacity)
  status5: const Color(0x3377706E), // Gray (0.2 opacity)
  status98: Colors.transparent, // No color - ignored terms
  status99: const Color(0xFF419252), // Green - known
  statusHighlightedText: const Color(0xFFeff1f2),
  
  // Border colors
  outline: const Color(0xFF938F99),
  outlineVariant: const Color(0xFF49454F),
  dividerColor: const Color(0xFF49454F),
  
  // Audio player colors
  audioPlayerBackground: const Color(0xFF6750A4), // Uses accent button color
  audioPlayerIcon: Colors.white,
  audioBookmark: const Color(0xFFFFA000),
  audioError: const Color(0xFFD32F2F),
  audioErrorBackground: const Color(0x33FFCDD2),
);

/// Light theme preset - softer reading-friendly colors (not pure white)
final AppThemeColorScheme lightThemePreset = AppThemeColorScheme(
  // Text colors - softer than pure black
  textPrimary: const Color(0xFF2C2C2C),
  textSecondary: const Color(0xFF5C5C5C),
  textDisabled: const Color(0xFF9E9E9E),
  textHeadline: const Color(0xFF1A1A1A),
  textOnPrimary: const Color(0xFFFFFFFF),
  textOnSecondary: const Color(0xFFFFFFFF),
  
  // Background colors - warm off-whites, not pure white
  background: const Color(0xFFF5F3EF), // Warm off-white paper
  surface: const Color(0xFFFFFFFF), // Pure white cards
  surfaceVariant: const Color(0xFFF0EBE5),
  surfaceContainerHighest: const Color(0xFFE8E3DD), // Warm light gray
  bookCardBackground: const Color(0xFFFFFFFF),
  tooltipBackground: const Color(0xFFFFFFFF),
  
  // Semantic colors - same as dark theme
  success: const Color(0xFF419252),
  onSuccess: const Color(0xFFFFFFFF),
  warning: const Color(0xFFBA8050),
  onWarning: const Color(0xFFFFFFFF),
  error: const Color(0xFFBA1A1A),
  onError: const Color(0xFFFFFFFF),
  info: const Color(0xFF8095FF),
  onInfo: const Color(0xFFFFFFFF),
  connected: const Color(0xFF419252),
  disconnected: const Color(0xFFBA1A1A),
  
  // Provider colors - same as dark theme
  aiProviderBadge: const Color(0xFF6750A4),
  localProviderBadge: const Color(0xFF1976D2),
  
  // Status colors - same base colors with slightly less opacity
  status0: const Color(0xCC8095FF), // Light blue - unknown (0.8 opacity)
  status1: const Color(0x88b46b7a), // Rosy brown (0.53 opacity)
  status2: const Color(0x88BA8050), // Burnt orange (0.53 opacity)
  status3: const Color(0x88BD9C7B), // Tan (0.53 opacity)
  status4: const Color(0x88756D6B), // Dark gray (0.53 opacity)
  status5: const Color(0x4477706E), // Gray (0.26 opacity)
  status98: Colors.transparent,
  status99: const Color(0xFF419252), // Green - known
  statusHighlightedText: const Color(0xFF2C2C2C),
  
  // Border colors
  outline: const Color(0xFF79747E),
  outlineVariant: const Color(0xFFE0E0E0),
  dividerColor: const Color(0xFFE0E0E0),
  
  // Audio player colors
  audioPlayerBackground: const Color(0xFF6750A4), // Uses accent button color
  audioPlayerIcon: Colors.white,
  audioBookmark: const Color(0xFFFF8F00),
  audioError: const Color(0xFFD32F2F),
  audioErrorBackground: const Color(0x33FFEBEE),
);
```

---

## **Phase 2: Update Theme System**

### **3. Modify: `lib/shared/theme/app_theme.dart`**

**Changes:**
- Import `theme_definitions.dart` and `theme_presets.dart`
- Update `lightTheme()` to use `lightThemePreset` values instead of `AppColors` constants:
  ```dart
  static ThemeData lightTheme(ThemeSettings themeSettings) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: themeSettings.accentButtonColor,
        onPrimary: lightThemePreset.textOnPrimary,
        primaryContainer: lightThemePreset.surface,
        onPrimaryContainer: lightThemePreset.textPrimary,
        secondary: lightThemePreset.textSecondary,
        onSecondary: lightThemePreset.textOnSecondary,
        secondaryContainer: lightThemePreset.surfaceVariant,
        onSecondaryContainer: lightThemePreset.textPrimary,
        tertiary: lightThemePreset.warning,
        onTertiary: lightThemePreset.onWarning,
        tertiaryContainer: lightThemePreset.surface,
        onTertiaryContainer: lightThemePreset.textPrimary,
        surface: lightThemePreset.surface,
        onSurface: lightThemePreset.textPrimary,
        surfaceContainerHighest: lightThemePreset.surfaceContainerHighest,
        onSurfaceVariant: lightThemePreset.textSecondary,
        outline: lightThemePreset.outline,
        outlineVariant: lightThemePreset.outlineVariant,
        error: lightThemePreset.error,
        onError: lightThemePreset.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: lightThemePreset.textPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: lightThemePreset.textPrimary),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: lightThemePreset.textPrimary),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: lightThemePreset.textHeadline),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: lightThemePreset.textHeadline),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: lightThemePreset.textHeadline),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: lightThemePreset.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: lightThemePreset.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: lightThemePreset.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: lightThemePreset.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: lightThemePreset.textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightThemePreset.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: lightThemePreset.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lightThemePreset.textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: lightThemePreset.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: lightThemePreset.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: lightThemePreset),
        CustomThemeExtension(colors: CustomThemeColors(
          accentLabelColor: themeSettings.accentLabelColor,
          accentButtonColor: themeSettings.accentButtonColor,
        )),
      ],
    );
  }
  ```
- Update `darkTheme()` to use `darkThemePreset` values:
  ```dart
  static ThemeData darkTheme(ThemeSettings themeSettings) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: themeSettings.accentButtonColor,
        onPrimary: darkThemePreset.textOnPrimary,
        primaryContainer: darkThemePreset.surface,
        onPrimaryContainer: darkThemePreset.textPrimary,
        secondary: darkThemePreset.textSecondary,
        onSecondary: darkThemePreset.textOnSecondary,
        secondaryContainer: darkThemePreset.surfaceVariant,
        onSecondaryContainer: darkThemePreset.textPrimary,
        tertiary: darkThemePreset.warning,
        onTertiary: darkThemePreset.onWarning,
        tertiaryContainer: darkThemePreset.surface,
        onTertiaryContainer: darkThemePreset.textPrimary,
        surface: darkThemePreset.background,
        onSurface: darkThemePreset.textPrimary,
        surfaceContainerHighest: darkThemePreset.surfaceContainerHighest,
        onSurfaceVariant: darkThemePreset.textSecondary,
        outline: darkThemePreset.outline,
        outlineVariant: darkThemePreset.outlineVariant,
        error: darkThemePreset.error,
        onError: darkThemePreset.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: darkThemePreset.textPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: darkThemePreset.textPrimary),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: darkThemePreset.textPrimary),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: darkThemePreset.textHeadline),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: darkThemePreset.textHeadline),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: darkThemePreset.textHeadline),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: darkThemePreset.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkThemePreset.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkThemePreset.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkThemePreset.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkThemePreset.textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkThemePreset.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkThemePreset.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkThemePreset.textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: darkThemePreset.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: darkThemePreset.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: darkThemePreset),
        CustomThemeExtension(colors: CustomThemeColors(
          accentLabelColor: themeSettings.accentLabelColor,
          accentButtonColor: themeSettings.accentButtonColor,
        )),
      ],
    );
  }
  ```
- Add `AppThemeColorExtension` class at top of file:
  ```dart
  class AppThemeColorExtension extends ThemeExtension<AppThemeColorExtension> {
    final AppThemeColorScheme colorScheme;

    const AppThemeColorExtension({required this.colorScheme});

    @override
    AppThemeColorExtension copyWith({AppThemeColorScheme? colorScheme}) {
      return AppThemeColorExtension(colorScheme: colorScheme ?? this.colorScheme);
    }

    @override
    AppThemeColorExtension lerp(covariant ThemeExtension<AppThemeColorExtension>? other, double t) {
      if (other is! AppThemeColorExtension) return this;
      return AppThemeColorExtension(
        colorScheme: AppThemeColorScheme(
          textPrimary: Color.lerp(colorScheme.textPrimary, other.colorScheme.textPrimary, t)!,
          textSecondary: Color.lerp(colorScheme.textSecondary, other.colorScheme.textSecondary, t)!,
          textDisabled: Color.lerp(colorScheme.textDisabled, other.colorScheme.textDisabled, t)!,
          textHeadline: Color.lerp(colorScheme.textHeadline, other.colorScheme.textHeadline, t)!,
          textOnPrimary: Color.lerp(colorScheme.textOnPrimary, other.colorScheme.textOnPrimary, t)!,
          textOnSecondary: Color.lerp(colorScheme.textOnSecondary, other.colorScheme.textOnSecondary, t)!,
          background: Color.lerp(colorScheme.background, other.colorScheme.background, t)!,
          surface: Color.lerp(colorScheme.surface, other.colorScheme.surface, t)!,
          surfaceVariant: Color.lerp(colorScheme.surfaceVariant, other.colorScheme.surfaceVariant, t)!,
          surfaceContainerHighest: Color.lerp(colorScheme.surfaceContainerHighest, other.colorScheme.surfaceContainerHighest, t)!,
          bookCardBackground: Color.lerp(colorScheme.bookCardBackground, other.colorScheme.bookCardBackground, t)!,
          tooltipBackground: Color.lerp(colorScheme.tooltipBackground, other.colorScheme.tooltipBackground, t)!,
          success: Color.lerp(colorScheme.success, other.colorScheme.success, t)!,
          onSuccess: Color.lerp(colorScheme.onSuccess, other.colorScheme.onSuccess, t)!,
          warning: Color.lerp(colorScheme.warning, other.colorScheme.warning, t)!,
          onWarning: Color.lerp(colorScheme.onWarning, other.colorScheme.onWarning, t)!,
          error: Color.lerp(colorScheme.error, other.colorScheme.error, t)!,
          onError: Color.lerp(colorScheme.onError, other.colorScheme.onError, t)!,
          info: Color.lerp(colorScheme.info, other.colorScheme.info, t)!,
          onInfo: Color.lerp(colorScheme.onInfo, other.colorScheme.onInfo, t)!,
          connected: Color.lerp(colorScheme.connected, other.colorScheme.connected, t)!,
          disconnected: Color.lerp(colorScheme.disconnected, other.colorScheme.disconnected, t)!,
          aiProviderBadge: Color.lerp(colorScheme.aiProviderBadge, other.colorScheme.aiProviderBadge, t)!,
          localProviderBadge: Color.lerp(colorScheme.localProviderBadge, other.colorScheme.localProviderBadge, t)!,
          status0: Color.lerp(colorScheme.status0, other.colorScheme.status0, t)!,
          status1: Color.lerp(colorScheme.status1, other.colorScheme.status1, t)!,
          status2: Color.lerp(colorScheme.status2, other.colorScheme.status2, t)!,
          status3: Color.lerp(colorScheme.status3, other.colorScheme.status3, t)!,
          status4: Color.lerp(colorScheme.status4, other.colorScheme.status4, t)!,
          status5: Color.lerp(colorScheme.status5, other.colorScheme.status5, t)!,
          status98: Color.lerp(colorScheme.status98, other.colorScheme.status98, t)!,
          status99: Color.lerp(colorScheme.status99, other.colorScheme.status99, t)!,
          statusHighlightedText: Color.lerp(colorScheme.statusHighlightedText, other.colorScheme.statusHighlightedText, t)!,
          outline: Color.lerp(colorScheme.outline, other.colorScheme.outline, t)!,
          outlineVariant: Color.lerp(colorScheme.outlineVariant, other.colorScheme.outlineVariant, t)!,
          dividerColor: Color.lerp(colorScheme.dividerColor, other.colorScheme.dividerColor, t)!,
          audioPlayerBackground: Color.lerp(colorScheme.audioPlayerBackground, other.colorScheme.audioPlayerBackground, t)!,
          audioPlayerIcon: Color.lerp(colorScheme.audioPlayerIcon, other.colorScheme.audioPlayerIcon, t)!,
          audioBookmark: Color.lerp(colorScheme.audioBookmark, other.colorScheme.audioBookmark, t)!,
          audioError: Color.lerp(colorScheme.audioError, other.colorScheme.audioError, t)!,
          audioErrorBackground: Color.lerp(colorScheme.audioErrorBackground, other.colorScheme.audioErrorBackground, t)!,
        ),
      );
    }
  }
  ```

### **4. Modify: `lib/shared/theme/theme_extensions.dart`**

**Changes:**
- Update `AppColorSchemeExtension` to get colors from `AppThemeColorExtension`:
  ```dart
  extension AppColorSchemeExtension on ColorScheme {
    AppThemeColorScheme get appColorScheme {
      final extension = Theme.of(Theme.of(this).navigatorKey.currentContext!)
          .extension<AppThemeColorExtension>();
      return extension?.colorScheme ?? darkThemePreset; // Fallback to dark
    }

    // Custom background colors
    Color get bookCardBackground => appColorScheme.bookCardBackground;
    Color get tooltipBackground => appColorScheme.tooltipBackground;

    // Audio player colors
    Color get audioPlayerBackground => appColorScheme.audioPlayerBackground;
    Color get audioPlayerIcon => appColorScheme.audioPlayerIcon;

    // Status colors
    Color get status1 => appColorScheme.status1;
    Color get status2 => appColorScheme.status2;
    Color get status3 => appColorScheme.status3;
    Color get status4 => appColorScheme.status4;
    Color get status5 => appColorScheme.status5;
    Color get status98 => appColorScheme.status98;
    Color get status99 => appColorScheme.status99;
    Color get status0 => appColorScheme.status0;

    // Semantic colors
    Color get success => appColorScheme.success;
    Color get warning => appColorScheme.warning;
    Color get error => appColorScheme.error;
    Color get info => appColorScheme.info;

    // Connection status colors
    Color get connected => appColorScheme.connected;
    Color get disconnected => appColorScheme.disconnected;

    // Provider badge colors
    Color get aiProvider => appColorScheme.aiProviderBadge;
    Color get localProvider => appColorScheme.localProviderBadge;

    // Get status color by status string for text styling
    Color getStatusTextColor(String status) {
      switch (status) {
        case '1':
        case '2':
        case '3':
        case '4':
          return appColorScheme.statusHighlightedText;
        case '5':
        case '98':
        case '99':
          return onSurface;
        case '0':
        default:
          return appColorScheme.status0;
      }
    }

    // Get status background color for highlighting
    Color? getStatusBackgroundColor(String status) {
      switch (status) {
        case '1':
          return appColorScheme.status1;
        case '2':
          return appColorScheme.status2;
        case '3':
          return appColorScheme.status3;
        case '4':
          return appColorScheme.status4;
        case '5':
          return appColorScheme.status5;
        case '0':
        case '98':
        case '99':
        default:
          return null;
      }
    }

    // Get status color by status string (legacy method)
    Color getStatusColor(String status) {
      switch (status) {
        case '1':
          return appColorScheme.status1;
        case '2':
          return appColorScheme.status2;
        case '3':
          return appColorScheme.status3;
        case '4':
          return appColorScheme.status4;
        case '5':
          return appColorScheme.status5;
        case '98':
          return appColorScheme.status98;
        case '99':
          return appColorScheme.status99;
        case '0':
        default:
          return appColorScheme.status0;
      }
    }

    // Get status color with opacity (legacy method)
    Color getStatusColorWithOpacity(String status, {double opacity = 0.1}) {
      return getStatusColor(status).withValues(alpha: opacity);
    }
  }
  ```
- Remove `CustomThemeColorsExtension` (no longer needed, can access via `context.customColors` directly)
- Keep `AppTextThemeExtension` unchanged

---

## **Phase 3: Update Settings Model & Provider**

### **5. Modify: `lib/features/settings/models/settings.dart`**

**Changes to `ThemeSettings` class:**
- Add `final ThemeType themeType = ThemeType.dark;`
- Add `ThemeType?` to `copyWith()` method
- Add `themeType` to `operator ==`
- Add `themeType.hashCode` to `hashCode`
- Keep `accentLabelColor` and `accentButtonColor` unchanged

```dart
class ThemeSettings {
  final ThemeType themeType;
  final Color accentLabelColor;
  final Color accentButtonColor;
  final Color? customAccentLabelColor;
  final Color? customAccentButtonColor;
  
  const ThemeSettings({
    this.themeType = ThemeType.dark,
    this.accentLabelColor = const Color(0xFF1976D2),
    this.accentButtonColor = const Color(0xFF6750A4),
    this.customAccentLabelColor,
    this.customAccentButtonColor,
  });
  
  ThemeSettings copyWith({
    ThemeType? themeType,
    Color? accentLabelColor,
    Color? accentButtonColor,
    Color? customAccentLabelColor,
    Color? customAccentButtonColor,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      accentLabelColor: accentLabelColor ?? this.accentLabelColor,
      // ... etc
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeType == themeType &&
        // ... rest of equality checks
  }
  
  @override
  int get hashCode => Object.hash(
    themeType,
    // ... rest of hash values
  );
}
```

### **6. Modify: `lib/features/settings/providers/settings_provider.dart`**

**Changes:**
- Add storage key: `static const String _themeTypeKey = 'themeType';`
- In `loadSettings()`, load theme type from storage:
  ```dart
  final themeTypeValue = prefs.getString(_themeTypeKey);
  final themeType = themeTypeValue != null
      ? ThemeType.values.firstWhere((e) => e.name == themeTypeValue)
      : ThemeType.dark;
  ```
- In `saveSettings()`, save theme type:
  ```dart
  await prefs.setString(_themeTypeKey, settings.themeSettings.themeType.name);
  ```
- Add new method:
  ```dart
  Future<void> updateThemeType(ThemeType themeType) async {
    final updated = settings.copyWith(
      themeSettings: settings.themeSettings.copyWith(themeType: themeType),
    );
    state = AsyncValue.data(updated);
    await _saveSettings(updated);
  }
  ```
- Ensure backward compatibility: default to `ThemeType.dark` if not set

---

## **Phase 4: Create Theme Selector UI**

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

## **Phase 5: Apply Theme in App**

### **9. Modify: `lib/app.dart`**

**Changes:**
- Add import: `import 'package:lute_for_mobile/shared/theme/theme_presets.dart';`
- Update `themeMode` selection logic to use `ThemeSettings.themeType`:
  ```dart
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
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

### **Dark Theme Preset**
| Category | Property | Color Value | Notes |
|----------|----------|--------------|-------|
| Text | textPrimary | `0xFFE6E1E5` | Light grey font |
| Text | textSecondary | `0xFFCAC4D0` | Lighter grey |
| Text | textDisabled | `0xFF938F99` | Muted grey |
| Text | textHeadline | `0xFFE6E1E5` | Same as primary |
| Text | textOnPrimary | `0xFFFFFFFF` | White |
| Text | textOnSecondary | `0xFFFFFFFF` | White |
| Background | background | `0xFF48484a` | Dark grey paper |
| Background | surface | `0xFF1E1E1E` | Cards |
| Background | surfaceVariant | `0xFF2A2A2A` | Variant surface |
| Background | surfaceContainerHighest | `0xFF49454F` | Headers/nav |
| Background | bookCardBackground | `0xFF1E1E1E` | Book cards |
| Background | tooltipBackground | `0xFF1E1E1E` | Tooltips |
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
| Provider | aiProviderBadge | `0xFF6750A4` | Purple |
| Provider | localProviderBadge | `0xFF1976D2` | Blue |
| Status | status0 | `0xFF8095FF` | Light blue (unknown) |
| Status | status1 | `0x99b46b7a` | Rosy brown (0.6 opacity) |
| Status | status2 | `0x99BA8050` | Burnt orange (0.6 opacity) |
| Status | status3 | `0x99BD9C7B` | Tan (0.6 opacity) |
| Status | status4 | `0x99756D6B` | Dark gray (0.6 opacity) |
| Status | status5 | `0x3377706E` | Gray (0.2 opacity) |
| Status | status98 | `transparent` | No color (ignored) |
| Status | status99 | `0xFF419252` | Green (known) |
| Status | statusHighlightedText | `0xFFeff1f2` | Light text on colored bg |
| Border | outline | `0xFF938F99` | Standard border |
| Border | outlineVariant | `0xFF49454F` | Subtle border |
| Border | dividerColor | `0xFF49454F` | Divider |
| Audio | audioPlayerBackground | `0xFF6750A4` | Accent button color |
| Audio | audioPlayerIcon | `white` | White icons |
| Audio | audioBookmark | `0xFFFFA000` | Amber |
| Audio | audioError | `0xFFD32F2F` | Red |
| Audio | audioErrorBackground | `0x33FFCDD2` | Light red (0.2 opacity) |

### **Light Theme Preset**
| Category | Property | Color Value | Notes |
|----------|----------|--------------|-------|
| Text | textPrimary | `0xFF2C2C2C` | Soft black |
| Text | textSecondary | `0xFF5C5C5C` | Dark grey |
| Text | textDisabled | `0xFF9E9E9E` | Muted grey |
| Text | textHeadline | `0xFF1A1A1A` | Near black |
| Text | textOnPrimary | `0xFFFFFFFF` | White |
| Text | textOnSecondary | `0xFFFFFFFF` | White |
| Background | background | `0xFFF5F3EF` | Warm off-white paper |
| Background | surface | `0xFFFFFFFF` | Pure white cards |
| Background | surfaceVariant | `0xFFF0EBE5` | Warm light grey |
| Background | surfaceContainerHighest | `0xFFE8E3DD` | Header/nav background |
| Background | bookCardBackground | `0xFFFFFFFF` | White book cards |
| Background | tooltipBackground | `0xFFFFFFFF` | White tooltips |
| Semantic | success | `0xFF419252` | Green (same as dark) |
| Semantic | onSuccess | `0xFFFFFFFF` | White (same as dark) |
| Semantic | warning | `0xFFBA8050` | Orange (same as dark) |
| Semantic | onWarning | `0xFFFFFFFF` | White (same as dark) |
| Semantic | error | `0xFFBA1A1A` | Red (same as dark) |
| Semantic | onError | `0xFFFFFFFF` | White (same as dark) |
| Semantic | info | `0xFF8095FF` | Blue (same as dark) |
| Semantic | onInfo | `0xFFFFFFFF` | White (same as dark) |
| Semantic | connected | `0xFF419252` | Green (same as dark) |
| Semantic | disconnected | `0xFFBA1A1A` | Red (same as dark) |
| Provider | aiProviderBadge | `0xFF6750A4` | Purple (same as dark) |
| Provider | localProviderBadge | `0xFF1976D2` | Blue (same as dark) |
| Status | status0 | `0xCC8095FF` | Light blue (0.8 opacity) |
| Status | status1 | `0x88b46b7a` | Rosy brown (0.53 opacity) |
| Status | status2 | `0x88BA8050` | Burnt orange (0.53 opacity) |
| Status | status3 | `0x88BD9C7B` | Tan (0.53 opacity) |
| Status | status4 | `0x88756D6B` | Dark gray (0.53 opacity) |
| Status | status5 | `0x4477706E` | Gray (0.26 opacity) |
| Status | status98 | `transparent` | No color (ignored) |
| Status | status99 | `0xFF419252` | Green (known) |
| Status | statusHighlightedText | `0xFF2C2C2C` | Dark text on colored bg |
| Border | outline | `0xFF79747E` | Standard border |
| Border | outlineVariant | `0xFFE0E0E0` | Subtle border |
| Border | dividerColor | `0xFFE0E0E0` | Divider |
| Audio | audioPlayerBackground | `0xFF6750A4` | Accent button color |
| Audio | audioPlayerIcon | `white` | White icons |
| Audio | audioBookmark | `0xFFFF8F00` | Darker amber |
| Audio | audioError | `0xFFD32F2F` | Red |
| Audio | audioErrorBackground | `0x33FFEBEE` | Light red (0.2 opacity) |

---

## **v1 File Summary**

### **New Files (3)**
1. `lib/shared/theme/theme_definitions.dart` - Data structures
2. `lib/shared/theme/theme_presets.dart` - Preset values
3. `lib/features/settings/widgets/theme_selector_screen.dart` - UI

### **Modified Files (5)**
1. `lib/shared/theme/app_theme.dart` - Theme application
2. `lib/shared/theme/theme_extensions.dart` - Theme extensions
3. `lib/features/settings/models/settings.dart` - ThemeSettings model
4. `lib/features/settings/providers/settings_provider.dart` - Settings state
5. `lib/features/settings/widgets/settings_screen.dart` - Settings UI
6. `lib/app.dart` - App theme mode

### **No Changes Needed**
- Widget files using theme (auto-update via extensions)
- Accent color functionality
- All other settings functionality
- AppColors and AppStatusColors (deprecated but still work)

---

## **v1 Testing Checklist**

### **Theme Switching**
- [ ] Switch from dark to light theme
- [ ] Switch from light to dark theme
- [ ] Verify theme selection persists after app restart
- [ ] Verify backward compatibility (existing users default to dark)

### **Dark Theme Verification**
- [ ] All text colors readable on backgrounds
- [ ] Status colors display correctly
- [ ] Book cards display correctly
- [ ] Audio player colors appropriate
- [ ] Success/error/warning colors visible
- [ ] Tooltips readable
- [ ] Modals readable
- [ ] Drawer/appropriate colors
- [ ] All semantic colors visible

### **Light Theme Verification**
- [ ] All text colors readable on backgrounds (not too harsh)
- [ ] Status colors visible but not overwhelming (correct opacity)
- [ ] Book cards display correctly
- [ ] Audio player colors appropriate
- [ ] Success/error/warning colors visible
- [ ] Tooltips readable
- [ ] Modals readable
- [ ] Drawer/appropriate colors
- [ ] All semantic colors visible
- [ ] Reading experience comfortable (soft colors, not blinding)

### **Accent Colors**
- [ ] Accent colors work independently in dark mode
- [ ] Accent colors work independently in light mode
- [ ] Changing accent colors doesn't affect theme mode
- [ ] Changing theme mode doesn't affect accent colors

### **UI Elements**
- [ ] Settings screen displays current theme correctly
- [ ] Theme selector screen shows both theme options
- [ ] Radio buttons display correct selection state
- [ ] Switching themes updates immediately
- [ ] Navigation works smoothly

### **All Screens**
- [ ] Home screen looks good in both themes
- [ ] Books screen looks good in both themes
- [ ] Book details dialog looks good
- [ ] Reader screen looks good
- [ ] Sentence reader looks good
- [ ] Term form looks good
- [ ] Parent search looks good
- [ ] Sentence translation looks good
- [ ] Dictionary view looks good
- [ ] Audio player looks good
- [ ] Settings screen looks good

### **Edge Cases**
- [ ] Long text in light theme doesn't cause eye strain
- [ ] Status colors with opacity work correctly
- [ ] Transparent status (98) displays correctly
- [ ] Disabled state colors work in both themes
- [ ] Error states are visible in both themes

---

## **v1 Implementation Order**

1. Create `theme_definitions.dart` (enums + AppThemeColorScheme class)
2. Create `theme_presets.dart` with darkThemePreset and lightThemePreset
3. Add `AppThemeColorExtension` class to `app_theme.dart`
4. Update `app_theme.dart` methods to use preset values
5. Update `settings.dart` model with ThemeType field
6. Update `settings_provider.dart` to save/load theme type
7. Update `theme_extensions.dart` to use AppThemeColorExtension
8. Create `theme_selector_screen.dart` (simple selector, no previews)
9. Update `settings_screen.dart` to add Theme section
10. Update `app.dart` to apply theme mode based on selection
11. Test thoroughly

---

## **Notes for v2**
- Custom theme editor will reuse `AppThemeColorScheme`
- Add `ThemeType.custom` enum value
- Theme preview widgets in theme selector (show samples of text, colors, status badges)
- Status mode toggles (background/text) will be added
- JSON serialization will be needed for custom themes
- Color contrast validation optional
- More preset themes (Sepia, High Contrast) can be added
