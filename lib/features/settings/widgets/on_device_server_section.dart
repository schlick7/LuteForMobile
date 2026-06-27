import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lute_for_mobile/core/services/embedded_server_service.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

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

  /// Error body: show the error message, a Retry button, and a
  /// collapsible "Show logs" section that pulls the Python server's
  /// recent stdout/stderr from Kotlin. This is how the user figures
  /// out why startup failed (missing dep, import error, DB issue, etc).
  Widget _buildErrorBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error: ${_snapshot?.lastError ?? "Unknown"}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _toggleLogs,
              icon: Icon(_showLogs ? Icons.expand_less : Icons.expand_more),
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
