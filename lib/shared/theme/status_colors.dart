import 'package:flutter/material.dart';

class AppStatusColors {
  static const Color status0 = Color(0xFF8095FF); // Light blue - unknown
  static const Color status1 = Color(
    0x99b46b7a,
  ); // Rosy brown - hardest (0.6 opacity)
  static const Color status2 = Color(0x99BA8050); // Burnt orange (0.6 opacity)
  static const Color status3 = Color(0x99BD9C7B); // Tan (0.6 opacity)
  static const Color status4 = Color(0x99756D6B); // Dark gray (0.6 opacity)
  static const Color status5 = Color(0x3377706E); // gray (0.2 opacity)
  static const Color status98 =
      Colors.transparent; // No color - ignored terms display as normal text
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
