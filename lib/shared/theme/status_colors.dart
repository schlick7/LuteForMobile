import 'package:flutter/material.dart';

class AppStatusColors {
  static const Color status1 = Color(0xFFb46b7a); // Rosy brown - hardest
  static const Color status2 = Color(0xFFBA8050); // Burnt orange
  static const Color status3 = Color(0xFFBD9C7B); // Tan
  static const Color status4 = Color(0xFF756D6B); // Dark gray
  static const Color status5 = Color(0xFF9E9E9E); // Medium gray
  static const Color status98 = Color(0xFF8095FF); // Light blue - ignored
  static const Color status99 = Color(0xFF419252); // Green - known/completed
  static const Color status0 = Color(0xFF757575); // Gray - unknown

  // Get status color by status string
  static Color getStatusColor(String status) {
    switch (status) {
      case '1':
        return status1;
      case '2':
        return status2;
      case '3':
        return status3;
      case '4':
        return status4;
      case '5':
        return status5;
      case '98':
        return status98;
      case '99':
        return status99;
      case '0':
      default:
        return status0;
    }
  }

  // Get status color with opacity for backgrounds
  static Color getStatusColorWithOpacity(
    String status, {
    double opacity = 0.1,
  }) {
    return getStatusColor(status).withValues(alpha: opacity);
  }
}
