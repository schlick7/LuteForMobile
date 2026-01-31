import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/core/services/storage_service.dart';

class TermuxScreen extends StatefulWidget {
  const TermuxScreen({super.key});

  @override
  State<TermuxScreen> createState() => _TermuxScreenState();
}

class _TermuxScreenState extends State<TermuxScreen> {
  bool _isLoading = true;
  bool _termuxInstalled = false;
  bool _permissionGranted = false;
  bool _externalAppsEnabled = false;
  String _lute3Status = 'UNKNOWN';
  String? _lute3Version;
  String? _termuxVersion;
  bool _serverRunning = false;
  String? _message;

  List<Map<String, dynamic>>? _backups;
  bool _isBackingUp = false;
  String _remoteUrl = '';
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
      _message = null;
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
          _backups = await TermuxService.listBackups();
        } catch (e) {
          _backups = null;
        }
      }
    } catch (e) {
      setState(() {
        _message = 'Error checking Termux status: $e';
      });
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
    setState(() {
      _isLoading = true;
      _message = 'Installing Lute3 Server...\nThis may take 1-3 minutes.';
    });

    final result = await TermuxService.installLute3();

    setState(() {
      _message = result == 'COMPLETE'
          ? 'Lute3 installed successfully!'
          : 'Installation failed.';
      _isLoading = false;
    });

    await Future.delayed(const Duration(seconds: 2));
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

  Future<void> _testHeartbeat() async {
    await TermuxService.touchHeartbeat();
    setState(() {
      _message = 'Heartbeat test sent';
    });
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    final result = await TermuxService.createBackup();

    setState(() {
      _message = result;
      _isBackingUp = false;
    });

    await Future.delayed(const Duration(seconds: 2));
    _refreshStatus();
  }

  Future<void> _downloadBackup(String filename) async {
    setState(() {
      _message = 'Downloading $filename...';
    });

    final result = await TermuxService.downloadBackup(filename);

    setState(() {
      _message = result != null ? 'Downloaded to: $result' : 'Download failed';
    });
  }

  Future<void> _restoreBackup() async {
    final hasPermissions = await StorageService.checkStoragePermissions();

    if (!hasPermissions) {
      final granted = await StorageService.requestStoragePermissions();
      if (!granted) {
        setState(() {
          _message = 'Storage permissions are required to restore backups';
        });
        return;
      }
    }

    setState(() {
      _message = 'Selecting backup file...';
    });

    final backupPath = await StorageService.selectBackupFile();

    if (backupPath == null) {
      setState(() {
        _message = 'No backup file selected';
      });
      return;
    }

    setState(() {
      _message = 'Restoring backup...';
    });

    final result = await TermuxService.restoreBackup();

    setState(() {
      _message = result;
    });

    await Future.delayed(const Duration(seconds: 5));
    _refreshStatus();
  }

  Future<void> _syncWithRemote() async {
    if (_remoteUrl.isEmpty) {
      setState(() {
        _message = 'Please enter remote server URL';
      });
      return;
    }

    setState(() {
      _message = 'Syncing backup to remote server...';
    });

    final result = await TermuxService.syncWithRemote(
      _remoteUrl,
      apiKey: _apiKey.isEmpty ? null : _apiKey,
    );

    setState(() {
      _message = result;
    });
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color:
                    _message!.contains('Error') || _message!.contains('failed')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _message!.contains('Error') ||
                          _message!.contains('failed')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color:
                      _message!.contains('Error') ||
                          _message!.contains('failed')
                      ? Colors.red.shade900
                      : Colors.green.shade900,
                ),
              ),
            ),
          ],
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
              _buildInfoRow('Termux Version', _termuxVersion ?? 'Unknown'),
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _testHeartbeat,
              icon: const Icon(Icons.favorite),
              label: const Text('Test Heartbeat'),
            ),
            const SizedBox(height: 8),
            Text(
              'Server will auto-shutdown after 30 minutes of inactivity',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              'Database Backup & Sync',
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
            if (_backups != null && _backups!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Available Backups',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._backups!.take(5).map((backup) {
                final filename = backup['filename'] as String;
                final lastModified = backup['lastModified'] as int;
                final size = backup['size'] as String;
                final isManual = backup['isManual'] as bool;
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
                            if (isManual)
                              Chip(
                                label: const Text('Manual'),
                                backgroundColor: Colors.blue.shade100,
                                labelStyle: TextStyle(fontSize: 10),
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _downloadBackup(filename),
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _restoreBackup(),
                                icon: const Icon(Icons.restore, size: 16),
                                label: const Text('Restore'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 24),
            Text(
              'Sync with Remote Server',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Remote Server URL',
                hintText: 'https://your-lute-server.com',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _remoteUrl = value;
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'API Key (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _apiKey = value;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _remoteUrl.isEmpty ? null : _syncWithRemote,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Backup to Remote'),
            ),
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
                'Step 4: Reopen Termux and verify',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Run: cat ~/.termux/termux.properties',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'Step 5: Test with a simple command',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Run: echo "Termux test"',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'Step 6: Return to LuteForMobile and refresh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Troubleshooting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Make sure you have Termux 0.118.3 or higher installed',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Verify the RUN_COMMAND permission is granted in Android Settings',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• If still showing "Disabled", try using the app anyway',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The detection may fail on some devices even if external apps are properly configured.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
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
