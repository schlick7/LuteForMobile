import 'package:flutter/material.dart';
import '../../features/settings/models/settings.dart';
import 'theme_definitions.dart';
import 'theme_presets.dart';

class AppThemeColorExtension extends ThemeExtension<AppThemeColorExtension> {
  final AppThemeColorScheme colorScheme;

  const AppThemeColorExtension({required this.colorScheme});

  @override
  AppThemeColorExtension copyWith({AppThemeColorScheme? colorScheme}) {
    return AppThemeColorExtension(colorScheme: colorScheme ?? this.colorScheme);
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: themeSettings.accentButtonColor,
        onPrimary: lightThemePreset.text.onPrimary,
        primaryContainer: lightThemePreset.material3.primaryContainer,
        onPrimaryContainer: lightThemePreset.text.onPrimaryContainer,
        secondary: lightThemePreset.material3.secondary,
        onSecondary: lightThemePreset.text.onSecondary,
        secondaryContainer: lightThemePreset.material3.secondaryContainer,
        onSecondaryContainer: lightThemePreset.text.onSecondaryContainer,
        tertiary: lightThemePreset.material3.tertiary,
        onTertiary: lightThemePreset.text.onTertiary,
        tertiaryContainer: lightThemePreset.material3.tertiaryContainer,
        onTertiaryContainer: lightThemePreset.text.onTertiaryContainer,
        surface: lightThemePreset.background.surface,
        onSurface: lightThemePreset.text.primary,
        surfaceContainerHighest:
            lightThemePreset.background.surfaceContainerHighest,
        onSurfaceVariant: lightThemePreset.text.secondary,
        outline: lightThemePreset.border.outline,
        outlineVariant: lightThemePreset.border.outlineVariant,
        error: lightThemePreset.error.error,
        onError: lightThemePreset.error.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.headline,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.headline,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.headline,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightThemePreset.text.secondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightThemePreset.text.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeSettings.accentButtonColor,
          foregroundColor: lightThemePreset.text.onPrimary,
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
        color: lightThemePreset.background.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: lightThemePreset),
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
    print(
      'DEBUG: AppTheme.darkTheme() called with accentLabelColor: ${themeSettings.accentLabelColor}',
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: themeSettings.accentButtonColor,
        onPrimary: darkThemePreset.text.onPrimary,
        primaryContainer: darkThemePreset.material3.primaryContainer,
        onPrimaryContainer: darkThemePreset.text.onPrimaryContainer,
        secondary: darkThemePreset.material3.secondary,
        onSecondary: darkThemePreset.text.onSecondary,
        secondaryContainer: darkThemePreset.material3.secondaryContainer,
        onSecondaryContainer: darkThemePreset.text.onSecondaryContainer,
        tertiary: darkThemePreset.material3.tertiary,
        onTertiary: darkThemePreset.text.onTertiary,
        tertiaryContainer: darkThemePreset.material3.tertiaryContainer,
        onTertiaryContainer: darkThemePreset.text.onTertiaryContainer,
        surface: darkThemePreset.background.background,
        onSurface: darkThemePreset.text.primary,
        surfaceContainerHighest:
            darkThemePreset.background.surfaceContainerHighest,
        onSurfaceVariant: darkThemePreset.text.secondary,
        outline: darkThemePreset.border.outline,
        outlineVariant: darkThemePreset.border.outlineVariant,
        error: darkThemePreset.error.error,
        onError: darkThemePreset.error.onError,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.headline,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.headline,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.headline,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkThemePreset.text.secondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkThemePreset.text.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeSettings.accentButtonColor,
          foregroundColor: darkThemePreset.text.onPrimary,
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
        color: darkThemePreset.background.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppThemeColorExtension(colorScheme: darkThemePreset),
        CustomThemeExtension(
          colors: CustomThemeColors(
            accentLabelColor: themeSettings.accentLabelColor,
            accentButtonColor: themeSettings.accentButtonColor,
          ),
        ),
      ],
    );
  }
}
