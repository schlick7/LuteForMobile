import 'package:flutter/material.dart';
import '../../features/settings/models/settings.dart';
import 'theme_definitions.dart';
import 'theme_presets.dart';

class AppThemeColorExtension extends ThemeExtension<AppThemeColorExtension> {
  final AppThemeColorScheme colorScheme;
  final Map<int, StatusMode> statusModes;

  const AppThemeColorExtension({
    required this.colorScheme,
    required this.statusModes,
  });

  @override
  AppThemeColorExtension copyWith({
    AppThemeColorScheme? colorScheme,
    Map<int, StatusMode>? statusModes,
  }) {
    return AppThemeColorExtension(
      colorScheme: colorScheme ?? this.colorScheme,
      statusModes: statusModes ?? this.statusModes,
    );
  }

  @override
  AppThemeColorExtension lerp(
    covariant ThemeExtension<AppThemeColorExtension>? other,
    double t,
  ) {
    if (other is! AppThemeColorExtension) return this;
    return AppThemeColorExtension(
      colorScheme: AppThemeColorScheme(
        text: TextColors(
          primary: Color.lerp(
            colorScheme.text.primary,
            other.colorScheme.text.primary,
            t,
          )!,
          secondary: Color.lerp(
            colorScheme.text.secondary,
            other.colorScheme.text.secondary,
            t,
          )!,
          disabled: Color.lerp(
            colorScheme.text.disabled,
            other.colorScheme.text.disabled,
            t,
          )!,
          headline: Color.lerp(
            colorScheme.text.headline,
            other.colorScheme.text.headline,
            t,
          )!,
          onPrimary: Color.lerp(
            colorScheme.text.onPrimary,
            other.colorScheme.text.onPrimary,
            t,
          )!,
          onSecondary: Color.lerp(
            colorScheme.text.onSecondary,
            other.colorScheme.text.onSecondary,
            t,
          )!,
          onPrimaryContainer: Color.lerp(
            colorScheme.text.onPrimaryContainer,
            other.colorScheme.text.onPrimaryContainer,
            t,
          )!,
          onSecondaryContainer: Color.lerp(
            colorScheme.text.onSecondaryContainer,
            other.colorScheme.text.onSecondaryContainer,
            t,
          )!,
          onTertiary: Color.lerp(
            colorScheme.text.onTertiary,
            other.colorScheme.text.onTertiary,
            t,
          )!,
          onTertiaryContainer: Color.lerp(
            colorScheme.text.onTertiaryContainer,
            other.colorScheme.text.onTertiaryContainer,
            t,
          )!,
        ),
        background: BackgroundColors(
          background: Color.lerp(
            colorScheme.background.background,
            other.colorScheme.background.background,
            t,
          )!,
          surface: Color.lerp(
            colorScheme.background.surface,
            other.colorScheme.background.surface,
            t,
          )!,
          surfaceVariant: Color.lerp(
            colorScheme.background.surfaceVariant,
            other.colorScheme.background.surfaceVariant,
            t,
          )!,
          surfaceContainerHighest: Color.lerp(
            colorScheme.background.surfaceContainerHighest,
            other.colorScheme.background.surfaceContainerHighest,
            t,
          )!,
        ),
        semantic: SemanticColors(
          success: Color.lerp(
            colorScheme.semantic.success,
            other.colorScheme.semantic.success,
            t,
          )!,
          onSuccess: Color.lerp(
            colorScheme.semantic.onSuccess,
            other.colorScheme.semantic.onSuccess,
            t,
          )!,
          warning: Color.lerp(
            colorScheme.semantic.warning,
            other.colorScheme.semantic.warning,
            t,
          )!,
          onWarning: Color.lerp(
            colorScheme.semantic.onWarning,
            other.colorScheme.semantic.onWarning,
            t,
          )!,
          error: Color.lerp(
            colorScheme.semantic.error,
            other.colorScheme.semantic.error,
            t,
          )!,
          onError: Color.lerp(
            colorScheme.semantic.onError,
            other.colorScheme.semantic.onError,
            t,
          )!,
          info: Color.lerp(
            colorScheme.semantic.info,
            other.colorScheme.semantic.info,
            t,
          )!,
          onInfo: Color.lerp(
            colorScheme.semantic.onInfo,
            other.colorScheme.semantic.onInfo,
            t,
          )!,
          connected: Color.lerp(
            colorScheme.semantic.connected,
            other.colorScheme.semantic.connected,
            t,
          )!,
          disconnected: Color.lerp(
            colorScheme.semantic.disconnected,
            other.colorScheme.semantic.disconnected,
            t,
          )!,
          aiProvider: Color.lerp(
            colorScheme.semantic.aiProvider,
            other.colorScheme.semantic.aiProvider,
            t,
          )!,
          localProvider: Color.lerp(
            colorScheme.semantic.localProvider,
            other.colorScheme.semantic.localProvider,
            t,
          )!,
        ),
        status: StatusColors(
          status0: Color.lerp(
            colorScheme.status.status0,
            other.colorScheme.status.status0,
            t,
          )!,
          status1: Color.lerp(
            colorScheme.status.status1,
            other.colorScheme.status.status1,
            t,
          )!,
          status2: Color.lerp(
            colorScheme.status.status2,
            other.colorScheme.status.status2,
            t,
          )!,
          status3: Color.lerp(
            colorScheme.status.status3,
            other.colorScheme.status.status3,
            t,
          )!,
          status4: Color.lerp(
            colorScheme.status.status4,
            other.colorScheme.status.status4,
            t,
          )!,
          status5: Color.lerp(
            colorScheme.status.status5,
            other.colorScheme.status.status5,
            t,
          )!,
          status98: Color.lerp(
            colorScheme.status.status98,
            other.colorScheme.status.status98,
            t,
          )!,
          status99: Color.lerp(
            colorScheme.status.status99,
            other.colorScheme.status.status99,
            t,
          )!,
          highlightedText: Color.lerp(
            colorScheme.status.highlightedText,
            other.colorScheme.status.highlightedText,
            t,
          )!,
          wordGlowColor: Color.lerp(
            colorScheme.status.wordGlowColor,
            other.colorScheme.status.wordGlowColor,
            t,
          )!,
        ),
        border: BorderColors(
          outline: Color.lerp(
            colorScheme.border.outline,
            other.colorScheme.border.outline,
            t,
          )!,
          outlineVariant: Color.lerp(
            colorScheme.border.outlineVariant,
            other.colorScheme.border.outlineVariant,
            t,
          )!,
          dividerColor: Color.lerp(
            colorScheme.border.dividerColor,
            other.colorScheme.border.dividerColor,
            t,
          )!,
        ),
        audio: AudioColors(
          background: Color.lerp(
            colorScheme.audio.background,
            other.colorScheme.audio.background,
            t,
          )!,
          icon: Color.lerp(
            colorScheme.audio.icon,
            other.colorScheme.audio.icon,
            t,
          )!,
          bookmark: Color.lerp(
            colorScheme.audio.bookmark,
            other.colorScheme.audio.bookmark,
            t,
          )!,
          error: Color.lerp(
            colorScheme.audio.error,
            other.colorScheme.audio.error,
            t,
          )!,
          errorBackground: Color.lerp(
            colorScheme.audio.errorBackground,
            other.colorScheme.audio.errorBackground,
            t,
          )!,
        ),
        error: ErrorColors(
          error: Color.lerp(
            colorScheme.error.error,
            other.colorScheme.error.error,
            t,
          )!,
          onError: Color.lerp(
            colorScheme.error.onError,
            other.colorScheme.error.onError,
            t,
          )!,
        ),
        material3: Material3ColorScheme(
          primary: Color.lerp(
            colorScheme.material3.primary,
            other.colorScheme.material3.primary,
            t,
          )!,
          secondary: Color.lerp(
            colorScheme.material3.secondary,
            other.colorScheme.material3.secondary,
            t,
          )!,
          tertiary: Color.lerp(
            colorScheme.material3.tertiary,
            other.colorScheme.material3.tertiary,
            t,
          )!,
          primaryContainer: Color.lerp(
            colorScheme.material3.primaryContainer,
            other.colorScheme.material3.primaryContainer,
            t,
          )!,
          secondaryContainer: Color.lerp(
            colorScheme.material3.secondaryContainer,
            other.colorScheme.material3.secondaryContainer,
            t,
          )!,
          tertiaryContainer: Color.lerp(
            colorScheme.material3.tertiaryContainer,
            other.colorScheme.material3.tertiaryContainer,
            t,
          )!,
        ),
      ),
      statusModes: t < 0.5 ? statusModes : other.statusModes,
    );
  }
}

@immutable
class CustomThemeColors {
  final Color accentLabelColor;
  final Color accentButtonColor;

  const CustomThemeColors({
    required this.accentLabelColor,
    required this.accentButtonColor,
  });
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final CustomThemeColors colors;

  const CustomThemeExtension({required this.colors});

  @override
  CustomThemeExtension copyWith({CustomThemeColors? colors}) {
    return CustomThemeExtension(colors: colors ?? this.colors);
  }

  @override
  CustomThemeExtension lerp(
    covariant ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    final otherColors = (other as CustomThemeExtension).colors;
    return CustomThemeExtension(
      colors: CustomThemeColors(
        accentLabelColor: Color.lerp(
          colors.accentLabelColor,
          otherColors.accentLabelColor,
          t,
        )!,
        accentButtonColor: Color.lerp(
          colors.accentButtonColor,
          otherColors.accentButtonColor,
          t,
        )!,
      ),
    );
  }

  static CustomThemeColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<CustomThemeExtension>()?.colors ??
        const CustomThemeColors(
          accentLabelColor: Color(0xFF1976D2),
          accentButtonColor: Color(0xFF6750A4),
        );
  }
}

class AppTheme {
  static ThemeData lightTheme(ThemeSettings themeSettings) {
    final scheme = _resolveColorScheme(
      themeSettings,
      themePreset: lightThemePreset,
    );
    final statusModes = _resolveStatusModes(themeSettings);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: themeSettings.accentButtonColor,
        onPrimary: scheme.text.onPrimary,
        primaryContainer: scheme.material3.primaryContainer,
        onPrimaryContainer: scheme.text.onPrimaryContainer,
        secondary: scheme.material3.secondary,
        onSecondary: scheme.text.onSecondary,
        secondaryContainer: scheme.material3.secondaryContainer,
        onSecondaryContainer: scheme.text.onSecondaryContainer,
        tertiary: scheme.material3.tertiary,
        onTertiary: scheme.text.onTertiary,
        tertiaryContainer: scheme.material3.tertiaryContainer,
        onTertiaryContainer: scheme.text.onTertiaryContainer,
        surface: scheme.background.surface,
        onSurface: scheme.text.primary,
        surfaceContainerHighest: scheme.background.surfaceContainerHighest,
        onSurfaceVariant: scheme.text.secondary,
        outline: scheme.border.outline,
        outlineVariant: scheme.border.outlineVariant,
        error: scheme.error.error,
        onError: scheme.error.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.text.secondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeSettings.accentButtonColor,
          foregroundColor: scheme.text.onPrimary,
          elevation: 1,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
          side: const BorderSide(color: Color(0xFF79747E)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.background.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: scheme, statusModes: statusModes),
        CustomThemeExtension(
          colors: CustomThemeColors(
            accentLabelColor: themeSettings.accentLabelColor,
            accentButtonColor: themeSettings.accentButtonColor,
          ),
        ),
      ],
    );
  }

  static ThemeData darkTheme(ThemeSettings themeSettings) {
    final scheme = _resolveColorScheme(
      themeSettings,
      themePreset: darkThemePreset,
    );
    final statusModes = _resolveStatusModes(themeSettings);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: themeSettings.accentButtonColor,
        onPrimary: scheme.text.onPrimary,
        primaryContainer: scheme.material3.primaryContainer,
        onPrimaryContainer: scheme.text.onPrimaryContainer,
        secondary: scheme.material3.secondary,
        onSecondary: scheme.text.onSecondary,
        secondaryContainer: scheme.material3.secondaryContainer,
        onSecondaryContainer: scheme.text.onSecondaryContainer,
        tertiary: scheme.material3.tertiary,
        onTertiary: scheme.text.onTertiary,
        tertiaryContainer: scheme.material3.tertiaryContainer,
        onTertiaryContainer: scheme.text.onTertiaryContainer,
        surface: scheme.background.background,
        onSurface: scheme.text.primary,
        surfaceContainerHighest: scheme.background.surfaceContainerHighest,
        onSurfaceVariant: scheme.text.secondary,
        outline: scheme.border.outline,
        outlineVariant: scheme.border.outlineVariant,
        error: scheme.error.error,
        onError: scheme.error.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.text.secondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeSettings.accentButtonColor,
          foregroundColor: scheme.text.onPrimary,
          elevation: 1,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
          side: const BorderSide(color: Color(0xFF938F99)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.background.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: scheme, statusModes: statusModes),
        CustomThemeExtension(
          colors: CustomThemeColors(
            accentLabelColor: themeSettings.accentLabelColor,
            accentButtonColor: themeSettings.accentButtonColor,
          ),
        ),
      ],
    );
  }

  static ThemeData blackAndWhiteTheme(ThemeSettings themeSettings) {
    final scheme = _resolveColorScheme(
      themeSettings,
      themePreset: blackAndWhiteThemePreset,
    );
    final statusModes = _resolveStatusModes(themeSettings);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: themeSettings.accentButtonColor,
        onPrimary: scheme.text.onPrimary,
        primaryContainer: scheme.material3.primaryContainer,
        onPrimaryContainer: scheme.text.onPrimaryContainer,
        secondary: scheme.material3.secondary,
        onSecondary: scheme.text.onSecondary,
        secondaryContainer: scheme.material3.secondaryContainer,
        onSecondaryContainer: scheme.text.onSecondaryContainer,
        tertiary: scheme.material3.tertiary,
        onTertiary: scheme.text.onTertiary,
        tertiaryContainer: scheme.material3.tertiaryContainer,
        onTertiaryContainer: scheme.text.onTertiaryContainer,
        surface: scheme.background.surface,
        onSurface: scheme.text.primary,
        surfaceContainerHighest: scheme.background.surfaceContainerHighest,
        onSurfaceVariant: scheme.text.secondary,
        outline: scheme.border.outline,
        outlineVariant: scheme.border.outlineVariant,
        error: scheme.error.error,
        onError: scheme.error.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: scheme.text.headline,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.text.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.text.secondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.text.primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.text.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeSettings.accentButtonColor,
          foregroundColor: scheme.text.onPrimary,
          elevation: 1,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeSettings.accentButtonColor,
          side: const BorderSide(color: Color(0xFF999999)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.background.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: scheme, statusModes: statusModes),
        CustomThemeExtension(
          colors: CustomThemeColors(
            accentLabelColor: themeSettings.accentLabelColor,
            accentButtonColor: themeSettings.accentButtonColor,
          ),
        ),
      ],
    );
  }

  static AppThemeColorScheme _resolveColorScheme(
    ThemeSettings themeSettings, {
    required AppThemeColorScheme themePreset,
  }) {
    final selectedUserTheme = themeSettings.selectedUserTheme;
    if (selectedUserTheme != null) {
      return selectedUserTheme.colorScheme;
    }
    return themePreset;
  }

  static Map<int, StatusMode> _resolveStatusModes(ThemeSettings themeSettings) {
    final selectedUserTheme = themeSettings.selectedUserTheme;
    return selectedUserTheme?.statusModes ?? defaultStatusModes();
  }
}
