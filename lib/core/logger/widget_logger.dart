import 'package:flutter/foundation.dart';

class WidgetLogger {
  static bool enableRebuildLogging = kDebugMode;
  static bool enableLifecycleLogging = kDebugMode;

  static void logRebuild(String widgetName, int count, [String? details]) {
    if (enableRebuildLogging) {
      print(
        'REBUILD [$widgetName] #$count${details != null ? ' - $details' : ''}',
      );
    }
  }

  static void logInit(String widgetName) {
    if (enableLifecycleLogging) {
      print('INIT [$widgetName]');
    }
  }

  static void logDispose(String widgetName) {
    if (enableLifecycleLogging) {
      print('DISPOSE [$widgetName]');
    }
  }
}
