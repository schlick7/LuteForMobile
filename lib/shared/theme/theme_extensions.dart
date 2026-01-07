import 'package:flutter/material.dart';
import 'theme_definitions.dart';
import 'theme_presets.dart';
import 'app_theme.dart';

extension BuildContextExtension on BuildContext {
  CustomThemeColors get customColors {
    final extension = Theme.of(this).extension<CustomThemeExtension>();
    return extension?.colors ??
        const CustomThemeColors(
          accentLabelColor: Color(0xFF1976D2),
          accentButtonColor: Color(0xFF6750A4),
        );
  }

  AppThemeColorScheme get appColorScheme {
    final extension = Theme.of(this).extension<AppThemeColorExtension>();
    return extension?.colorScheme ?? darkThemePreset;
  }

  Color get audioPlayerBackground => appColorScheme.audio.background;
  Color get audioPlayerIcon => appColorScheme.audio.icon;

  Color get status1 => appColorScheme.status.status1;
  Color get status2 => appColorScheme.status.status2;
  Color get status3 => appColorScheme.status.status3;
  Color get status4 => appColorScheme.status.status4;
  Color get status5 => appColorScheme.status.status5;
  Color get status98 => appColorScheme.status.status98;
  Color get status99 => appColorScheme.status.status99;
  Color get status0 => appColorScheme.status.status0;
  Color get wordGlowColor => appColorScheme.status.wordGlowColor;

  Color get success => appColorScheme.semantic.success;
  Color get warning => appColorScheme.semantic.warning;
  Color get error => appColorScheme.error.error;
  Color get info => appColorScheme.semantic.info;

  Color get connected => appColorScheme.semantic.connected;
  Color get disconnected => appColorScheme.semantic.disconnected;

  Color get aiProvider => appColorScheme.semantic.aiProvider;
  Color get localProvider => appColorScheme.semantic.localProvider;

  Color get m3Primary => appColorScheme.material3.primary;
  Color get m3Secondary => appColorScheme.material3.secondary;
  Color get m3Tertiary => appColorScheme.material3.tertiary;
  Color get m3PrimaryContainer => appColorScheme.material3.primaryContainer;
  Color get m3SecondaryContainer => appColorScheme.material3.secondaryContainer;
  Color get m3TertiaryContainer => appColorScheme.material3.tertiaryContainer;

  Color getStatusTextColor(String status) {
    switch (status) {
      case '1':
        if (appColorScheme.status.isTransparent1) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '2':
        if (appColorScheme.status.isTransparent2) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '3':
        if (appColorScheme.status.isTransparent3) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '4':
        if (appColorScheme.status.isTransparent4) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '5':
        if (appColorScheme.status.isTransparent5) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '98':
        return appColorScheme.text.primary;
      case '99':
        if (appColorScheme.status.isTransparent99) {
          return appColorScheme.text.primary;
        }
        return appColorScheme.status.highlightedText;
      case '0':
      default:
        return appColorScheme.status.status0;
    }
  }

  Color? getStatusBackgroundColor(String status) {
    switch (status) {
      case '1':
        if (appColorScheme.status.isTransparent1) return null;
        return appColorScheme.status.status1;
      case '2':
        if (appColorScheme.status.isTransparent2) return null;
        return appColorScheme.status.status2;
      case '3':
        if (appColorScheme.status.isTransparent3) return null;
        return appColorScheme.status.status3;
      case '4':
        if (appColorScheme.status.isTransparent4) return null;
        return appColorScheme.status.status4;
      case '5':
        if (appColorScheme.status.isTransparent5) return null;
        return appColorScheme.status.status5;
      case '0':
        if (appColorScheme.status.isTransparent0) return null;
        return appColorScheme.status.status0;
      case '98':
        return null;
      case '99':
        if (appColorScheme.status.isTransparent99) return null;
        return appColorScheme.status.status99;
      default:
        return null;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case '1':
        return appColorScheme.status.status1;
      case '2':
        return appColorScheme.status.status2;
      case '3':
        return appColorScheme.status.status3;
      case '4':
        return appColorScheme.status.status4;
      case '5':
        return appColorScheme.status.status5;
      case '98':
        return appColorScheme.status.status98;
      case '99':
        return appColorScheme.status.status99;
      case '0':
      default:
        return appColorScheme.status.status0;
    }
  }

  Color getStatusColorWithOpacity(String status, {double opacity = 0.1}) {
    return getStatusColor(status).withValues(alpha: opacity);
  }
}

extension AppTextThemeExtension on TextTheme {
  TextStyle get statusBadge {
    return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  }

  TextStyle get providerBadge {
    return const TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
  }
}
