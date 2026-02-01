import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/core/services/backup_service.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

class TermuxScreen extends ConsumerStatefulWidget {
  const TermuxScreen({super.key});

  @override
  ConsumerState<TermuxScreen> createState() => _TermuxScreenState();
}

class _TermuxScreenState extends ConsumerState<TermuxScreen> {
  bool _isLoading = true;
  bool _termuxInstalled = false;
  bool _permissionGranted = false;
  bool _externalAppsEnabled = false;
  String _lute3Status = 'UNKNOWN';
  String? _lute3Version;
  String? _termuxVersion;
  bool _serverRunning = false;
  List<Map<String, dynamic>>? _backups;
  bool _isBackingUp = false;
  final Set<String> _downloadingBackups = {};

  StreamSubscription? _progressSubscription;
  String _currentStep = '';
  String _currentStatus = '';
  int _currentMaxWaitSeconds = 60;

  // tmux-related state
  String _tmuxStatus = 'UNKNOWN';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _termuxInstalled = await TermuxService.isTermuxInstalled();

      if (_termuxInstalled) {
        try {
          _permissionGranted = await TermuxService.isTermuxPermissionGranted();

          try {
            _lute3Status = await TermuxService.isLute3Installed();
          } catch (e) {
            _lute3Status = 'UNKNOWN';
          }

          try {
            _serverRunning = await TermuxService.isServerRunning();
          } catch (e) {
            _serverRunning = false;
          }

          // Request storage permission before checking external apps
          try {
            final hasStoragePermission =
                await Permission.manageExternalStorage.isGranted;
            if (!hasStoragePermission) {
              final storageResult = await Permission.manageExternalStorage
                  .request();
              if (!storageResult.isGranted) {
                _externalAppsEnabled = false;
              } else {
                try {
                  _externalAppsEnabled =
                      await TermuxService.checkExternalAppsEnabled();
                } catch (e) {
                  _externalAppsEnabled = false;
                }
              }
            } else {
              try {
                _externalAppsEnabled =
                    await TermuxService.checkExternalAppsEnabled();
              } catch (e) {
                _externalAppsEnabled = false;
              }
            }
          } catch (e) {
            _externalAppsEnabled = false;
          }

          try {
            _termuxVersion = await TermuxService.getTermuxVersion();
          } catch (e) {
            _termuxVersion = null;
          }
        } catch (e) {
          _permissionGranted = false;
          _externalAppsEnabled = false;
        }
      }

      if (_lute3Status == 'INSTALLED') {
        try {
          _lute3Version = await TermuxService.getLute3Version();
        } catch (e) {
          _lute3Version = null;
        }
      }

      if (_lute3Status == 'INSTALLED') {
        try {
          final serverUrl = ref.read(settingsProvider).serverUrl;
          _backups = await BackupService.listBackups(serverUrl);
          print('Backups found: ${_backups?.length ?? 0}');
          if (_backups != null) {
            for (var backup in _backups!) {
              print(
                'Backup: ${backup['filename']} - ${backup['lastModified']}',
              );
            }
          }
        } catch (e) {
          print('Error loading backups: $e');
          _backups = null;
        }
      }

      // Check tmux status
      try {
        _tmuxStatus = await TermuxService.getTmuxStatus();
      } catch (e) {
        _tmuxStatus = 'ERROR';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking Termux status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _openFStore() async {
    final url = Uri.parse('https://termux.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openTermuxApp() async {
    const termuxPackage = 'com.termux';
    try {
      // Try to launch the Termux app directly using its package name
      final uri = Uri.parse('android-app://com.termux');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Alternative approach: try using Android Intent
        await launchUrl(
          Uri.parse(
            'intent://com.termux#Intent;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;launchFlags=0x10000000;package=com.termux;end',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // If direct launch fails, try using app_settings to open the app info
      AppSettings.openAppSettings();
    }
  }

  Future<void> _openAppSettings() async {
    AppSettings.openAppSettings(type: AppSettingsType.settings);
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

    final result = await TermuxService.installLute3Chained();

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

  Future<void> _startServer() async {
    await TermuxService.startServer();
    await Future.delayed(const Duration(seconds: 2));
    _refreshStatus();
  }

  Future<void> _stopServer() async {
    await TermuxService.stopServer();
    await Future.delayed(const Duration(seconds: 2));
    _refreshStatus();
  }

  Future<void> _showTmuxAttachInstructions() async {
    final instructions = await TermuxService.attachTmuxSession();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('View Live Installation Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can view the live installation progress by attaching to the tmux session:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  instructions,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 Tips:\n'
                '• Use Ctrl+b then "d" to detach without stopping the installation\n'
                '• You can safely close the Termux app after detaching\n'
                '• The app will continue to show progress updates',
                style: TextStyle(fontSize: 12, color: const Color(0xFF616161)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                _openTermuxApp();
                Navigator.of(context).pop();
              },
              child: const Text('Open Termux'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final serverUrl = ref.read(settingsProvider).serverUrl;
      await BackupService.createBackup(serverUrl);

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
      final serverUrl = ref.read(settingsProvider).serverUrl;
      final result = await BackupService.downloadBackup(serverUrl, filename);

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
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildServerCard(),
          const SizedBox(height: 16),
          _buildBackupCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
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
            _buildStatusRow('Termux', _termuxInstalled, () {
              if (!_termuxInstalled) {
                _openFStore();
              } else {
                _openTermuxApp();
              }
            }),
            if (_termuxInstalled)
              _buildStatusRow('External Apps', _externalAppsEnabled, () {
                _showExternalAppsInstructions();
              }),
            if (_termuxInstalled)
              _buildStatusRow('Permission', _permissionGranted, () {
                _openAppSettings();
              }),
            if (_termuxInstalled)
              _buildStatusRow('Lute3', _lute3Status == 'INSTALLED', () {
                _installLute3();
              }, statusLabel: _lute3Status),

            if (_lute3Status == 'INSTALLED') ...[
              _buildInfoRow('Lute3 Version', _lute3Version ?? 'Unknown'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String labelText,
    bool status,
    VoidCallback onTap, {
    String? statusLabel,
  }) {
    String statusText;
    if (labelText == 'Permission') {
      statusText = status ? 'Granted' : 'Not granted';
    } else if (labelText == 'External Apps') {
      statusText = status ? 'Enabled' : 'Disabled';
    } else if (labelText == 'Lute3' && statusLabel != null) {
      statusText = statusLabel; // Use the specific status label for Lute3
    } else {
      statusText = status ? 'Installed' : 'Not installed';
    }

    final showFdroidLink = labelText == 'Termux' && !status;

    return InkWell(
      onTap: onTap,
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
                Text(
                  statusText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                if (showFdroidLink)
                  Row(
                    children: [
                      Text(
                        'Open in F-Droid',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                Icon(
                  status ? Icons.check_circle : Icons.error,
                  color: status ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String labelText, String value) {
    return Container(
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard() {
    if (_lute3Status != 'INSTALLED') {
      return const SizedBox.shrink();
    }

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
    if (_lute3Status != 'INSTALLED') {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Backup',
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
            if (_backups != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Backups (${_backups!.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              if (_backups!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No backups found. Create a backup first.'),
                )
              else
                ..._backups!.take(5).map((backup) {
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
              const SizedBox(height: 16),
              const Text(
                'Step 1: Open the Termux app',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 2: Run these commands one by one:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
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
              const SizedBox(height: 12),
              const Text(
                'You should see: allow-external-apps=true',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 3: Force-stop Termux',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Settings → Apps → Termux → Force Stop',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'Step 4: Return to LuteForMobile and refresh',
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
}
