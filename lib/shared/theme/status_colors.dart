import 'package:flutter/material.dart';

class AppStatusColors {
  static const Color status0 = Color(0xFF8095FF); // Light blue - unknown
  static const Color status1 = Color(0xFFb46b7a); // Rosy brown - hardest
  static const Color status2 = Color(0xFFBA8050); // Burnt orange
  static const Color status3 = Color(0xFFBD9C7B); // Tan
  static const Color status4 = Color(0xFF756D6B); // Dark gray
  static const Color status5 = Color(
    0x80756D6B,
  ); // Dark gray with 50% transparency
  static const Color status98 = Color(
    0xFF8095FF,
  ); // Light blue - ignored (same as status0)
  static const Color status99 = Color(0xFF419252); // Green - known/completed

  // Text color for highlighted backgrounds
  static const Color highlightedText = Color(
    0xFFeff1f2,
  ); // Light text on colored backgrounds

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

  // Get label for status (for dialogs)
  static String getStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'Unknown (0)';
      case 1:
        return 'Learning (1)';
      case 2:
        return 'Learning (2)';
      case 3:
        return 'Learning (3)';
      case 4:
        return 'Learning (4)';
      case 5:
        return 'Learning (5)';
      case 98:
        return 'Ignored (98)';
      case 99:
        return 'Known (99)';
      default:
        return 'Unknown';
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
