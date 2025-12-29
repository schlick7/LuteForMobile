import 'package:flutter/material.dart';
import 'colors.dart';
import 'status_colors.dart';

extension AppColorSchemeExtension on ColorScheme {
  // Status colors
  Color get status1 => AppStatusColors.status1;
  Color get status2 => AppStatusColors.status2;
  Color get status3 => AppStatusColors.status3;
  Color get status4 => AppStatusColors.status4;
  Color get status5 => AppStatusColors.status5;
  Color get status98 => AppStatusColors.status98;
  Color get status99 => AppStatusColors.status99;
  Color get status0 => AppStatusColors.status0;

  // Semantic colors
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
  Color get info => AppColors.info;

  // Connection status colors
  Color get connected => AppColors.connected;
  Color get disconnected => AppColors.disconnected;

  // Provider badge colors
  Color get aiProvider => AppColors.aiProvider;
  Color get localProvider => AppColors.localProvider;

  // Get status color by status string
  Color getStatusColor(String status) {
    return AppStatusColors.getStatusColor(status);
  }

  // Get status color with opacity
  Color getStatusColorWithOpacity(String status, {double opacity = 0.1}) {
    return AppStatusColors.getStatusColorWithOpacity(status, opacity: opacity);
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
