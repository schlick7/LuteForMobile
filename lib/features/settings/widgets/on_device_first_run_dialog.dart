import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lute_for_mobile/core/services/embedded_server_service.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

/// One-time chooser shown the first time the embedded on-device server
/// is started. Two paths:
///
/// - **Restore from backup**: the user picks a `.db.gz` (a gzipped
///   lute sqlite backup). The embedded server is stopped, the file
///   is decompressed over `<filesDir>/lute/lute.db`, the server is
///   restarted, and the chooser is dismissed.
///
/// - **Start fresh**: just dismiss the chooser. The user lands in the
///   empty database and can add a language from the 64 prefilled defs.
///
/// Either path sets `onDeviceFirstRunCompleted = true` so this
/// dialog never appears again unless the user resets it (e.g. wipes
/// the on-device server and re-installs).
class OnDeviceFirstRunDialog extends ConsumerStatefulWidget {
  const OnDeviceFirstRunDialog({super.key});

  @override
  ConsumerState<OnDeviceFirstRunDialog> createState() =>
      _OnDeviceFirstRunDialogState();
}

class _OnDeviceFirstRunDialogState
    extends ConsumerState<OnDeviceFirstRunDialog> {
  bool _busy = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _restoreFromBackup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = 'Picking file…';
      _isError = false;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: false, // we need a path, not bytes
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() {
          _busy = false;
          _statusMessage = null;
        });
        return;
      }
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        setState(() {
          _busy = false;
          _isError = true;
          _statusMessage = "Couldn't read the picked file. Try a local file.";
        });
        return;
      }

      setState(() {
        _statusMessage = 'Stopping embedded server…';
      });
      await EmbeddedServerService.instance.stop();

      setState(() {
        _statusMessage = 'Restoring backup…';
      });
      // The Kotlin bridge handles gzip decompression + atomic
      // file replacement via Chaquopy/Python's stdlib gzip.
      final ok = await EmbeddedServerService.instance.restoreBackup(path);
      if (!ok) {
        setState(() {
          _isError = true;
          _statusMessage = 'Backup file is not a valid lute .db.gz';
        });
        await _safeStart();
        return;
      }

      setState(() {
        _statusMessage = 'Restarting embedded server…';
      });
      try {
        await EmbeddedServerService.instance.start();
      } catch (e) {
        setState(() {
          _isError = true;
          _statusMessage =
              'Restored, but server failed to restart: $e. '
              'Try Stop / Start in Settings.';
        });
        return;
      }

      await ref
          .read(settingsProvider.notifier)
          .markOnDeviceFirstRunCompleted();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _startFresh() async {
    await ref
        .read(settingsProvider.notifier)
        .markOnDeviceFirstRunCompleted();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _safeStart() async {
    try {
      await EmbeddedServerService.instance.start();
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Don't let the user dismiss by tapping outside; they have to
      // make a choice. (Tap-outside would skip the chooser but
      // also re-trigger on next start if the flag wasn't set.)
      canPop: !_busy,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Welcome to on-device Lute',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'The on-device server is running. You can restore '
                  'from an existing backup, or start fresh and add a '
                  'language from the 64 bundled definitions.',
                ),
                const SizedBox(height: 20),
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        if (_busy)
                          const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isError ? Icons.error_outline : Icons.info_outline,
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isError
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _startFresh,
                        icon: const Icon(Icons.fiber_new),
                        label: const Text('Start fresh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _restoreFromBackup,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Restore from backup'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Backup files are .db.gz (a gzipped sqlite dump).',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience function for showing the dialog. Returns a Future that
/// completes when the user dismisses it.
Future<void> showOnDeviceFirstRunDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const OnDeviceFirstRunDialog(),
  );
}
