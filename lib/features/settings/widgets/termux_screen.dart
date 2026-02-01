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
  bool _isBackgroundChecking = false;
  bool _termuxInstalled = false;
  bool _termuxInstalledConfirmed = false;
  bool _permissionGranted = false;
  bool _externalAppsEnabled = false;
  String _lute3Status = 'UNKNOWN';
  String? _lute3Version;
  bool _serverRunning = false;
  List<Map<String, dynamic>>? _backups;
  bool _isBackingUp = false;
  final Set<String> _downloadingBackups = {};

  StreamSubscription? _progressSubscription;
  String _currentStep = '';
  String _currentStatus = '';
  int _currentMaxWaitSeconds = 60;

  String _tmuxStatus = 'UNKNOWN';

  bool _checkingTermux = false;
  bool _checkingPermission = false;
  bool _checkingExternalApps = false;
  bool _checkingLute3 = false;
  bool _checkingServer = false;
  bool _checkingVersion = false;
  bool _checkingTmux = false;
  bool _checkingBackups = false;

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
        _tmuxStatus = 'UNKNOWN';
      } else {
        _termuxInstalled = false;
        _termuxInstalledConfirmed = false;
        _permissionGranted = false;
        _externalAppsEnabled = false;
        _serverRunning = false;
        _tmuxStatus = 'UNKNOWN';
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
      _checkingTmux = true;
    });

    try {
      final termuxInstalled = await TermuxService.isTermuxInstalled();
      setState(() {
        _checkingTermux = false;
        _termuxInstalled = termuxInstalled;
        _termuxInstalledConfirmed = true;
      });

      if (termuxInstalled) {
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

        final tmuxStatus = await TermuxService.getTmuxStatus();
        setState(() {
          _checkingTmux = false;
          _tmuxStatus = tmuxStatus;
        });

        if (lute3Status == 'INSTALLED') {
          setState(() {
            _checkingVersion = true;
          });
          final lute3Version = await TermuxService.getLute3Version();
          setState(() {
            _checkingVersion = false;
            _lute3Version = lute3Version;
          });

          if (serverRunning) {
            setState(() {
              _checkingBackups = true;
            });
            try {
              final serverUrl = ref.read(settingsProvider).serverUrl;
              final backups = await BackupService.listBackups(serverUrl);
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
      }
    } catch (e) {
      print('Background status check failed: $e');
    } finally {
      setState(() {
        _isBackgroundChecking = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    _runBackgroundStatusCheck();
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
                style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
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
          _buildInfoRow(
            'Termux',
            _termuxInstalledConfirmed
                ? (_termuxInstalled ? 'Installed' : 'Not installed')
                : 'Checking...',
            checking: _checkingTermux,
          ),
          if (_termuxInstalled) ...[
            _buildInfoRow(
              'Permission',
              _permissionGranted ? 'Granted' : 'Not granted',
              checking: _checkingPermission,
            ),
            _buildInfoRow(
              'External Apps',
              _externalAppsEnabled ? 'Enabled' : 'Disabled',
              checking: _checkingExternalApps,
            ),
            _buildInfoRow('Lute3', _lute3Status, checking: _checkingLute3),
            if (_lute3Status == 'INSTALLED' && _lute3Version != null)
              _buildInfoRow(
                'Version',
                _lute3Version!,
                checking: _checkingVersion,
              ),
            _buildInfoRow(
              'Server',
              _serverRunning ? 'Running' : 'Stopped',
              checking: _checkingServer,
            ),
            _buildInfoRow('Tmux', _tmuxStatus, checking: _checkingTmux),
            const SizedBox(height: 16),
            _buildServerCard(),
            const SizedBox(height: 16),
            _buildBackupCard(),
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
                label: const Text('Get Termux from F-Droid'),
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

  Widget _buildInfoRow(
    String labelText,
    String value, {
    bool checking = false,
  }) {
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
          Row(
            children: [
              if (checking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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
                      'Server not connected. Start the server to view backups.',
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
                      'Server not connected or No backups found. Create a backup first.',
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
