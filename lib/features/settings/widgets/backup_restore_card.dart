import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/services/backup_service.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/theme/theme_extensions.dart';

class BackupRestoreCard extends ConsumerStatefulWidget {
  const BackupRestoreCard({super.key});

  @override
  ConsumerState<BackupRestoreCard> createState() => _BackupRestoreCardState();
}

class _BackupRestoreCardState extends ConsumerState<BackupRestoreCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUploading = false;
  List<Map<String, dynamic>>? _backups;
  String? _error;
  String? _lastLoadedServerUrl;
  final Set<String> _downloadingBackups = {};
  final Set<String> _restoringBackups = {};
  final Set<String> _deletingBackups = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfServerChanged();
  }

  @override
  void didUpdateWidget(covariant BackupRestoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfServerChanged();
  }

  void _refreshIfServerChanged() {
    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    if (_lastLoadedServerUrl == serverUrl) {
      return;
    }
    _lastLoadedServerUrl = serverUrl;
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    if (serverUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _backups = null;
        _error = 'No server configured';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final backups = await BackupService.listBackups(serverUrl);
      if (!mounted) return;
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backups = null;
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    setState(() {
      _isCreating = true;
    });

    try {
      await BackupService.createBackup(serverUrl);
      if (!mounted) return;
      _showSnackBar(
        'Backup created successfully',
        context.appColorScheme.semantic.success,
      );
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to create backup: ${e.toString().replaceFirst('Exception: ', '')}',
        context.appColorScheme.error.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gz'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    final filename = path.split(Platform.pathSeparator).last;
    if (!filename.endsWith('.db.gz')) {
      if (!mounted) return;
      _showSnackBar(
        'Selected file must end with .db.gz',
        context.appColorScheme.error.error,
      );
      return;
    }

    final uploadedName = filename.startsWith('manual_')
        ? filename
        : 'manual_$filename';
    final duplicateExists =
        _backups?.any((backup) => backup['filename'] == uploadedName) ?? false;
    if (duplicateExists) {
      if (!mounted) return;
      _showSnackBar(
        'Backup already exists: $uploadedName',
        context.appColorScheme.error.error,
      );
      return;
    }

    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    setState(() {
      _isUploading = true;
    });

    try {
      await BackupService.uploadBackup(serverUrl, path);
      if (!mounted) return;
      _showSnackBar(
        'Backup uploaded successfully',
        context.appColorScheme.semantic.success,
      );
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to upload backup: ${e.toString().replaceFirst('Exception: ', '')}',
        context.appColorScheme.error.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _restoreBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          'Restore "$filename"? This will replace the current server database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    setState(() {
      _restoringBackups.add(filename);
    });

    try {
      await BackupService.restoreBackup(serverUrl, filename);
      if (!mounted) return;
      _showSnackBar(
        'Backup restored successfully',
        context.appColorScheme.semantic.success,
      );
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to restore backup: ${e.toString().replaceFirst('Exception: ', '')}',
        context.appColorScheme.error.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _restoringBackups.remove(filename);
        });
      }
    }
  }

  Future<void> _downloadBackup(String filename) async {
    final settings = ref.read(settingsProvider);
    final serverUrl = settings.serverUrl.trim();
    final serverType = serverUrl == Settings.termuxUrl ? 'termux' : 'localurl';

    setState(() {
      _downloadingBackups.add(filename);
    });

    try {
      final result = await BackupService.downloadBackup(
        serverUrl,
        filename,
        serverType: serverType,
      );
      if (!mounted) return;
      _showSnackBar(
        'Downloaded to: $result',
        context.appColorScheme.semantic.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to download backup: ${e.toString().replaceFirst('Exception: ', '')}',
        context.appColorScheme.error.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingBackups.remove(filename);
        });
      }
    }
  }

  Future<void> _deleteBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Delete "$filename"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColorScheme.error.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    setState(() {
      _deletingBackups.add(filename);
    });

    try {
      await BackupService.deleteBackup(serverUrl, filename);
      if (!mounted) return;
      _showSnackBar(
        'Backup deleted successfully',
        context.appColorScheme.semantic.success,
      );
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to delete backup: ${e.toString().replaceFirst('Exception: ', '')}',
        context.appColorScheme.error.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingBackups.remove(filename);
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final serverUrl = settings.serverUrl.trim();
    final experimentalEnabled = settings.experimentalBackupRestoreFeatures;

    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: const Text(
          'Backup/Restore',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          serverUrl.isEmpty ? 'No server configured' : serverUrl,
          style: TextStyle(color: context.appColorScheme.text.secondary),
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          if (expanded) {
            _loadBackups();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Experimental Features',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            experimentalEnabled
                                ? 'Upload, restore, and delete are enabled'
                                : 'Only standard backup listing and creation are enabled',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColorScheme.text.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: experimentalEnabled,
                        onChanged: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateExperimentalBackupRestoreFeatures(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isCreating || serverUrl.isEmpty
                          ? null
                          : _createBackup,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.backup),
                      label: Text(
                        _isCreating ? 'Creating...' : 'Create Backup',
                      ),
                    ),
                    if (experimentalEnabled)
                      OutlinedButton.icon(
                        onPressed: _isUploading || serverUrl.isEmpty
                            ? null
                            : _pickAndUploadBackup,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Backup',
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _loadBackups,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(),
                  )
                else if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: context.appColorScheme.error.error),
                  )
                else if (_backups == null || _backups!.isEmpty)
                  Text(
                    'No backups found',
                    style: TextStyle(
                      color: context.appColorScheme.text.secondary,
                    ),
                  )
                else
                  ..._backups!.map((backup) {
                    final filename = backup['filename'] as String;
                    final size = backup['size'] as String;
                    final lastModified = backup['lastModified'] as int;
                    final isManual = backup['isManual'] as bool? ?? false;
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      lastModified,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    filename,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isManual)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context
                                          .appColorScheme
                                          .semantic
                                          .warning
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Manual',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context
                                            .appColorScheme
                                            .semantic
                                            .warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}  •  $size',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColorScheme.text.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed:
                                      _downloadingBackups.contains(filename)
                                      ? null
                                      : () => _downloadBackup(filename),
                                  icon: _downloadingBackups.contains(filename)
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.download, size: 16),
                                  label: Text(
                                    _downloadingBackups.contains(filename)
                                        ? 'Downloading...'
                                        : 'Download',
                                  ),
                                ),
                                if (experimentalEnabled)
                                  OutlinedButton.icon(
                                    onPressed:
                                        _restoringBackups.contains(filename)
                                        ? null
                                        : () => _restoreBackup(filename),
                                    icon: _restoringBackups.contains(filename)
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.restore, size: 16),
                                    label: Text(
                                      _restoringBackups.contains(filename)
                                          ? 'Restoring...'
                                          : 'Restore',
                                    ),
                                  ),
                                if (experimentalEnabled)
                                  OutlinedButton.icon(
                                    onPressed:
                                        _deletingBackups.contains(filename)
                                        ? null
                                        : () => _deleteBackup(filename),
                                    icon: _deletingBackups.contains(filename)
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                          ),
                                    label: Text(
                                      _deletingBackups.contains(filename)
                                          ? 'Deleting...'
                                          : 'Delete',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
