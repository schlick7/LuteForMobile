import 'package:flutter/material.dart';
import 'package:lute_for_mobile/core/services/backup_folder_service.dart';

/// One-time prompt after the user chooses the integrated server:
/// asks them to pick an external backup folder so their Lute data
/// survives "Clear storage" / uninstall.
class BackupLocationPromptDialog extends StatefulWidget {
  const BackupLocationPromptDialog({super.key});

  @override
  State<BackupLocationPromptDialog> createState() =>
      _BackupLocationPromptDialogState();
}

class _BackupLocationPromptDialogState
    extends State<BackupLocationPromptDialog> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final folder = await BackupFolderService.instance.pickFolder();
      if (!mounted) return;
      if (folder != null) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
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
                    Icon(Icons.save, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Choose a backup location',
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
                  'Your Lute data is stored inside this app. If you '
                  '"Clear storage" or uninstall the app, that data is '
                  'deleted with it. Choosing a folder (e.g. '
                  '"Downloads/Lute") keeps a copy of every backup '
                  'there, so you can restore it later even if the app '
                  'is removed.',
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change or remove this later in Settings → '
                  'Backup location.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: _busy ? null : _skip,
                      child: const Text('Not now'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _pick,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.folder_open),
                        label: const Text('Choose folder'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the backup-location prompt. Returns a Future that completes
/// when the user picks a folder or dismisses it.
Future<void> showBackupLocationPrompt(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const BackupLocationPromptDialog(),
  );
}