import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lute_for_mobile/core/services/lute_server_manifest.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

/// State of the on-device lute-v3 server.
enum EmbeddedServerState {
  /// No artifact installed under the pinned version.
  notInstalled,

  /// Download in progress.
  downloading,

  /// Artifact extracted, not running.
  ready,

  /// Process being spawned, waiting for /info 200.
  starting,

  /// Process is alive and responding.
  running,

  /// Last operation failed; see [EmbeddedServerSnapshot.lastError].
  error,
}

/// Snapshot of the on-device server as reported by Kotlin.
class EmbeddedServerSnapshot {
  final EmbeddedServerState state;
  final String? installedVersion;
  final String pinnedVersion;
  final int? port;

  /// Last error message (when [state] == [EmbeddedServerState.error]).
  final String? lastError;

  /// Optional URL of the running server, e.g. `http://127.0.0.1:51234/`.
  final String? url;

  const EmbeddedServerSnapshot({
    required this.state,
    this.installedVersion,
    required this.pinnedVersion,
    this.port,
    this.lastError,
    this.url,
  });

  factory EmbeddedServerSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final stateStr = map['state'] as String? ?? 'notInstalled';
    final state = EmbeddedServerState.values.firstWhere(
      (s) => s.name == stateStr,
      orElse: () => EmbeddedServerState.notInstalled,
    );
    final port = map['port'] as int?;
    return EmbeddedServerSnapshot(
      state: state,
      installedVersion: map['installedVersion'] as String?,
      pinnedVersion:
          map['pinnedVersion'] as String? ?? Settings.luteServerPinnedVersion,
      port: port,
      url: port == null ? null : 'http://127.0.0.1:$port/',
    );
  }

  @override
  String toString() =>
      'EmbeddedServerSnapshot(state: $state, version: $installedVersion, '
      'pinned: $pinnedVersion, port: $port)';
}

/// Info about the downloadable lute-server tarball.
class TarballInfo {
  final String pinnedVersion;
  final String tarballUrl;
  final String sha256Url;
  const TarballInfo({
    required this.pinnedVersion,
    required this.tarballUrl,
    required this.sha256Url,
  });

  factory TarballInfo.fromMap(Map<dynamic, dynamic> map) {
    return TarballInfo(
      pinnedVersion: map['pinnedVersion'] as String? ?? '',
      tarballUrl: map['tarballUrl'] as String? ?? '',
      sha256Url: map['sha256Url'] as String? ?? '',
    );
  }
}

/// Result of an update check against GitHub.
class UpdateCheckResult {
  final String? latestTag;
  final bool updateAvailable;
  final String? error;
  const UpdateCheckResult({
    this.latestTag,
    required this.updateAvailable,
    this.error,
  });

  factory UpdateCheckResult.fromMap(Map<dynamic, dynamic> map) {
    return UpdateCheckResult(
      latestTag: map['latestTag'] as String?,
      updateAvailable: (map['updateAvailable'] as bool?) ?? false,
      error: map['error'] as String?,
    );
  }
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
    state: EmbeddedServerState.notInstalled,
    pinnedVersion: Settings.luteServerPinnedVersion,
  );
  final _snapshotController =
      StreamController<EmbeddedServerSnapshot>.broadcast();
  String? _lastError;

  /// Current snapshot of the on-device server state.
  EmbeddedServerSnapshot get snapshot => _snapshot;

  /// Broadcast of state changes. Listeners are notified on every event
  /// from the Kotlin side, plus on [refresh] calls.
  Stream<EmbeddedServerSnapshot> get stream => _snapshotController.stream;

  void _handleEvent(dynamic raw) {
    if (raw is! Map) return;
    final type = raw['type'] as String? ?? '';
    switch (type) {
      case 'download_progress':
        final done = (raw['bytesDone'] as num?)?.toInt() ?? 0;
        final total = (raw['bytesTotal'] as num?)?.toInt() ?? 0;
        _progressController.add(DownloadProgress(done, total));
        break;
      case 'download_complete':
        _lastError = null;
        _setState(EmbeddedServerState.ready);
        break;
      case 'download_error':
        _lastError = raw['message'] as String?;
        _setState(EmbeddedServerState.error);
        break;
      case 'started':
        final port = raw['port'] as int?;
        _lastError = null;
        _snapshot = EmbeddedServerSnapshot(
          state: EmbeddedServerState.running,
          installedVersion: _snapshot.installedVersion,
          pinnedVersion: _snapshot.pinnedVersion,
          port: port,
          url: port == null ? null : 'http://127.0.0.1:$port/',
        );
        _snapshotController.add(_snapshot);
        break;
      case 'stopped':
        _setState(EmbeddedServerState.ready);
        break;
      case 'error':
        _lastError = raw['message'] as String?;
        _setState(EmbeddedServerState.error);
        break;
      case 'log':
        // Captured by the log stream separately; nothing to do here.
        break;
    }
  }

  void _setState(EmbeddedServerState state) {
    _snapshot = EmbeddedServerSnapshot(
      state: state,
      installedVersion: _snapshot.installedVersion,
      pinnedVersion: _snapshot.pinnedVersion,
      port: _snapshot.port,
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
            port: _snapshot.port,
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

  /// Returns metadata about the pinned tarball (for the UI to display).
  Future<TarballInfo> getTarballInfo() async {
    if (kIsWeb || !Platform.isAndroid) {
      return TarballInfo(
        pinnedVersion: Settings.luteServerPinnedVersion,
        tarballUrl: LuteServerManifest.arm64TarballUrl,
        sha256Url: LuteServerManifest.arm64Sha256Url,
      );
    }
    final map = await _methodChannel.invokeMapMethod<String, Object>(
      'getTarballInfo',
    );
    if (map == null) {
      throw StateError('Kotlin returned null tarball info');
    }
    return TarballInfo.fromMap(map);
  }

  /// Start a background download. Resolves immediately; the actual
  /// download is observed via [stream] (and the [downloadProgressStream]
  /// for byte-level progress).
  Future<void> download() async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('On-device server is Android-only');
    }
    _lastError = null;
    _setState(EmbeddedServerState.downloading);
    try {
      await _methodChannel.invokeMethod<void>('download');
    } on PlatformException catch (e) {
      _lastError = e.message;
      _setState(EmbeddedServerState.error);
      rethrow;
    }
  }

  Future<void> cancelDownload() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _methodChannel.invokeMethod<void>('cancelDownload');
  }

  /// Start the installed server. Returns the bound URL.
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
        port: port,
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

  Future<void> remove() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _methodChannel.invokeMethod<bool>('remove');
    _snapshot = EmbeddedServerSnapshot(
      state: EmbeddedServerState.notInstalled,
      pinnedVersion: _snapshot.pinnedVersion,
    );
    _snapshotController.add(_snapshot);
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const UpdateCheckResult(updateAvailable: false);
    }
    final map = await _methodChannel.invokeMapMethod<String, Object>(
      'checkForUpdate',
    );
    if (map == null) {
      return const UpdateCheckResult(updateAvailable: false);
    }
    return UpdateCheckResult.fromMap(map);
  }

  /// Separate stream of byte-level download progress, distinct from
  /// the state snapshot stream.
  Stream<DownloadProgress> get downloadProgressStream =>
      _progressController.stream;
  final _progressController = StreamController<DownloadProgress>.broadcast();

  /// Most recent error string (if any).
  String? get lastError => _lastError;

  void dispose() {
    _eventSubscription?.cancel();
    _snapshotController.close();
    _progressController.close();
  }
}

/// Byte-level download progress, reported by the Kotlin side.
class DownloadProgress {
  final int bytesDone;
  final int bytesTotal;
  const DownloadProgress(this.bytesDone, this.bytesTotal);
  double get fraction => bytesTotal <= 0 ? 0 : bytesDone / bytesTotal;
}
