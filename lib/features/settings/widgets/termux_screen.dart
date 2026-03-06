import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/logger/widget_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/core/services/backup_service.dart';
import 'package:lute_for_mobile/core/services/storage_service.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/shared/theme/theme_extensions.dart';

class TermuxScreen extends ConsumerStatefulWidget {
  const TermuxScreen({super.key});

  @override
  ConsumerState<TermuxScreen> createState() => _TermuxScreenState();
}

class _TermuxScreenState extends ConsumerState<TermuxScreen> {
  int _buildCount = 0;
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
  bool _isStartingServer = false;
  bool _isStoppingServer = false;
  List<Map<String, dynamic>>? _backups;
  bool _isBackingUp = false;
  final Set<String> _downloadingBackups = {};
  List<Map<String, dynamic>>? _localBackups;
  bool _isBackingUpLocal = false;
  final Set<String> _downloadingLocalBackups = {};
  bool _isRestoring = false;
  bool _isLaunchingTermux = false;
  bool _isInstalling = false;

  StreamSubscription? _progressSubscription;
  String _currentStep = '';
  String _currentStatus = '';
  int _currentMaxWaitSeconds = 60;

  bool _checkingTermux = false;
  bool _checkingPermission = false;
  bool _checkingExternalApps = false;
  bool _checkingStorageAccess = false;
  bool _storageAccessGranted = false;
  bool _checkingLute3 = false;
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
      _checkingStorageAccess = true;
      _checkingLute3 = true;
      _checkingTermuxRunning = true;
    });

    try {
      // First check if Termux is installed
      final termuxInstalled = await TermuxService.isTermuxInstalled();
      setState(() {
        _checkingTermux = false;
        _termuxInstalled = termuxInstalled;
        _termuxInstalledConfirmed = true;
      });

      if (termuxInstalled) {
        // Run Termux running and permission checks in parallel
        final basicResults = await Future.wait([
          TermuxService.isTermuxRunning(),
          TermuxService.isTermuxPermissionGranted(),
          _checkStorageAccessGranted(),
        ]);

        // Check external apps (may need storage permission)
        bool externalAppsEnabled = false;
        try {
          final hasStoragePermission =
              await Permission.manageExternalStorage.isGranted;
          if (!hasStoragePermission) {
            final storageResult = await Permission.manageExternalStorage
                .request();
            if (storageResult.isGranted) {
              externalAppsEnabled =
                  await TermuxService.checkExternalAppsEnabled();
            }
          } else {
            externalAppsEnabled =
                await TermuxService.checkExternalAppsEnabled();
          }
        } catch (e) {
          externalAppsEnabled = false;
        }

        // Check Lute3 installation
        final lute3Status = await TermuxService.isLute3Installed();

        setState(() {
          _checkingTermuxRunning = false;
          _termuxRunning = basicResults[0] as bool;
          _checkingPermission = false;
          _permissionGranted = basicResults[1] as bool;
          _checkingStorageAccess = false;
          _storageAccessGranted = basicResults[2] as bool;
          _checkingExternalApps = false;
          _externalAppsEnabled = externalAppsEnabled;
          _checkingLute3 = false;
          _lute3Status = lute3Status;
        });

        final serverRunning = await TermuxService.isServerRunning(
          Settings.termuxUrl,
        );
        setState(() {
          _serverRunning = serverRunning;
        });

        if (_lute3Status == 'INSTALLED') {
          if (serverRunning) {
            try {
              final backups = await BackupService.listBackups(
                Settings.termuxUrl,
              );
              setState(() {
                _backups = backups;
              });
            } catch (e) {
              setState(() {
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
      if (!termuxInstalled) {
        setState(() {
          _checkingTermuxRunning = false;
          _checkingPermission = false;
          _checkingExternalApps = false;
          _checkingStorageAccess = false;
          _checkingLute3 = false;
          _storageAccessGranted = false;
        });
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

  Future<bool> _checkStorageAccessGranted() async {
    try {
      final androidVersion = await TermuxService.getAndroidVersion();
      if (androidVersion != null && androidVersion >= 30) {
        return await Permission.manageExternalStorage.isGranted;
      }
      return await Permission.storage.isGranted;
    } catch (_) {
      return false;
    }
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
      _isInstalling = true;
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
              backgroundColor: context.appColorScheme.error.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _isLoading = false;
          _isInstalling = false;
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
      _isInstalling = false;
    });

    if (mounted) {
      final message = switch (result) {
        'COMPLETE' => 'Lute3 installed successfully!',
        'CANCELLED' => 'Installation cancelled',
        _ => 'Installation failed. Check Downloads folder for log files',
      };
      final backgroundColor = switch (result) {
        'COMPLETE' => context.appColorScheme.semantic.success,
        'CANCELLED' => context.appColorScheme.semantic.warning,
        _ => context.appColorScheme.error.error,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    _refreshStatus();
  }

  Future<void> _cancelInstallation() async {
    await TermuxService.cancelInstallation();
    setState(() {
      _isInstalling = false;
    });
  }

  Future<void> _refreshServerStatus() async {
    final serverRunning = await TermuxService.isServerRunning(
      Settings.termuxUrl,
    );
    setState(() {
      _serverRunning = serverRunning;
    });
  }

  Future<void> _startServer() async {
    setState(() {
      _isStartingServer = true;
    });

    try {
      final androidVersion = await TermuxService.getAndroidVersion();
      if (androidVersion != null && androidVersion >= 33) {
        final hasPermission = await TermuxService.hasNotificationPermission();
        if (!hasPermission) {
          await TermuxService.requestNotificationPermission();
          setState(() {
            _isStartingServer = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Notification permission check failed: $e');
    }

    await TermuxService.startServer();
    await Future.delayed(const Duration(seconds: 2));
    await _refreshServerStatus();

    setState(() {
      _isStartingServer = false;
    });
  }

  Future<void> _stopServer() async {
    setState(() {
      _isStoppingServer = true;
    });

    await TermuxService.stopServer();
    await Future.delayed(const Duration(seconds: 2));
    await _refreshServerStatus();

    setState(() {
      _isStoppingServer = false;
    });
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
          SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: context.appColorScheme.semantic.success,
            duration: const Duration(seconds: 2),
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
            backgroundColor: context.appColorScheme.error.error,
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
            backgroundColor: context.appColorScheme.semantic.success,
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
            backgroundColor: context.appColorScheme.error.error,
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
          SnackBar(
            content: Text('Local backup created successfully'),
            backgroundColor: context.appColorScheme.semantic.success,
            duration: const Duration(seconds: 2),
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
            backgroundColor: context.appColorScheme.error.error,
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
            backgroundColor: context.appColorScheme.semantic.success,
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
            backgroundColor: context.appColorScheme.error.error,
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
              style: TextStyle(
                fontSize: 12,
                color: context.appColorScheme.text.secondary,
              ),
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
      _currentStep = 'PREPARING';
      _currentStatus = 'Initializing restore...';
      _currentMaxWaitSeconds = 30;
    });

    _progressSubscription?.cancel();
    _progressSubscription = TermuxService.getInstallProgress().listen(
      (progress) {
        debugPrint('Restore progress received: $progress');
        if (mounted && _isRestoring) {
          setState(() {
            final step = progress['step'] ?? '';
            final status = progress['status'] ?? '';
            debugPrint('Restore step: $step, status: $status');
            if (step.isNotEmpty) {
              _currentStep = step;
            }
            if (status.isNotEmpty) {
              _currentStatus = status;
            }
            _currentMaxWaitSeconds = progress['maxWaitSeconds'] ?? 30;
          });
        }
      },
      onError: (error) {
        debugPrint('Restore progress error: $error');
      },
    );

    try {
      // Step 1: Save original backup_dir
      // Step 1: Skip saving backup_dir - Kotlin now always sets it to Termux path after restore

      // Step 2: Optional backup
      if (createBackupFirst) {
        setState(() {
          _currentStep = 'CREATING_BACKUP';
          _currentStatus = 'Creating backup before restore...';
          _currentMaxWaitSeconds = 30;
        });
        debugPrint('Creating backup via server...');
        try {
          final backupResult = await BackupService.createBackup(
            Settings.termuxUrl,
          ).timeout(const Duration(seconds: 30));
          debugPrint('Backup result: $backupResult');
          if (!backupResult.contains('successfully')) {
            await _progressSubscription?.cancel();
            _progressSubscription = null;
            setState(() {
              _isRestoring = false;
              _currentStep = '';
              _currentStatus = '';
            });
            _showRestoreErrorDialog('Backup failed: $backupResult');
            return;
          }
        } on TimeoutException {
          await _progressSubscription?.cancel();
          _progressSubscription = null;
          setState(() {
            _isRestoring = false;
            _currentStep = '';
            _currentStatus = '';
          });
          _showRestoreErrorDialog('Backup creation timed out after 30 seconds');
          return;
        }
      }

      // Step 3: Execute Termux restore
      debugPrint(
        'Calling TermuxService.restoreBackup with filePath: $filePath',
      );
      final result = await TermuxService.restoreBackup(filePath);
      debugPrint('TermuxService.restoreBackup returned: $result');

      await _progressSubscription?.cancel();
      _progressSubscription = null;

      setState(() {
        _isRestoring = false;
        _currentStep = '';
        _currentStatus = '';
      });

      if (!result.startsWith('SUCCESS')) {
        _showRestoreErrorDialog(result);
        return;
      }

      // Step 4: Skip restoring backup_dir - Kotlin now always sets it to Termux path after restore

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore completed successfully'),
            backgroundColor: context.appColorScheme.semantic.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      _refreshStatus();
    } on TimeoutException catch (e) {
      debugPrint('Restore timeout: $e');
      await _progressSubscription?.cancel();
      _progressSubscription = null;
      setState(() {
        _isRestoring = false;
        _currentStep = '';
        _currentStatus = '';
      });
      _showRestoreErrorDialog(
        'Operation timed out: ${e.message ?? "Unknown timeout"}',
      );
    } catch (e, stack) {
      debugPrint('Restore exception: $e');
      debugPrint('Stack trace: $stack');
      await _progressSubscription?.cancel();
      _progressSubscription = null;
      setState(() {
        _isRestoring = false;
        _currentStep = '';
        _currentStatus = '';
      });
      _showRestoreErrorDialog('Restore failed: $e');
    }
  }

  void _showRestoreErrorDialog(String message) {
    if (!mounted) return;
    final displayMessage = message
        .replaceFirst('FAIL: ', '')
        .replaceFirst('FAIL:', '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline),
            SizedBox(width: 8),
            Text('Restore Failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            displayMessage,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final files = await StorageService.getBackupFilesInDownloads();
    debugPrint('Found ${files.length} backup files in Downloads');

    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No backup files found in Downloads folder'),
            backgroundColor: context.appColorScheme.semantic.warning,
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
                  '${lastModified.year}-${lastModified.month.toString().padLeft(2, '0')}-${lastModified.day.toString().padLeft(2, '0')} ${lastModified.hour}:${lastModified.minute.toString().padLeft(2, '0')} - ${_formatFileSize(size)}',
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

  Future<String?> _saveServerSettings() async {
    try {
      final settings = await BackupService.getAllSettings(Settings.termuxUrl);
      final downloadsDir = Directory('/storage/emulated/0/Download');
      await downloadsDir.create(recursive: true);
      final file = File('${downloadsDir.path}/termux_settings_backup.json');
      await file.writeAsString(json.encode(settings));
      return file.path;
    } catch (e) {
      debugPrint('Failed to save server settings: $e');
      return null;
    }
  }

  Future<bool> _restoreServerSettings(String filePath) async {
    try {
      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final settings = json.decode(jsonStr) as Map<String, dynamic>;

      final checkboxFields = [
        'backup_enabled',
        'backup_auto',
        'backup_warn',
        'show_highlights',
        'open_popup_in_new_tab',
        'stop_audio_on_term_form_open',
        'term_popup_promote_parent_translation',
        'term_popup_show_components',
        'use_ankiconnect',
      ];

      final textFieldFields = [
        'backup_dir',
        'backup_count',
        'current_theme',
        'custom_styles',
        'mecab_path',
        'japanese_reading',
        'stats_calc_sample_size',
        'ankiconnect_url',
      ];

      final formBody = <String, String>{};

      for (final field in checkboxFields) {
        final value = settings[field];
        if (value == true || value == '1' || value == 'true') {
          formBody[field] = 'y';
        }
      }

      for (final field in textFieldFields) {
        final value = settings[field];
        formBody[field] = value?.toString() ?? '';
      }

      formBody['submit'] = 'Save';

      final response = await http.post(
        Uri.parse('${Settings.termuxUrl}/settings/index'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to restore server settings: $e');
      return false;
    }
  }

  void _showRestoreFlowDialog() {
    int dialogStep = 0;
    String? settingsPath;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Restore Flow'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRestoreFlowStep(
                    setDialogState,
                    step: 1,
                    title: 'Save Settings',
                    subtitle: 'Save settings to JSON file',
                    enabled: dialogStep == 0 && !isLoading,
                    completed: dialogStep > 0 && settingsPath != null,
                    isLoading: isLoading,
                    onTap: () async {
                      setDialogState(() => isLoading = true);
                      final path = await _saveServerSettings();
                      if (path == null) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to save settings. Please try again.',
                            ),
                            backgroundColor: context.appColorScheme.error.error,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          settingsPath = path;
                          dialogStep = 1;
                          isLoading = false;
                        });
                      }
                    },
                  ),
                  _buildRestoreFlowStep(
                    setDialogState,
                    step: 2,
                    title: 'Create Backup (Optional)',
                    subtitle: 'Create lute3 backup on Termux',
                    enabled: dialogStep == 1 && !isLoading,
                    completed: dialogStep > 1,
                    isLoading: isLoading,
                    onTap: () async {
                      final skip = await showDialog<bool>(
                        context: dialogContext,
                        builder: (context) => AlertDialog(
                          title: const Text('Create Backup?'),
                          content: const Text(
                            'Do you want to create a backup of your Termux data before restoring?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Skip'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Create Backup'),
                            ),
                          ],
                        ),
                      );
                      if (skip == null) return;
                      if (skip) {
                        setDialogState(() => dialogStep = 2);
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await BackupService.createBackup(
                          Settings.termuxUrl,
                        ).timeout(const Duration(seconds: 30));
                        setDialogState(() {
                          dialogStep = 2;
                          isLoading = false;
                        });
                      } catch (e) {
                        debugPrint('Backup failed: $e');
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Backup failed: $e')),
                        );
                      }
                    },
                  ),
                  _buildRestoreFlowStep(
                    setDialogState,
                    step: 3,
                    title: 'Stop Server',
                    subtitle: 'Shutdown Termux server',
                    enabled: dialogStep >= 1 && !isLoading,
                    completed: dialogStep > 2,
                    isLoading: isLoading,
                    onTap: () async {
                      setDialogState(() => isLoading = true);
                      final stopped = await TermuxService.stopServer();
                      await _refreshServerStatus();

                      if (!stopped || _serverRunning) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to stop server. Please try again or stop it manually in Termux.',
                            ),
                            backgroundColor: context.appColorScheme.error.error,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          dialogStep = 3;
                          isLoading = false;
                        });
                      }
                    },
                  ),
                  _buildRestoreFlowStep(
                    setDialogState,
                    step: 4,
                    title: 'Restore',
                    subtitle: 'Restore from backup file',
                    enabled: dialogStep == 3 && !isLoading,
                    completed: dialogStep > 3,
                    isLoading: isLoading,
                    onTap: () async {
                      final files =
                          await StorageService.getBackupFilesInDownloads();
                      if (files.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('No backup files found in Downloads'),
                          ),
                        );
                        return;
                      }
                      final selectedFile = await showDialog<String>(
                        context: dialogContext,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Backup File'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                final filePath = files[index];
                                final fileName = filePath.split('/').last;
                                return ListTile(
                                  title: Text(fileName),
                                  onTap: () => Navigator.pop(context, filePath),
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
                      if (selectedFile == null) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final result = await TermuxService.restoreBackup(
                          selectedFile,
                        );
                        if (result.startsWith('SUCCESS')) {
                          if (settingsPath != null) {
                            final settingsRestored =
                                await _restoreServerSettings(settingsPath!);
                            if (!settingsRestored) {
                              throw Exception(
                                'Database restored, but restoring server settings failed',
                              );
                            }
                          }
                          setDialogState(() {
                            dialogStep = 4;
                            isLoading = false;
                          });
                        } else {
                          throw Exception(result);
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Restore failed: $e')),
                        );
                      }
                    },
                  ),
                  _buildRestoreFlowStep(
                    setDialogState,
                    step: 5,
                    title: 'Start Server',
                    subtitle: 'Restart Termux server',
                    enabled: dialogStep == 4 && !isLoading,
                    completed: dialogStep > 4,
                    isLoading: isLoading,
                    onTap: () async {
                      setDialogState(() => isLoading = true);
                      final started = await TermuxService.startServer();
                      await Future.delayed(const Duration(seconds: 2));
                      await _refreshServerStatus();
                      if (!started || !_serverRunning) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to start server. Please try again or start it manually in Termux.',
                            ),
                            backgroundColor: context.appColorScheme.error.error,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          dialogStep = 5;
                          isLoading = false;
                        });
                        Navigator.pop(dialogContext);
                        _refreshStatus();
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRestoreFlowStep(
    StateSetter setDialogState, {
    required int step,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool completed,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? context.appColorScheme.semantic.success
                      : (enabled && !isLoading
                            ? context.appColorScheme.material3.primary
                            : context.appColorScheme.text.secondary),
                ),
                child: completed
                    ? Icon(
                        Icons.check,
                        color: context.appColorScheme.text.onPrimary,
                        size: 18,
                      )
                    : (isLoading
                          ? null
                          : Text(
                              step.toString(),
                              style: TextStyle(
                                color: context.appColorScheme.text.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
              ),
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.appColorScheme.text.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: enabled && !isLoading ? onTap : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: enabled && !isLoading
                          ? context.appColorScheme.text.primary
                          : context.appColorScheme.text.secondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColorScheme.text.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    WidgetLogger.logRebuild('TermuxScreen', _buildCount);

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
    if (_isLoading || _isRestoring) {
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
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColorScheme.text.secondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              if (_currentMaxWaitSeconds > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Estimated wait time: ~$_currentMaxWaitSeconds seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColorScheme.text.secondary.withValues(
                      alpha: 0.9,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Output logs are saved to Downloads folder',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appColorScheme.text.secondary.withValues(
                      alpha: 0.8,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_isInstalling) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _cancelInstallation,
                  icon: Icon(
                    Icons.cancel,
                    color: context.appColorScheme.error.error,
                  ),
                  label: Text(
                    'Cancel Installation',
                    style: TextStyle(color: context.appColorScheme.error.error),
                  ),
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
                      'Storage Access',
                      _storageAccessGranted,
                      _checkingStorageAccess,
                      !_checkingStorageAccess,
                      'Not granted',
                      onTap: _showStorageAccessInstructions,
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
    bool isConfirmed,
    String defaultText, {
    String? statusText,
    VoidCallback? onTap,
  }) {
    String displayText;

    if (isLoading) {
      displayText = 'Checking...';
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
            bottom: BorderSide(
              color: context.appColorScheme.border.outline.withValues(
                alpha: 0.4,
              ),
              width: 1,
            ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appColorScheme.text.secondary,
                    ),
                  ),
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  Icon(
                    status ? Icons.check_circle : Icons.error,
                    color: status
                        ? context.appColorScheme.semantic.success
                        : context.appColorScheme.error.error,
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
                    onPressed: (_serverRunning || _isStartingServer)
                        ? null
                        : _startServer,
                    icon: _isStartingServer
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.appColorScheme.text.onPrimary,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      _isStartingServer ? 'Starting...' : 'Start Server',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!_serverRunning || _isStoppingServer)
                        ? null
                        : _stopServer,
                    icon: _isStoppingServer
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.appColorScheme.text.onPrimary,
                            ),
                          )
                        : const Icon(Icons.stop),
                    label: Text(
                      _isStoppingServer ? 'Stopping...' : 'Stop Server',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColorScheme.error.error,
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
              'Termux Restore',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _serverRunning ? _showRestoreFlowDialog : null,
              icon: const Icon(Icons.restore),
              label: const Text('Restore Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColorScheme.semantic.warning,
                minimumSize: const Size(double.infinity, 48),
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
                      color: context.appColorScheme.text.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Server not connected',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.appColorScheme.text.secondary,
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
                      color: context.appColorScheme.text.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Server not connected or No backups found',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.appColorScheme.text.secondary,
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
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColorScheme.text.secondary,
                              ),
                            ),
                            Text(
                              size,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColorScheme.text.secondary,
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
                    Icon(
                      Icons.link_off,
                      size: 16,
                      color: context.appColorScheme.text.secondary,
                    ),

                    const SizedBox(width: 8),
                    Text(
                      'No local URL configured',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.appColorScheme.text.secondary,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _isBackingUpLocal ? null : _createLocalBackup,
                icon: _isBackingUpLocal
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColorScheme.text.onPrimary,
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
                        color: context.appColorScheme.text.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Server not connected',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appColorScheme.text.secondary,
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
                        color: context.appColorScheme.text.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No backups found',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appColorScheme.text.secondary,
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
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appColorScheme.text.secondary,
                                ),
                              ),
                              Text(
                                size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appColorScheme.text.secondary,
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
                        color: context
                            .appColorScheme
                            .background
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'echo "allow-external-apps=true" > ~/.termux/termux.properties',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: context.appColorScheme.text.primary,
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

  void _showStorageAccessInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Storage Access'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Termux needs access to shared storage (Download folder) for file operations.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 1: Run this command in Termux:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context
                            .appColorScheme
                            .background
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'termux-setup-storage',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: context.appColorScheme.text.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'termux-setup-storage'),
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
                'Step 2: When prompted type y and then press enter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
            SnackBar(
              content: Text('Termux initialized successfully'),
              backgroundColor: context.appColorScheme.semantic.success,
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
