import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServerStatusNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void markError() => state = false;
  void markSuccess() => state = true;
}

final serverStatusProvider = NotifierProvider<ServerStatusNotifier, bool>(
  () => ServerStatusNotifier(),
);

class ServerStatus {
  static bool _isReachable = true;
  static final List<VoidCallback> _listeners = [];

  static bool get isReachable => _isReachable;

  static void markError() {
    _isReachable = false;
    _notifyListeners();
  }

  static void markSuccess() {
    _isReachable = true;
    _notifyListeners();
  }

  static void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  static void _notifyListeners() {
    for (final callback in _listeners) {
      callback();
    }
  }
}
