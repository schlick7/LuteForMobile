import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/services/backup_folder_service.dart';

/// Settings card for the optional external SAF backup folder.
///
/// Lets the user pick a folder on shared storage (via the Storage
/// Access Framework, so no broad permissions are needed). Every
/// backup is mirrored there automatically, keeping a durable copy
/// that survives "Clear storage" / app uninstall.
class BackupFolderCard extends ConsumerStatefulWidget {
  const BackupFolderCard({super.key});

  @override
  ConsumerState<BackupFolderCard> createState() => _BackupFolderCardState();
}

class _BackupFolderCardState extends ConsumerState<BackupFolderCard> {
  BackupFolderInfo? _folder;
  bool _busy = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      _load();
    }
  }

  Future<void> _load() async {
    final folder = await BackupFolderService.instance.getFolder();
    if (!mounted) return;
    setState(() => _folder = folder);
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final folder = await BackupFolderService.instance.pickFolder();
      if (!mounted) return;
      setState(() => _folder = folder);
      if (folder != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backups will now be saved to ${folder.name}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await BackupFolderService.instance.clearFolder();
      if (!mounted) return;
      setState(() => _folder = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup location', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Your Lute data is stored inside this app. If you "Clear '
              'storage" or uninstall the app, that data is deleted with it. '
              'Choose a folder (e.g. "Downloads/Lute") to automatically '
              'keep a copy of every backup there, so you can restore it '
              'later even if the app is removed.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            if (_folder != null) ...[
              Row(
                children: [
                  const Icon(Icons.folder, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _folder!.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open),
                  label: Text(_folder != null ? 'Change folder' : 'Choose folder'),
                ),
                if (_folder != null)
                  TextButton.icon(
                    onPressed: _busy ? null : _clear,
                    icon: const Icon(Icons.close),
                    label: const Text('Stop saving here'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}