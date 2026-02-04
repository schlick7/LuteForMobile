import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/core/services/backup_service.dart';
import 'package:lute_for_mobile/core/services/storage_service.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

class TermuxScreen extends ConsumerStatefulWidget {
  const TermuxScreen({super.key});

  @override
  ConsumerState<TermuxScreen> createState() => _TermuxScreenState();
}

class _TermuxScreenState extends ConsumerState<TermuxScreen> {
  bool _isLoading = true;
  bool _isBackgroundChecking = false;
  bool _termuxInstalled = false;
  bool _termuxInstalledConfirmed = false;
  bool _permissionGranted = false;
  bool _externalAppsEnabled = false;
  bool _termuxRunning = false;
  bool _checkingTermuxRunning = false;
  String _lute3Status = 'UNKNOWN';
  bool _serverRunning = false;
  List<Map<String, dynamic>>? _backups;
  bool _isBackingUp = false;
  final Set<String> _downloadingBackups = {};
  List<Map<String, dynamic>>? _localBackups;
  bool _isBackingUpLocal = false;
  final Set<String> _downloadingLocalBackups = {};
  bool _isRestoring = false;
  List<String>? _downloadFolderFiles;
  bool _isLoadingDownloadFiles = false;
  bool _isLaunchingTermux = false;

  StreamSubscription? _progressSubscription;
  String _currentStep = '';
  String _currentStatus = '';
  int _currentMaxWaitSeconds = 60;

  bool _checkingTermux = false;
  bool _checkingPermission = false;
  bool _checkingExternalApps = false;
  bool _checkingLute3 = false;
  bool _checkingServer = false;
  bool _checkingBackups = false;
  bool _checkingLocalBackups = false;

  @override
  void initState() {
    super.initState();
    _initialQuickLoad();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialQuickLoad() async {
    final quickStatus = await TermuxService.getQuickInstallationStatus();

    setState(() {
      _isLoading = false;
      _lute3Status = quickStatus;

      if (quickStatus == 'INSTALLED') {
        _termuxInstalled = true;
        _termuxInstalledConfirmed = false;
        _permissionGranted = false;
        _externalAppsEnabled = false;
        _serverRunning = false;
      } else {
        _termuxInstalled = false;
        _termuxInstalledConfirmed = false;
        _permissionGranted = false;
        _externalAppsEnabled = false;
        _serverRunning = false;
      }
    });

    _runBackgroundStatusCheck();
  }

  Future<void> _runBackgroundStatusCheck() async {
    setState(() {
      _isBackgroundChecking = true;
      _checkingTermux = true;
      _checkingPermission = true;
      _checkingExternalApps = true;
      _checkingLute3 = true;
      _checkingServer = true;
      _checkingTermuxRunning = true;
    });

    try {
      final termuxInstalled = await TermuxService.isTermuxInstalled();
      setState(() {
        _checkingTermux = false;
        _termuxInstalled = termuxInstalled;
        _termuxInstalledConfirmed = true;
      });

      if (termuxInstalled) {
        // Check if Termux service is running
        final termuxRunning = await TermuxService.isTermuxRunning();
        setState(() {
          _checkingTermuxRunning = false;
          _termuxRunning = termuxRunning;
        });

        final permissionGranted =
            await TermuxService.isTermuxPermissionGranted();
        setState(() {
          _checkingPermission = false;
          _permissionGranted = permissionGranted;
        });

        try {
          final hasStoragePermission =
              await Permission.manageExternalStorage.isGranted;
          if (!hasStoragePermission) {
            final storageResult = await Permission.manageExternalStorage
                .request();
            if (!storageResult.isGranted) {
              setState(() {
                _checkingExternalApps = false;
                _externalAppsEnabled = false;
              });
            } else {
              final externalAppsEnabled =
                  await TermuxService.checkExternalAppsEnabled();
              setState(() {
                _checkingExternalApps = false;
                _externalAppsEnabled = externalAppsEnabled;
              });
            }
          } else {
            final externalAppsEnabled =
                await TermuxService.checkExternalAppsEnabled();
            setState(() {
              _checkingExternalApps = false;
              _externalAppsEnabled = externalAppsEnabled;
            });
          }
        } catch (e) {
          setState(() {
            _checkingExternalApps = false;
            _externalAppsEnabled = false;
          });
        }

        final lute3Status = await TermuxService.isLute3Installed();
        setState(() {
          _checkingLute3 = false;
          _lute3Status = lute3Status;
        });

        final serverRunning = await TermuxService.isServerRunning();
        setState(() {
          _checkingServer = false;
          _serverRunning = serverRunning;
        });

        if (lute3Status == 'INSTALLED') {
          if (serverRunning) {
            setState(() {
              _checkingBackups = true;
            });
            try {
              final backups = await BackupService.listBackups(
                Settings.termuxUrl,
              );
              setState(() {
                _checkingBackups = false;
                _backups = backups;
              });
            } catch (e) {
              setState(() {
                _checkingBackups = false;
                _backups = null;
              });
            }
          }
        }

        setState(() {
          _checkingLocalBackups = true;
        });
        try {
          final localUrl = ref.read(settingsProvider).localUrl;
          if (localUrl.isNotEmpty && localUrl != Settings.termuxUrl) {
            final localBackups = await BackupService.listBackups(localUrl);
            setState(() {
              _checkingLocalBackups = false;
              _localBackups = localBackups;
            });
          } else {
            setState(() {
              _checkingLocalBackups = false;
              _localBackups = null;
            });
          }
        } catch (e) {
          setState(() {
            _checkingLocalBackups = false;
            _localBackups = null;
          });
        }
      }
    } catch (e) {
      print('Background status check failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundChecking = false;
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    _runBackgroundStatusCheck();
  }

  Future<void> _openFStore() async {
    try {
      final fdroidInstalled = await TermuxService.isFDroidInstalled();

      if (fdroidInstalled) {
        // Try to open F-Droid app directly
        final fdroidUri = Uri.parse('fdroid.app:com.termux');
        if (await canLaunchUrl(fdroidUri)) {
          await launchUrl(fdroidUri);
          return;
        }

        // Fallback: open F-Droid store URL
        final fdroidWebUri = Uri.parse(
          'https://f-droid.org/packages/com.termux/',
        );
        if (await canLaunchUrl(fdroidWebUri)) {
          await launchUrl(fdroidWebUri);
          return;
        }
      }

      // Fallback to GitHub releases if F-Droid is not available
      final githubUri = Uri.parse(
        'https://github.com/termux/termux-app/releases/tag/v0.118.3',
      );
      if (await canLaunchUrl(githubUri)) {
        await launchUrl(githubUri);
      }
    } catch (e) {
      print('Failed to open store: $e');
    }
  }

  Future<void> _openTermuxApp() async {
    try {
      final uri = Uri.parse('android-app://com.termux');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(
          Uri.parse(
            'intent://com.termux#Intent;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;launchFlags=0x10000000;package=com.termux;end',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      AppSettings.openAppSettings();
    }
  }

  Future<void> _openAppSettings() async {
    AppSettings.openAppSettings(type: AppSettingsType.settings);
  }

  Future<void> _requestTermuxPermission() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termux Permission Required'),
        content: const Text(
          'To run the Lute server, LuteForMobile needs permission to execute commands in Termux.\n\n'
          'Tap "Open Settings" \n'
          '"Permissions" → "Additional permissions" → "Run commands" → "Allow"\n'
          'Press back until you return to LuteForMobile\n'
          'Tap refresh icon in top right',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              TermuxService.requestTermuxPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _installLute3() async {
    await _installLute3Chained();
  }

  Future<void> _installLute3Chained() async {
    setState(() {
      _isLoading = true;
      _currentStep = 'Preparing...';
      _currentStatus = 'Initializing...';
    });

    _progressSubscription?.cancel();
    _progressSubscription = TermuxService.getInstallProgress().listen(
      (progress) {
        setState(() {
          _currentStep = progress['step'] ?? 'Processing...';
          _currentStatus = progress['status'] ?? 'Processing...';
          _currentMaxWaitSeconds = progress['maxWaitSeconds'] ?? 60;
        });
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Installation error: $error. Check Downloads folder for log files',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      },
    );

    final result = await TermuxService.installLute3();

    await _progressSubscription?.cancel();
    _progressSubscription = null;

    setState(() {
      _currentStep = '';
      _currentStatus = '';
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'COMPLETE'
                ? 'Lute3 installed successfully!'
                : 'Installation failed. Check Downloads folder for log files',
          ),
          backgroundColor: result == 'COMPLETE' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    _refreshStatus();
  }

  Future<void> _refreshServerStatus() async {
    final serverRunning = await TermuxService.isServerRunning();
    setState(() {
      _serverRunning = serverRunning;
    });
  }

  Future<void> _startServer() async {
    try {
      final androidVersion = await TermuxService.getAndroidVersion();
      if (androidVersion != null && androidVersion >= 33) {
        final hasPermission = await TermuxService.hasNotificationPermission();
        if (!hasPermission) {
          await TermuxService.requestNotificationPermission();
          return;
        }
      }
    } catch (e) {
      debugPrint('Notification permission check failed: $e');
    }

    await TermuxService.startServer();
    await Future.delayed(const Duration(seconds: 2));
    await _refreshServerStatus();
  }

  Future<void> _stopServer() async {
    await TermuxService.stopServer();
    await Future.delayed(const Duration(seconds: 2));
    await _refreshServerStatus();
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      await BackupService.createBackup(Settings.termuxUrl);

      setState(() {
        _isBackingUp = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      _refreshStatus();
    } catch (e) {
      setState(() {
        _isBackingUp = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadBackup(String filename) async {
    setState(() {
      _downloadingBackups.add(filename);
    });

    try {
      final result = await BackupService.downloadBackup(
        Settings.termuxUrl,
        filename,
        serverType: 'termux',
      );

      setState(() {
        _downloadingBackups.remove(filename);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadingBackups.remove(filename);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createLocalBackup() async {
    setState(() {
      _isBackingUpLocal = true;
    });

    try {
      final localUrl = ref.read(settingsProvider).localUrl;
      await BackupService.createBackup(localUrl);

      setState(() {
        _isBackingUpLocal = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local backup created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      _refreshStatus();
    } catch (e) {
      setState(() {
        _isBackingUpLocal = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create local backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadLocalBackup(String filename) async {
    setState(() {
      _downloadingLocalBackups.add(filename);
    });

    try {
      final localUrl = ref.read(settingsProvider).localUrl;
      final result = await BackupService.downloadBackup(
        localUrl,
        filename,
        serverType: 'localurl',
      );

      setState(() {
        _downloadingLocalBackups.remove(filename);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadingLocalBackups.remove(filename);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreConfirmDialog(String filePath) {
    debugPrint('_showRestoreConfirmDialog called with filePath: $filePath');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Do you want to create a backup before restoring?'),
            const SizedBox(height: 8),
            Text(
              'File: ${filePath.split('/').last}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('User selected NO for backup');
              Navigator.pop(context);
              _performRestore(filePath, createBackupFirst: false);
            },
            child: const Text('No, Restore Now'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('User selected YES for backup');
              Navigator.pop(context);
              _performRestore(filePath, createBackupFirst: true);
            },
            child: const Text('Yes, Create Backup First'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(
    String filePath, {
    required bool createBackupFirst,
  }) async {
    debugPrint(
      '_performRestore called with filePath: $filePath, createBackupFirst: $createBackupFirst',
    );
    setState(() {
      _isRestoring = true;
    });

    try {
      if (createBackupFirst) {
        debugPrint('Creating backup via server...');
        final backupResult = await BackupService.createBackup(
          Settings.termuxUrl,
        );
        debugPrint('Backup result: $backupResult');
        if (!backupResult.contains('successfully')) {
          setState(() {
            _isRestoring = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup failed: $backupResult'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      debugPrint(
        'Calling TermuxService.restoreBackup with filePath: $filePath',
      );
      final success = await TermuxService.restoreBackup(filePath);
      debugPrint('TermuxService.restoreBackup returned: $success');

      setState(() {
        _isRestoring = false;
      });

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restore failed: Termux operation did not complete',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      _refreshStatus();
    } catch (e, stack) {
      debugPrint('Restore exception: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _isRestoring = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isLoadingDownloadFiles = true;
    });

    final files = await StorageService.getBackupFilesInDownloads();
    debugPrint('Found ${files.length} backup files in Downloads');

    setState(() {
      _downloadFolderFiles = files;
      _isLoadingDownloadFiles = false;
    });

    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup files found in Downloads folder'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _showRestoreFileSelectionDialog(files);
  }

  void _showRestoreFileSelectionDialog(List<String> files) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Backup to Restore'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final filePath = files[index];
              final fileName = filePath.split('/').last;
              final file = File(filePath);
              final lastModified = file.lastModifiedSync();
              final size = file.lengthSync();

              return ListTile(
                title: Text(fileName),
                subtitle: Text(
                  '${lastModified.day}/${lastModified.month}/${lastModified.year} ${lastModified.hour}:${lastModified.minute.toString().padLeft(2, '0')} - ${_formatFileSize(size)}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRestoreConfirmDialog(filePath);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termux Integration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshStatus,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              if (_currentStep.isNotEmpty) ...[
                Text(
                  'Step: $_currentStep',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (_currentStatus.isNotEmpty)
                Text(
                  _currentStatus,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              if (_currentMaxWaitSeconds > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Estimated wait time: ~$_currentMaxWaitSeconds seconds',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Output logs are saved to Downloads folder',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Termux',
                    _termuxInstalled,
                    _checkingTermux,
                    _termuxInstalledConfirmed,
                    'Not installed',
                    onTap: _openTermuxApp,
                  ),
                  if (_termuxInstalled) ...[
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Termux Status',
                      _termuxRunning,
                      _checkingTermuxRunning,
                      !_checkingTermuxRunning,
                      _termuxRunning ? 'Running' : 'Not Running - Tap to start',
                      onTap: _manualStealthLaunchTermux,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Permission',
                      _permissionGranted,
                      _checkingPermission,
                      !_checkingPermission,
                      'Not granted',
                      onTap: _requestTermuxPermission,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'External Apps',
                      _externalAppsEnabled,
                      _checkingExternalApps,
                      !_checkingExternalApps,
                      'Disabled',
                      onTap: _showExternalAppsInstructions,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Lute3',
                      _lute3Status == 'INSTALLED',
                      _checkingLute3,
                      !_checkingLute3,
                      'Not installed',
                      onTap: _showLute3Options,
                    ),
                    if (_lute3Status == 'INSTALLED') ...[
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Launch Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, child) {
                      final settings = ref.watch(settingsProvider);
                      return SwitchListTile(
                        title: const Text('Auto-launch Termux when needed'),
                        subtitle: const Text(
                          'Automatically launch Termux in the background when the app starts if it\'s not already running',
                        ),
                        value: settings.termuxAutoLaunchEnabled,
                        onChanged: (bool value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateTermuxAutoLaunchEnabled(value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_lute3Status == 'INSTALLED') ...[
            const SizedBox(height: 16),
            _buildServerCard(),
            const SizedBox(height: 16),
            _buildBackupCard(),
            if (ref.watch(settingsProvider).serverUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLocalBackupCard(),
            ],
          ] else ...[
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _installLute3,
                icon: const Icon(Icons.download),
                label: const Text('Install Lute3 in Termux'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _openFStore,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Install Termux'),
              ),
            ),
          ],
          if (_isBackgroundChecking)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(value: null),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String labelText,
    bool status,
    bool isLoading,
    bool showFdroidLink,
    String defaultText, {
    String? statusText,
    VoidCallback? onTap,
  }) {
    String displayText;
    bool displayStatus = status;

    if (isLoading) {
      displayText = 'Checking...';
      displayStatus = false;
    } else if (labelText == 'Permission') {
      displayText = status ? 'Granted' : 'Not granted';
    } else if (labelText == 'External Apps') {
      displayText = status ? 'Enabled' : 'Disabled';
    } else if (labelText == 'Termux Status') {
      displayText = status ? 'Running' : defaultText;
    } else if (labelText == 'Lute3' && statusText != null) {
      displayText = statusText;
    } else if (labelText == 'Version' && statusText != null) {
      displayText = statusText;
    } else {
      displayText = status ? 'Installed' : defaultText;
    }

    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labelText, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    displayText,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  Icon(
                    status ? Icons.check_circle : Icons.error,
                    color: status ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Control',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _serverRunning ? null : _startServer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Server'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _serverRunning ? _stopServer : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termux Backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _createBackup,
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.backup),
              label: Text(_isBackingUp ? 'Creating...' : 'Create Backup'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isRestoring ? null : _restoreBackup,
              icon: _isRestoring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.restore),
              label: Text(_isRestoring ? 'Restoring...' : 'Restore Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Backups (${_backups?.length ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            if (_backups == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Server not connected',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (_backups!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Server not connected or No backups found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._backups!.take(5).map((backup) {
                final filename = backup['filename'] as String;
                final lastModified = backup['lastModified'] as int;
                final size = backup['size'] as String;
                final date = DateTime.fromMillisecondsSinceEpoch(lastModified);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                filename,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              size,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _downloadingBackups.contains(filename)
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
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalBackupCard() {
    final settings = ref.watch(settingsProvider);
    final localUrl = settings.localUrl;
    final hasLocalUrl = localUrl.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local URL Backup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (hasLocalUrl)
                  Text(
                    localUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasLocalUrl)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.link_off, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'No local URL configured',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _isBackingUpLocal ? null : _createLocalBackup,
                icon: _isBackingUpLocal
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.backup),
                label: Text(
                  _isBackingUpLocal ? 'Creating...' : 'Create Backup',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Backups (${_localBackups?.length ?? 0})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              if (_checkingLocalBackups)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(value: null),
                )
              else if (_localBackups == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Server not connected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_localBackups!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No backups found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._localBackups!.take(5).map((backup) {
                  final filename = backup['filename'] as String;
                  final lastModified = backup['lastModified'] as int;
                  final size = backup['size'] as String;
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  filename,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _downloadingLocalBackups.contains(filename)
                                  ? null
                                  : () => _downloadLocalBackup(filename),
                              icon: _downloadingLocalBackups.contains(filename)
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download, size: 16),
                              label: Text(
                                _downloadingLocalBackups.contains(filename)
                                    ? 'Downloading...'
                                    : 'Download',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  void _showExternalAppsInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable External Apps in Termux'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Termux needs to be configured to accept commands from LuteForMobile.',
              ),

              const SizedBox(height: 8),
              const Text(
                'Step 1: Copy this command into termux and press enter:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'echo "allow-external-apps=true" > ~/.termux/termux.properties',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text:
                              'echo "allow-external-apps=true" > ~/.termux/termux.properties',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Command copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 2: Open the Termux app, Paste Command press enter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Step 3: Return to LuteForMobile and refresh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openTermuxApp();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Termux'),
          ),
        ],
      ),
    );
  }

  void _showLute3Options() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lute3 Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Update Lute3'),
              subtitle: const Text('Update to the latest version'),
              onTap: () {
                Navigator.pop(context);
                _updateLute3();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reinstall Lute3'),
              subtitle: const Text('Uninstall and reinstall'),
              onTap: () {
                Navigator.pop(context);
                _reinstallLute3();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLute3() async {
    await _installLute3();
  }

  Future<void> _reinstallLute3() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reinstall feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _manualStealthLaunchTermux() async {
    if (_isLaunchingTermux) return; // Prevent multiple launches

    setState(() {
      _isLaunchingTermux = true;
    });

    try {
      // Show snackbar indicating initialization
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Initializing Termux...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Attempt to stealth launch Termux
      final success = await TermuxService.stealthLaunchTermux();

      if (mounted) {
        if (success) {
          // Refresh status after a brief delay
          await Future.delayed(const Duration(seconds: 1));
          _refreshStatus();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Termux initialized successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error dialog if launch failed
          _showLaunchFailedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showLaunchFailedDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingTermux = false;
        });
      }
    }
  }

  void _showLaunchFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termux Not Responding'),
        content: const Text(
          'Unable to start Termux automatically after retry. You can try again or open Termux manually.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openTermuxApp(); // Open Termux manually
            },
            child: const Text('Open Termux'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _manualStealthLaunchTermux(); // Try again
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
