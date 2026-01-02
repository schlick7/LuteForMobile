import 'package:flutter/material.dart';

enum ThemeType { dark, light }

@immutable
class TextColors {
  final Color primary;
  final Color secondary;
  final Color disabled;
  final Color headline;
  final Color onPrimary;
  final Color onSecondary;
  final Color onPrimaryContainer;
  final Color onSecondaryContainer;
  final Color onTertiary;
  final Color onTertiaryContainer;

  const TextColors({
    required this.primary,
    required this.secondary,
    required this.disabled,
    required this.headline,
    required this.onPrimary,
    required this.onSecondary,
    required this.onPrimaryContainer,
    required this.onSecondaryContainer,
    required this.onTertiary,
    required this.onTertiaryContainer,
  });

  TextColors copyWith({
    Color? primary,
    Color? secondary,
    Color? disabled,
    Color? headline,
    Color? onPrimary,
    Color? onSecondary,
    Color? onPrimaryContainer,
    Color? onSecondaryContainer,
    Color? onTertiary,
    Color? onTertiaryContainer,
  }) {
    return TextColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      disabled: disabled ?? this.disabled,
      headline: headline ?? this.headline,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      onTertiary: onTertiary ?? this.onTertiary,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextColors &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.disabled == disabled &&
        other.headline == headline &&
        other.onPrimary == onPrimary &&
        other.onSecondary == onSecondary &&
        other.onPrimaryContainer == onPrimaryContainer &&
        other.onSecondaryContainer == onSecondaryContainer &&
        other.onTertiary == onTertiary &&
        other.onTertiaryContainer == onTertiaryContainer;
  }

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    disabled,
    headline,
    onPrimary,
    onSecondary,
    onPrimaryContainer,
    onSecondaryContainer,
    onTertiary,
    onTertiaryContainer,
  );
}

@immutable
class BackgroundColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainerHighest;

  const BackgroundColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainerHighest,
  });

  BackgroundColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceContainerHighest,
  }) {
    return BackgroundColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundColors &&
        other.background == background &&
        other.surface == surface &&
        other.surfaceVariant == surfaceVariant &&
        other.surfaceContainerHighest == surfaceContainerHighest;
  }

  @override
  int get hashCode =>
      Object.hash(background, surface, surfaceVariant, surfaceContainerHighest);
}

@immutable
class SemanticColors {
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
  final Color aiProvider;
  final Color localProvider;

  const SemanticColors({
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
    required this.aiProvider,
    required this.localProvider,
  });

  SemanticColors copyWith({
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
    Color? aiProvider,
    Color? localProvider,
  }) {
    return SemanticColors(
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
      aiProvider: aiProvider ?? this.aiProvider,
      localProvider: localProvider ?? this.localProvider,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticColors &&
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
        other.aiProvider == aiProvider &&
        other.localProvider == localProvider;
  }

  @override
  int get hashCode => Object.hash(
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
    aiProvider,
    localProvider,
  );
}

@immutable
class StatusColors {
  final Color status0;
  final Color status1;
  final Color status2;
  final Color status3;
  final Color status4;
  final Color status5;
  final Color status98;
  final Color status99;
  final Color highlightedText;

  const StatusColors({
    required this.status0,
    required this.status1,
    required this.status2,
    required this.status3,
    required this.status4,
    required this.status5,
    required this.status98,
    required this.status99,
    required this.highlightedText,
  });

  StatusColors copyWith({
    Color? status0,
    Color? status1,
    Color? status2,
    Color? status3,
    Color? status4,
    Color? status5,
    Color? status98,
    Color? status99,
    Color? highlightedText,
  }) {
    return StatusColors(
      status0: status0 ?? this.status0,
      status1: status1 ?? this.status1,
      status2: status2 ?? this.status2,
      status3: status3 ?? this.status3,
      status4: status4 ?? this.status4,
      status5: status5 ?? this.status5,
      status98: status98 ?? this.status98,
      status99: status99 ?? this.status99,
      highlightedText: highlightedText ?? this.highlightedText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusColors &&
        other.status0 == status0 &&
        other.status1 == status1 &&
        other.status2 == status2 &&
        other.status3 == status3 &&
        other.status4 == status4 &&
        other.status5 == status5 &&
        other.status98 == status98 &&
        other.status99 == status99 &&
        other.highlightedText == highlightedText;
  }

  @override
  int get hashCode => Object.hash(
    status0,
    status1,
    status2,
    status3,
    status4,
    status5,
    status98,
    status99,
    highlightedText,
  );
}

@immutable
class BorderColors {
  final Color outline;
  final Color outlineVariant;
  final Color dividerColor;

  const BorderColors({
    required this.outline,
    required this.outlineVariant,
    required this.dividerColor,
  });

  BorderColors copyWith({
    Color? outline,
    Color? outlineVariant,
    Color? dividerColor,
  }) {
    return BorderColors(
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorderColors &&
        other.outline == outline &&
        other.outlineVariant == outlineVariant &&
        other.dividerColor == dividerColor;
  }

  @override
  int get hashCode => Object.hash(outline, outlineVariant, dividerColor);
}

@immutable
class AudioColors {
  final Color background;
  final Color icon;
  final Color bookmark;
  final Color error;
  final Color errorBackground;

  const AudioColors({
    required this.background,
    required this.icon,
    required this.bookmark,
    required this.error,
    required this.errorBackground,
  });

  AudioColors copyWith({
    Color? background,
    Color? icon,
    Color? bookmark,
    Color? error,
    Color? errorBackground,
  }) {
    return AudioColors(
      background: background ?? this.background,
      icon: icon ?? this.icon,
      bookmark: bookmark ?? this.bookmark,
      error: error ?? this.error,
      errorBackground: errorBackground ?? this.errorBackground,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioColors &&
        other.background == background &&
        other.icon == icon &&
        other.bookmark == bookmark &&
        other.error == error &&
        other.errorBackground == errorBackground;
  }

  @override
  int get hashCode =>
      Object.hash(background, icon, bookmark, error, errorBackground);
}

@immutable
class ErrorColors {
  final Color error;
  final Color onError;

  const ErrorColors({required this.error, required this.onError});

  ErrorColors copyWith({Color? error, Color? onError}) {
    return ErrorColors(
      error: error ?? this.error,
      onError: onError ?? this.onError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorColors &&
        other.error == error &&
        other.onError == onError;
  }

  @override
  int get hashCode => Object.hash(error, onError);
}

@immutable
class Material3ColorScheme {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color primaryContainer;
  final Color secondaryContainer;
  final Color tertiaryContainer;

  const Material3ColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.tertiaryContainer,
  });

  Material3ColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? primaryContainer,
    Color? secondaryContainer,
    Color? tertiaryContainer,
  }) {
    return Material3ColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material3ColorScheme &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.tertiary == tertiary &&
        other.primaryContainer == primaryContainer &&
        other.secondaryContainer == secondaryContainer &&
        other.tertiaryContainer == tertiaryContainer;
  }

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    tertiary,
    primaryContainer,
    secondaryContainer,
    tertiaryContainer,
  );
}

@immutable
class AppThemeColorScheme {
  final TextColors text;
  final BackgroundColors background;
  final SemanticColors semantic;
  final StatusColors status;
  final BorderColors border;
  final AudioColors audio;
  final ErrorColors error;
  final Material3ColorScheme material3;

  const AppThemeColorScheme({
    required this.text,
    required this.background,
    required this.semantic,
    required this.status,
    required this.border,
    required this.audio,
    required this.error,
    required this.material3,
  });

  AppThemeColorScheme copyWith({
    TextColors? text,
    BackgroundColors? background,
    SemanticColors? semantic,
    StatusColors? status,
    BorderColors? border,
    AudioColors? audio,
    ErrorColors? error,
    Material3ColorScheme? material3,
  }) {
    return AppThemeColorScheme(
      text: text ?? this.text,
      background: background ?? this.background,
      semantic: semantic ?? this.semantic,
      status: status ?? this.status,
      border: border ?? this.border,
      audio: audio ?? this.audio,
      error: error ?? this.error,
      material3: material3 ?? this.material3,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppThemeColorScheme &&
        other.text == text &&
        other.background == background &&
        other.semantic == semantic &&
        other.status == status &&
        other.border == border &&
        other.audio == audio &&
        other.error == error &&
        other.material3 == material3;
  }

  @override
  int get hashCode => Object.hash(
    text,
    background,
    semantic,
    status,
    border,
    audio,
    error,
    material3,
  );
}
