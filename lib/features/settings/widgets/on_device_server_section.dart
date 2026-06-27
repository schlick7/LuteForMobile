import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lute_for_mobile/core/services/embedded_server_service.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/settings/widgets/on_device_first_run_dialog.dart';

/// Settings card for the "On-device" lute-v3 server option.
///
/// Shows one of:
///   - Not installed → Download button (with size hint).
///   - Downloading → progress bar + Cancel.
///   - Ready (not running) → Start / Check for update / Remove.
///   - Running → Stop, current URL.
///   - Error → message + retry.
class OnDeviceServerSection extends ConsumerStatefulWidget {
  const OnDeviceServerSection({super.key});

  @override
  ConsumerState<OnDeviceServerSection> createState() =>
      _OnDeviceServerSectionState();
}

class _OnDeviceServerSectionState
    extends ConsumerState<OnDeviceServerSection> {
  StreamSubscription<EmbeddedServerSnapshot>? _stateSub;
  StreamSubscription<String>? _logSub;
  EmbeddedServerSnapshot? _snapshot;
  final List<String> _logBuffer = [];
  bool _showLogs = false;
  bool _isRestoringFromFile = false;

  bool get _isAndroid => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      _stateSub = EmbeddedServerService.instance.stream.listen((s) {
        if (mounted) setState(() => _snapshot = s);
      });
      _logSub = EmbeddedServerService.instance.logs.listen((line) {
        if (!mounted) return;
        setState(() {
          _logBuffer.add(line);
          if (_logBuffer.length > 200) {
            _logBuffer.removeRange(0, _logBuffer.length - 200);
          }
        });
      });
      // Pull initial state.
      EmbeddedServerService.instance.refresh();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      // Clear any logs from a previous run so the user sees fresh
      // output if the new run also fails.
      setState(() => _logBuffer.clear());
      final url = await EmbeddedServerService.instance.start();
      if (!mounted) return;
      // Push the new URL into Settings so the rest of the app picks it up.
      await ref.read(settingsProvider.notifier).setOnDeviceServerUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server running at $url')),
      );
      // First-time setup: if the user hasn't done the on-device
      // first-run flow yet, show the chooser. This includes a fresh
      // install, OR a re-install after wiping the embedded server.
      if (!ref.read(settingsProvider).onDeviceFirstRunCompleted) {
        await showOnDeviceFirstRunDialog(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start failed: $e')),
      );
    }
  }

  Future<void> _stop() async {
    await EmbeddedServerService.instance.stop();
    if (!mounted) return;
    // After stop, the URL is no longer reachable. Clear it.
    await ref.read(settingsProvider.notifier).setOnDeviceServerUrl('');
  }

  /// Restore the embedded lute.db from a user-picked .db.gz file.
  ///
  /// Recovery path for when the on-disk `lute.db` is broken
  /// (corrupted, missing tables, etc.) and the server fails to start
  /// with a sqlite3.OperationalError. The first-run chooser only
  /// appears after a successful start, so users in this state have
  /// no other way to push in a new DB without uninstalling.
  ///
  /// Steps:
  ///  1. Pick a .db.gz file.
  ///  2. Stop the server (no-op if it's already in error state).
  ///  3. Replace `[filesDir]/lute/lute.db` via the Kotlin bridge.
  ///  4. Restart the server.
  Future<void> _restoreFromFile() async {
    if (_isRestoringFromFile) return;
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: false,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't read the picked file. Try a local file."),
        ),
      );
      return;
    }

    setState(() {
      _isRestoringFromFile = true;
      _logBuffer.clear();
    });
    try {
      // Best-effort stop. If the server is in error state, this is a
      // no-op on the Kotlin side (serverProcess is null).
      await EmbeddedServerService.instance.stop();
      final ok = await EmbeddedServerService.instance.restoreBackup(path);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup file is not a valid lute .db.gz'),
          ),
        );
        return;
      }
      // Restart with the restored DB. This is the same call the
      // Retry button makes, so it'll either succeed (and we're done)
      // or fail again (and the error body will show the new error).
      final url = await EmbeddedServerService.instance.start();
      // The restored DB carries a `backup_dir` setting from the
      // previous machine; the path it points to doesn't exist on
      // this device, so the first auto-backup or manual backup
      // would fail. Reset it to the on-device path. Best-effort;
      // if the server just failed to start, url is empty and we
      // skip. The user can fix it manually if needed.
      if (url.isNotEmpty) {
        await EmbeddedServerService.instance.fixRestoredBackupDir(url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringFromFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid) return const SizedBox.shrink();
    final snap = _snapshot;
    final pinnedVersion = snap?.pinnedVersion ?? Settings.luteServerPinnedVersion;
    final state = snap?.state ?? EmbeddedServerState.running;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'On-device server',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'v$pinnedVersion',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Run a Lute v3 server directly on your phone. '
              'No Termux, no separate install.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '⚠ Japanese (MeCab) is not bundled. Use Remote mode '
              'for Japanese parsing.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error
                    .withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildBody(state),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(EmbeddedServerState state) {
    switch (state) {
      case EmbeddedServerState.starting:
        return Row(
          children: const [
            SizedBox(
              height: 18, width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Starting…'),
          ],
        );

      case EmbeddedServerState.running:
        final url = _snapshot?.url ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.circle, size: 12, color: Colors.green),
                SizedBox(width: 6),
                Text('Running'),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              url,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        );

      case EmbeddedServerState.error:
        return _buildErrorBody(context);
    }
  }

  /// Error body: show the error message, a Retry button, a
  /// "Restore from .db.gz" button, and a collapsible "Show logs"
  /// section that pulls the Python server's recent stdout/stderr
  /// from Kotlin. The Restore button is the recovery path when the
  /// on-disk `lute.db` is the cause of the failure (corrupted file,
  /// missing _migrations table, etc.) — the first-run chooser only
  /// appears after a successful start, so users would otherwise be
  /// stuck unless they uninstalled.
  Widget _buildErrorBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error: ${_snapshot?.lastError ?? "Unknown"}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _isRestoringFromFile ? null : _start,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            OutlinedButton.icon(
              onPressed: _isRestoringFromFile ? null : _restoreFromFile,
              icon: _isRestoringFromFile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isRestoringFromFile
                    ? 'Restoring…'
                    : 'Restore from .db.gz',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _toggleLogs,
              icon: Icon(
                _showLogs ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(_showLogs ? 'Hide logs' : 'Show logs'),
            ),
          ],
        ),
        if (_showLogs) _buildLogViewer(),
      ],
    );
  }

  Future<void> _toggleLogs() async {
    if (!_showLogs) {
      // Fetch any logs the server produced before we asked.
      final fetched = await EmbeddedServerService.instance.fetchLogs();
      if (!mounted) return;
      setState(() {
        _logBuffer
          ..clear()
          ..addAll(fetched);
        _showLogs = true;
      });
    } else {
      setState(() => _showLogs = false);
    }
  }

  Widget _buildLogViewer() {
    if (_logBuffer.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          '(no log output captured yet)',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView.builder(
          itemCount: _logBuffer.length,
          itemBuilder: (ctx, i) => Text(
            _logBuffer[i],
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
