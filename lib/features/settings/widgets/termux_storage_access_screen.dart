import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../../core/logger/widget_logger.dart';
import '../../../shared/theme/theme_extensions.dart';

class TermuxStorageAccessScreen extends StatefulWidget {
  const TermuxStorageAccessScreen({super.key});

  @override
  State<TermuxStorageAccessScreen> createState() =>
      _TermuxStorageAccessScreenState();
}

class _TermuxStorageAccessScreenState extends State<TermuxStorageAccessScreen> {
  int _buildCount = 0;
  bool _isLaunchingTermux = false;

  Future<void> _grantStorageAccess() async {
    if (_isLaunchingTermux) return;

    setState(() {
      _isLaunchingTermux = true;
    });

    try {
      // Check if Termux is installed
      final termuxInstalled = await _isTermuxInstalled();
      if (!termuxInstalled) {
        _showErrorDialog(
          'Termux not installed',
          'Please install Termux from F-Droid or Google Play Store first.',
        );
        return;
      }

      // Open Termux app
      await _openTermuxApp();

      // Show instructions
      _showInstructionsDialog();
    } catch (e) {
      _showErrorDialog(
        'Failed to open Termux',
        'Unable to launch Termux. Please open it manually.',
      );
    } finally {
      setState(() {
        _isLaunchingTermux = false;
      });
    }
  }

  Future<bool> _isTermuxInstalled() async {
    final uri = Uri.parse('android-app://com.termux');
    return await canLaunchUrl(uri);
  }

  Future<void> _openTermuxApp() async {
    final uri = Uri.parse(
      'intent://com.termux#Intent;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;launchFlags=0x10000000;package=com.termux;end',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Failed to launch Termux');
    }
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Storage Access'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('To grant Termux access to shared storage:'),
              const SizedBox(height: 12),
              const Text(
                'Step 1: In Termux, run this command:\n\ntermux-setup-storage\n\nThis will prompt you to grant storage permissions.\n\nStep 2: Tap "Allow" when prompted.\n\nStep 3: Return to LuteForMobile and verify storage access.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyStorageAccess();
            },
            child: const Text('Verify Access'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _verifyStorageAccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Storage Access'),
        content: const Text(
          'To verify storage access is working:<br><br>1. In Termux, run: <br><br>   ls /storage/emulated/0/Download<br><br>2. If you see files listed, storage access is working.<br>3. If you get “Permission denied”, try running termux-setup-storage again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    WidgetLogger.logRebuild('TermuxStorageAccessScreen', _buildCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Access'),
        backgroundColor: context.appColorScheme.material3.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grant Termux Storage Access',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this is needed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Termux needs permission to access your device shared storage (like the Download folder) to save and read files. This is a security feature of Android.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'What to expect',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Termux will prompt you to grant storage access\n\nTap "Allow" when prompted\n\nTermux can then access the Download folder and other shared storage',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Termux Installation',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isLaunchingTermux
                                    ? 'Launching Termux...'
                                    : 'Termux is ready to grant storage access',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appColorScheme.text.primary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _grantStorageAccess,
                    child: _isLaunchingTermux
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.appColorScheme.text.onPrimary,
                              ),
                            ),
                          )
                        : const Text('Grant Storage Access'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Steps (if needed)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Open Termux app\n\nRun: termux-setup-storage\n\nTap "Allow" when prompted\n\nReturn to LuteForMobile',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
