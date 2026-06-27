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
  StreamSubscription<DownloadProgress>? _progressSub;
  EmbeddedServerSnapshot? _snapshot;
  DownloadProgress? _progress;
  bool _checking = false;

  bool get _isAndroid => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      _stateSub = EmbeddedServerService.instance.stream.listen((s) {
        if (mounted) setState(() => _snapshot = s);
      });
      _progressSub = EmbeddedServerService.instance.downloadProgressStream
          .listen((p) {
        if (mounted) setState(() => _progress = p);
      });
      // Pull initial state.
      EmbeddedServerService.instance.refresh();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    try {
      await EmbeddedServerService.instance.download();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _cancelDownload() async {
    await EmbeddedServerService.instance.cancelDownload();
  }

  Future<void> _start() async {
    try {
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

  Future<void> _remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove on-device server?'),
        content: const Text(
          'This deletes the downloaded server. Your data (books, terms) '
          'is not affected. You can re-download at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await EmbeddedServerService.instance.remove();
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checking = true);
    try {
      final result = await EmbeddedServerService.instance.checkForUpdate();
      if (!mounted) return;
      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update check failed: ${result.error}')),
        );
      } else if (result.updateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update available: ${result.latestTag}. '
              'Re-download the app or use Remove + Download.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Up to date (${result.latestTag ?? "v${Settings.luteServerPinnedVersion}"}).')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid) return const SizedBox.shrink();
    final snap = _snapshot;
    final pinnedVersion = snap?.pinnedVersion ?? Settings.luteServerPinnedVersion;
    final state = snap?.state ?? EmbeddedServerState.notInstalled;

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
      case EmbeddedServerState.notInstalled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Not installed.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _checking ? null : _checkForUpdate,
                  child: const Text('Updates'),
                ),
              ],
            ),
          ],
        );

      case EmbeddedServerState.downloading:
        final p = _progress;
        final frac = p?.fraction ?? 0.0;
        final doneMb = (p?.bytesDone ?? 0) / 1024 / 1024;
        final totalMb = (p?.bytesTotal ?? 0) / 1024 / 1024;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p == null
                ? 'Downloading…'
                : 'Downloading: ${doneMb.toStringAsFixed(1)} / '
                    '${totalMb.toStringAsFixed(1)} MB'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: p == null ? null : frac),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cancelDownload,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ],
        );

      case EmbeddedServerState.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, size: 18),
                const SizedBox(width: 6),
                const Text('Installed · ready to start'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _remove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        );

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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        );

      case EmbeddedServerState.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error: ${_snapshot?.lastError ?? "Unknown"}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry download'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _remove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        );
    }
  }
}
