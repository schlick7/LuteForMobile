import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/settings_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/theme_definitions.dart';
import '../../../app.dart';
import 'theme_selector_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SettingsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverUrlController;
  bool _isTesting = false;
  String? _connectionStatus;
  bool _connectionTestPassed = false;

  // Debug variables for double tap testing
  DateTime? _firstTapTime;
  DateTime? _lastDoubleTapTime;
  String _doubleTapDebugInfo = 'Double tap here to test timing';

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
    _serverUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _connectionStatus = null;
      _connectionTestPassed = false;
    });

    final url = _serverUrlController.text.trim();
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectionStatus = 'Connection successful!';
          _isTesting = false;
          _connectionTestPassed = true;
        });
      } else {
        setState(() {
          _connectionStatus = 'Connection failed: ${response.statusCode}';
          _isTesting = false;
          _connectionTestPassed = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
        _isTesting = false;
        _connectionTestPassed = false;
      });
    }
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final newUrl = _serverUrlController.text.trim();

    await _testConnection();

    if (!_connectionTestPassed) {
      return;
    }

    final oldUrl = ref.read(settingsProvider).serverUrl;

    if (oldUrl != newUrl) {
      // Clear current book BEFORE updating URL to prevent race conditions
      await ref.read(settingsProvider.notifier).clearCurrentBook();
      await ref.read(settingsProvider.notifier).updateServerUrl(newUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }

      RestartWidget.restartApp(context);
    } else {
      // Update URL without changing (no book clearing needed)
      await ref.read(settingsProvider.notifier).updateServerUrl(newUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }

      if (oldUrl.isEmpty && newUrl.isNotEmpty) {
        ref.read(booksProvider.notifier).loadBooks();
      }
    }
  }

  void _handleTestDoubleTap() {
    final now = DateTime.now();
    final settings = ref.read(settingsProvider);

    if (_firstTapTime == null) {
      _firstTapTime = now;
      setState(() {
        _doubleTapDebugInfo =
            'First tap recorded. Tap again within ${settings.doubleTapTimeout}ms for double tap.';
      });
    } else {
      final difference = now.difference(_firstTapTime!).inMilliseconds;
      final isDoubleTap = difference <= settings.doubleTapTimeout;

      setState(() {
        _lastDoubleTapTime = now;
        _doubleTapDebugInfo =
            'Time between taps: ${difference}ms\n'
            'Double tap detected: ${isDoubleTap ? "YES" : "NO"}\n'
            'Timeout setting: ${settings.doubleTapTimeout}ms\n'
            'Last test: ${now.toString().substring(11, 19)}';
      });

      _firstTapTime = null; // Reset for next test
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final themeSettings = ref.watch(themeSettingsProvider);

    // Sync controller with current state on every build
    if (_serverUrlController.text != settings.serverUrl) {
      _serverUrlController.value = TextEditingValue(
        text: settings.serverUrl,
        selection: TextSelection.collapsed(offset: settings.serverUrl.length),
      );
    }

    ref.listen(settingsProvider, (previous, next) {
      if (previous?.serverUrl != next.serverUrl &&
          _serverUrlController.text != next.serverUrl) {
        _serverUrlController.value = TextEditingValue(
          text: next.serverUrl,
          selection: TextSelection.collapsed(offset: next.serverUrl.length),
        );
        _connectionTestPassed = false;
        _connectionStatus = null;
      }
    });

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
                        hintText: 'http://192.168.1.100:5001',
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.customColors.accentLabelColor,
                            ),
                        border: const OutlineInputBorder(),
                        errorText: settings.isUrlValid
                            ? null
                            : 'Invalid URL format',
                        suffixIcon: _connectionStatus != null
                            ? Icon(
                                _connectionTestPassed
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _connectionTestPassed
                                    ? Theme.of(context)
                                              .extension<
                                                AppThemeColorExtension
                                              >()
                                              ?.colorScheme
                                              .semantic
                                              .success ??
                                          Colors.green
                                    : Theme.of(context).colorScheme.error,
                              )
                            : settings.isUrlValid
                            ? Icon(
                                Icons.check_circle,
                                color:
                                    Theme.of(context)
                                        .extension<AppThemeColorExtension>()
                                        ?.colorScheme
                                        .semantic
                                        .connected ??
                                    Colors.green,
                              )
                            : Icon(
                                Icons.error,
                                color: Theme.of(context).colorScheme.error,
                              ),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) {
                        _connectionTestPassed = false;
                        _connectionStatus = null;
                      },
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
                              ? Theme.of(context)
                                        .extension<AppThemeColorExtension>()
                                        ?.colorScheme
                                        .semantic
                                        .success
                                        .withValues(alpha: 0.1) ??
                                    Colors.green.withValues(alpha: 0.1)
                              : Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionStatus!.contains('successful')
                                ? Theme.of(context)
                                          .extension<AppThemeColorExtension>()
                                          ?.colorScheme
                                          .semantic
                                          .success ??
                                      Colors.green
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
                                  ? Theme.of(context)
                                            .extension<AppThemeColorExtension>()
                                            ?.colorScheme
                                            .semantic
                                            .success ??
                                        Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(
                                  color:
                                      _connectionStatus!.contains('successful')
                                      ? Theme.of(context)
                                                .extension<
                                                  AppThemeColorExtension
                                                >()
                                                ?.colorScheme
                                                .semantic
                                                .success ??
                                            Colors.green
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
                      'Reading',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text('Sentence Combining in Sentence Reader '),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Combine sentences with'),
                        const SizedBox(width: 8),
                        Text(
                          '${settings.combineShortSentences ?? 3} terms or less',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: (settings.combineShortSentences ?? 3).toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: (settings.combineShortSentences ?? 3).toString(),
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateCombineShortSentences(value.toInt());
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sentences with this many terms or fewer will be combined to handle fragmentation from PDF/EPUB sources.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Double Tap Timeout'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Timeout duration'),
                        const SizedBox(width: 8),
                        Text(
                          '${settings.doubleTapTimeout}ms',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.doubleTapTimeout.toDouble(),
                      min: 200,
                      max: 400,
                      divisions: 8,
                      label: '${settings.doubleTapTimeout}ms',
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateDoubleTapTimeout(value.toInt());
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The lower the value the faster the tooltip opens and the harder it is to open the Term Form',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔧 Debug: Double Tap Test',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _handleTestDoubleTap,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Double Tap This Area',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _doubleTapDebugInfo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      themeSettings.customAccentLabelColor,
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateAccentLabelColor(color),
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateCustomAccentLabelColor(color),
                    ),
                    _buildAccentColorSetting(
                      context,
                      'Accent Button Color',
                      themeSettings.accentButtonColor,
                      themeSettings.customAccentButtonColor,
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateAccentButtonColor(color),
                      (color) => ref
                          .read(themeSettingsProvider.notifier)
                          .updateCustomAccentButtonColor(color),
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
                    Row(
                      children: [
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ThemeSelectorScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.tune),
                          label: Text(_getThemeLabel(themeSettings.themeType)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getThemeDescription(themeSettings.themeType),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
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
                                    _connectionStatus = null;
                                    _connectionTestPassed = false;
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
    Color? customColor,
    Function(Color) onColorSelected,
    Function(Color) onCustomColorSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._accentColorOptions.map((color) {
              final isSelected = color.toARGB32() == currentColor.toARGB32();
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
            _buildCustomColorOption(
              context,
              customColor ?? const Color(0xFFBDBDBD),
              currentColor,
              customColor,
              onCustomColorSelected,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomColorOption(
    BuildContext context,
    Color color,
    Color currentColor,
    Color? customColor,
    Function(Color) onCustomColorSelected,
  ) {
    final displayColor = customColor ?? const Color(0xFFBDBDBD);
    final isSelected =
        customColor != null &&
        customColor.toARGB32() == currentColor.toARGB32();

    return InkWell(
      onTap: () {
        if (customColor != null) {
          onCustomColorSelected(customColor);
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: displayColor,
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
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.check, color: Colors.white, size: 20),
              ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    _showCustomColorDialog(
                      context,
                      displayColor,
                      onCustomColorSelected,
                    );
                  },
                  child: const Icon(
                    Icons.settings,
                    size: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomColorDialog(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    Color previewColor = currentColor;
    final TextEditingController controller = TextEditingController(
      text:
          '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Custom Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Color Hex Code',
                  hintText: '#RRGGBB',
                  border: OutlineInputBorder(),
                ),
                maxLength: 7,
                onChanged: (value) {
                  final hexCode = value.trim();
                  try {
                    if (hexCode.startsWith('#') && hexCode.length == 7) {
                      final parsedColor = Color(
                        int.parse(hexCode.substring(1), radix: 16) + 0xFF000000,
                      );
                      setState(() {
                        previewColor = parsedColor;
                      });
                    } else if (hexCode.length == 6) {
                      final parsedColor = Color(
                        int.parse(hexCode, radix: 16) + 0xFF000000,
                      );
                      setState(() {
                        previewColor = parsedColor;
                      });
                    }
                  } catch (e) {}
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onColorSelected(previewColor);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
    }
  }

  String _getThemeDescription(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.light:
        return 'Bright, clean interface';
      case ThemeType.dark:
        return 'Dark interface for low light';
    }
  }
}
