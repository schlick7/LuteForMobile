import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

/// State of the on-device lute-v3 server.
enum EmbeddedServerState {
  /// Process being spawned, waiting for /info 200.
  starting,

  /// Process is alive and responding.
  running,

  /// Last operation failed; see [EmbeddedServerSnapshot.lastError].
  error,
}

/// Snapshot of the on-device server. The server, when running, is
/// always at `http://127.0.0.1:<port>/` where `<port>` is whatever
/// ephemeral port Kotlin picked. The Dart side never needs to know
/// the port number — it just uses [url].
class EmbeddedServerSnapshot {
  final EmbeddedServerState state;
  final String? installedVersion;
  final String pinnedVersion;

  /// Last error message (when [state] == [EmbeddedServerState.error]).
  final String? lastError;

  /// URL of the running server, e.g. `http://127.0.0.1:51234/`.
  /// Null when the server isn't running.
  final String? url;

  const EmbeddedServerSnapshot({
    required this.state,
    this.installedVersion,
    required this.pinnedVersion,
    this.lastError,
    this.url,
  });

  factory EmbeddedServerSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final stateStr = map['state'] as String? ?? 'notInstalled';
    final state = EmbeddedServerState.values.firstWhere(
      (s) => s.name == stateStr,
      orElse: () => EmbeddedServerState.error,
    );
    final port = map['port'] as int?;
    return EmbeddedServerSnapshot(
      state: state,
      installedVersion: map['installedVersion'] as String?,
      pinnedVersion:
          map['pinnedVersion'] as String? ?? Settings.luteServerPinnedVersion,
      url: port == null ? null : 'http://127.0.0.1:$port/',
    );
  }

  @override
  String toString() =>
      'EmbeddedServerSnapshot(state: $state, version: $installedVersion, '
      'pinned: $pinnedVersion, url: $url)';
}

/// Dart facade for the on-device lute-v3 server.
///
/// All real work happens in Kotlin (see `EmbeddedServerBridge.kt`).
/// This class is a singleton because there is exactly one on-device
/// server per app process.
class EmbeddedServerService {
  static const _methodChannel =
      MethodChannel('com.schlick7.luteformobile/embedded_server');
  static const _eventChannel =
      EventChannel('com.schlick7.luteformobile/embedded_server_progress');

  static EmbeddedServerService? _instance;
  static EmbeddedServerService get instance =>
      _instance ??= EmbeddedServerService._();

  EmbeddedServerService._() {
    if (!kIsWeb && Platform.isAndroid) {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: (e) {
          print('EmbeddedServerService event error: $e');
        },
      );
    }
  }

  StreamSubscription<dynamic>? _eventSubscription;
  EmbeddedServerSnapshot _snapshot = EmbeddedServerSnapshot(
    state: EmbeddedServerState.running,
    pinnedVersion: Settings.luteServerPinnedVersion,
  );
  final _snapshotController =
      StreamController<EmbeddedServerSnapshot>.broadcast();
  final _logController = StreamController<String>.broadcast();
  String? _lastError;
  List<String> _recentLogs = const [];

  /// Current snapshot of the on-device server state.
  EmbeddedServerSnapshot get snapshot => _snapshot;

  /// Broadcast of state changes. Listeners are notified on every event
  /// from the Kotlin side, plus on [refresh] calls.
  Stream<EmbeddedServerSnapshot> get stream => _snapshotController.stream;

  void _handleEvent(dynamic raw) {
    if (raw is! Map) return;
    final type = raw['type'] as String? ?? '';
    switch (type) {
      case 'started':
        final port = raw['port'] as int?;
        _lastError = null;
        _snapshot = EmbeddedServerSnapshot(
          state: EmbeddedServerState.running,
          installedVersion: _snapshot.installedVersion,
          pinnedVersion: _snapshot.pinnedVersion,
          url: port == null ? null : 'http://127.0.0.1:$port/',
        );
        _snapshotController.add(_snapshot);
        break;
      case 'stopped':
        _setState(EmbeddedServerState.running);
        // 'running' as the "not running, ready to start" state.
        break;
      case 'log':
        final line = raw['line'] as String? ?? '';
        if (line.isNotEmpty) {
          _recentLogs = [..._recentLogs, line];
          // Keep the in-memory buffer bounded too.
          if (_recentLogs.length > 200) {
            _recentLogs = _recentLogs.sublist(_recentLogs.length - 200);
          }
          _logController.add(line);
        }
        break;
      case 'error':
        _lastError = raw['message'] as String?;
        _setState(EmbeddedServerState.error);
        break;
    }
  }

  void _setState(EmbeddedServerState state) {
    _snapshot = EmbeddedServerSnapshot(
      state: state,
      installedVersion: _snapshot.installedVersion,
      pinnedVersion: _snapshot.pinnedVersion,
      lastError: _lastError,
      url: _snapshot.url,
    );
    _snapshotController.add(_snapshot);
  }

  /// Pull the current state from Kotlin (e.g. on app start).
  Future<EmbeddedServerSnapshot> refresh() async {
    if (kIsWeb || !Platform.isAndroid) {
      return _snapshot;
    }
    try {
      final map = await _methodChannel.invokeMapMethod<String, Object>(
        'getState',
      );
      if (map != null) {
        _snapshot = EmbeddedServerSnapshot.fromMap(map);
        if (_lastError != null) {
          _snapshot = EmbeddedServerSnapshot(
            state: _snapshot.state,
            installedVersion: _snapshot.installedVersion,
            pinnedVersion: _snapshot.pinnedVersion,
            url: _snapshot.url,
            lastError: _lastError,
          );
        }
        _snapshotController.add(_snapshot);
      }
    } on PlatformException catch (e) {
      print('EmbeddedServerService.refresh: ${e.message}');
    }
    return _snapshot;
  }

  /// Start the bundled server. Returns the bound URL.
  /// The server is bundled into the APK via Chaquopy; no download
  /// or install step is needed.
  Future<String> start() async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('On-device server is Android-only');
    }
    _setState(EmbeddedServerState.starting);
    try {
      final port = await _methodChannel.invokeMethod<int>('start');
      if (port == null) {
        throw StateError('start returned null port');
      }
      final url = 'http://127.0.0.1:$port/';
      _snapshot = EmbeddedServerSnapshot(
        state: EmbeddedServerState.running,
        installedVersion: _snapshot.installedVersion,
        pinnedVersion: _snapshot.pinnedVersion,
        url: url,
      );
      _snapshotController.add(_snapshot);
      return url;
    } on PlatformException catch (e) {
      _lastError = e.message;
      _setState(EmbeddedServerState.error);
      rethrow;
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      print('EmbeddedServerService.stop: ${e.message}');
    }
  }

  /// Absolute path of the lute data dir (where lute.db lives).
  /// Used by the first-time flow to drop in a restored backup.
  Future<String> luteDataDir() async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('On-device server is Android-only');
    }
    return await _methodChannel.invokeMethod<String>('dataDir') ?? '';
  }

  /// Restore the embedded lute.db from a gzipped sqlite dump.
  /// Returns true on success. The Kotlin side does the gzip
  /// decompression and atomic file replacement. The caller is
  /// expected to have stopped the server first.
  Future<bool> restoreBackup(String gzPath) async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('On-device server is Android-only');
    }
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('restoreBackup', {
        'path': gzPath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('EmbeddedServerService.restoreBackup: ${e.message}');
      return false;
    }
  }

  /// Most recent error string (if any).
  String? get lastError => _lastError;

  /// Stream of Python stdout/stderr lines from the server process.
  /// Emits one line at a time as the server runs. Lines are also
  /// retained in [recentLogs] for late subscribers.
  Stream<String> get logs => _logController.stream;

  /// Last ~200 log lines from the running server. Useful for showing
  /// the user a snapshot when the server has already exited.
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  /// Fetch the full Python log buffer from Kotlin. Returns a possibly
  /// larger set than [recentLogs] (Kotlin's ring buffer is also 200
  /// lines, so in practice they match). Used on error to show
  /// everything the server said before it died.
  Future<List<String>> fetchLogs() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    try {
      final result = await _methodChannel.invokeListMethod<String>('getLogs');
      if (result != null) {
        _recentLogs = result;
      }
      return result ?? const [];
    } on PlatformException catch (e) {
      print('EmbeddedServerService.fetchLogs: ${e.message}');
      return const [];
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _snapshotController.close();
    _logController.close();
  }
}
