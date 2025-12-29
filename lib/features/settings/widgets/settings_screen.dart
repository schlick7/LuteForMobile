import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/settings_provider.dart';
import '../../../shared/theme/theme_extensions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SettingsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverUrlController;
  late TextEditingController _bookIdController;
  late TextEditingController _pageIdController;
  bool _isTesting = false;
  String? _connectionStatus;

  static const List<Color> _accentColorOptions = [
    Color(0xFF1976D2), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9E9E80), // Brown
    Color(0xFF6750A4), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Grey
    Color(0xFF49454F), // Light gray (text secondary)
    Color(0xFF938F99), // Lighter Gray
    Color(0xFFBA1A1A), // Red
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _serverUrlController = TextEditingController(text: settings.serverUrl);
    _bookIdController = TextEditingController(
      text: settings.defaultBookId.toString(),
    );
    _pageIdController = TextEditingController(
      text: settings.defaultPageId.toString(),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _bookIdController.dispose();
    _pageIdController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _connectionStatus = null;
    });

    final url = _serverUrlController.text.trim();
    try {
      final dio = Dio();
      final response = await dio.get(
        '$url/read/${ref.read(settingsProvider).defaultBookId}/page/${ref.read(settingsProvider).defaultPageId}',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectionStatus = 'Connection successful!';
          _isTesting = false;
        });
      } else {
        setState(() {
          _connectionStatus = 'Connection failed: ${response.statusCode}';
          _isTesting = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
        _isTesting = false;
      });
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(settingsProvider.notifier)
          .updateServerUrl(_serverUrlController.text.trim());

      final bookId = int.tryParse(_bookIdController.text);
      if (bookId != null) {
        ref.read(settingsProvider.notifier).updateBookId(bookId);
      }

      final pageId = int.tryParse(_pageIdController.text);
      if (pageId != null) {
        ref.read(settingsProvider.notifier).updatePageId(pageId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final themeSettings = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (widget.scaffoldKey != null &&
                  widget.scaffoldKey!.currentState != null) {
                widget.scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        title: const Text('Settings'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'http://localhost:5001',
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.customColors.accentLabelColor,
                            ),
                        border: const OutlineInputBorder(),
                        errorText: settings.isUrlValid
                            ? null
                            : 'Invalid URL format',
                        suffixIcon: settings.isUrlValid
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.connected,
                              )
                            : Icon(
                                Icons.error,
                                color: Theme.of(context).colorScheme.error,
                              ),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a server URL';
                        }
                        try {
                          final uri = Uri.parse(value.trim());
                          if (!uri.hasScheme ||
                              (uri.scheme != 'http' && uri.scheme != 'https')) {
                            return 'URL must start with http:// or https://';
                          }
                          if (uri.host.isEmpty) {
                            return 'Please enter a valid host';
                          }
                        } catch (_) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bookIdController,
                      decoration: InputDecoration(
                        labelText: 'Default Book ID',
                        hintText: '18',
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.customColors.accentLabelColor,
                            ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a book ID';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pageIdController,
                      decoration: InputDecoration(
                        labelText: 'Default Page ID',
                        hintText: '1',
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.customColors.accentLabelColor,
                            ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a page ID';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTesting ? null : _testConnection,
                            child: _isTesting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Test Connection'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            child: const Text('Save Settings'),
                          ),
                        ),
                      ],
                    ),
                    if (_connectionStatus != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionStatus!.contains('successful')
                              ? Theme.of(
                                  context,
                                ).colorScheme.success.withValues(alpha: 0.1)
                              : Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionStatus!.contains('successful')
                                ? Theme.of(context).colorScheme.success
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _connectionStatus!.contains('successful')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _connectionStatus!.contains('successful')
                                  ? Theme.of(context).colorScheme.success
                                  : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(
                                  color:
                                      _connectionStatus!.contains('successful')
                                      ? Theme.of(context).colorScheme.success
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingRow('Server URL', settings.serverUrl),
                    _buildSettingRow(
                      'Default Book ID',
                      settings.defaultBookId.toString(),
                    ),
                    _buildSettingRow(
                      'Default Page ID',
                      settings.defaultPageId.toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accent Colors',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildAccentColorSetting(
                      context,
                      'Accent Label Color',
                      themeSettings.accentLabelColor,
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateAccentLabelColor(color),
                    ),
                    _buildAccentColorSetting(
                      context,
                      'Accent Button Color',
                      themeSettings.accentButtonColor,
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateAccentButtonColor(color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will reset all settings to their default values.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reset Settings'),
                              content: const Text(
                                'Are you sure you want to reset all settings to defaults?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .resetSettings();
                                    _serverUrlController.text = ref
                                        .read(settingsProvider)
                                        .serverUrl;
                                    _bookIdController.text = ref
                                        .read(settingsProvider)
                                        .defaultBookId
                                        .toString();
                                    _pageIdController.text = ref
                                        .read(settingsProvider)
                                        .defaultPageId
                                        .toString();
                                    setState(() {
                                      _connectionStatus = null;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Settings reset to defaults',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to Defaults'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
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

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorSetting(
    BuildContext context,
    String label,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _accentColorOptions.map((color) {
            final isSelected = color.r == currentColor.r;
            return InkWell(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
