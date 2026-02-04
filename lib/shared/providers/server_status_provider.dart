import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServerStatus {
  final bool isReachable;
  final bool isConnecting;

  const ServerStatus({this.isReachable = true, this.isConnecting = false});

  ServerStatus copyWith({bool? isReachable, bool? isConnecting}) {
    return ServerStatus(
      isReachable: isReachable ?? this.isReachable,
      isConnecting: isConnecting ?? this.isConnecting,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerStatus &&
        other.isReachable == isReachable &&
        other.isConnecting == isConnecting;
  }

  @override
  int get hashCode => Object.hash(isReachable, isConnecting);
}

class ServerStatusNotifier extends Notifier<ServerStatus> {
  @override
  ServerStatus build() => const ServerStatus();

  void markOnline() {
    state = state.copyWith(isReachable: true, isConnecting: false);
  }

  void markOffline() {
    state = state.copyWith(isReachable: false);
  }

  void markConnecting() {
    state = state.copyWith(isConnecting: true);
  }
}

final serverStatusProvider =
    NotifierProvider<ServerStatusNotifier, ServerStatus>(() {
      return ServerStatusNotifier();
    });

class ServerStatusManager {
  static bool _isReachable = true;
  static bool _isConnecting = false;
  static bool _initialCheckComplete = false;
  static final List<VoidCallback> _listeners = [];

  static bool get isReachable => _isReachable;
  static bool get isConnecting => _isConnecting;
  static bool get initialCheckComplete => _initialCheckComplete;

  static void setReachable(bool value) {
    _isReachable = value;
    _isConnecting = false;
    _notifyListeners();
  }

  static void setConnecting() {
    _isConnecting = true;
    _notifyListeners();
  }

  static void setInitialCheckComplete(bool value) {
    _initialCheckComplete = value;
    _notifyListeners();
  }

  static void markError() {
    _isReachable = false;
    _notifyListeners();
  }

  static void markSuccess() {
    _isReachable = true;
    _isConnecting = false;
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
