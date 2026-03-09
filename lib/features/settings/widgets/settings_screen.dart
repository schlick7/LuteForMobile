import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/logger/widget_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/app_bar_leading.dart';
import '../providers/settings_provider.dart';
import '../../books/providers/books_provider.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../models/settings.dart';
import '../../../shared/theme/theme_definitions.dart';
import '../../../app.dart';
import 'theme_selector_screen.dart';
import 'tts_settings_section.dart';
import 'ai_settings_section.dart';
import 'termux_screen.dart';
import 'language_settings_card.dart';

class NumberField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String hint;
  final int minValue;
  final int maxValue;
  final Function(String) onChanged;

  const NumberField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            hintText: widget.hint,
          ),
          controller: _controller,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null &&
                intValue >= widget.minValue &&
                intValue <= widget.maxValue) {
              widget.onChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SettingsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localUrlController = TextEditingController();
  int _buildCount = 0;
  bool _isTesting = false;
  String? _connectionStatus;
  bool _connectionTestPassed = false;
  bool _bookStatsExpanded = false;
  bool _readerExpanded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final savedUrl = prefs.getString('local_url') ?? '';
      if (mounted) {
        _localUrlController.text = savedUrl;
      }
    });
  }

  @override
  void dispose() {
    _localUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _connectionStatus = null;
      _connectionTestPassed = false;
    });

    final url = _localUrlController.text.trim();
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

    final newUrl = _localUrlController.text.trim();

    await _testConnection();

    if (!_connectionTestPassed) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final oldUrl = prefs.getString('local_url') ?? '';

    if (oldUrl != newUrl) {
      await ref.read(settingsProvider.notifier).clearCurrentBook();
      await ref.read(settingsProvider.notifier).updateLocalUrl(newUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }

      RestartWidget.restartApp(context);
    } else {
      await ref.read(settingsProvider.notifier).updateLocalUrl(newUrl);

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

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    WidgetLogger.logRebuild('SettingsScreen', _buildCount);

    final settings = ref.watch(settingsProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final textSettings = ref.watch(textFormattingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AppBarLeading(scaffoldKey: widget.scaffoldKey),
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
                      controller: _localUrlController,
                      decoration: InputDecoration(
                        labelText: 'Local URL',
                        hintText: 'http://192.168.1.100:5001',
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: settings.serverUrl == Settings.termuxUrl
                                  ? context.appColorScheme.text.primary
                                        .withValues(alpha: 0.4)
                                  : context.m3Secondary,
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
                                    ? context.success
                                    : context.error,
                              )
                            : settings.isUrlValid
                            ? Icon(Icons.check_circle, color: context.connected)
                            : Icon(Icons.error, color: context.error),
                      ),
                      style: settings.serverUrl == Settings.termuxUrl
                          ? TextStyle(
                              color: context.appColorScheme.text.primary
                                  .withValues(alpha: 0.5),
                            )
                          : null,
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
                              ? context.success.withValues(alpha: 0.1)
                              : context.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionStatus!.contains('successful')
                                ? context.success
                                : context.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _connectionStatus!.contains('successful')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _connectionStatus!.contains('successful')
                                  ? context.success
                                  : context.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(
                                  color:
                                      _connectionStatus!.contains('successful')
                                      ? context.success
                                      : context.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Termux Integration',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Enable Termux server features',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: settings.termuxIntegrationEnabled,
                              onChanged: (value) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateTermuxIntegrationEnabled(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (settings.termuxIntegrationEnabled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Server Selection',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Use Termux server (localhost)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: settings.serverUrl == Settings.termuxUrl,
                              onChanged: (value) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setServerSelection(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (settings.termuxIntegrationEnabled) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Termux Integration',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermuxScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone_android),
                            label: const Text('Open'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Run Lute3 server locally on your device using Termux',
                        style: TextStyle(
                          color: context.appColorScheme.text.primary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                    if (settings.serverUrl == Settings.termuxUrl)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Using Termux (localhost)',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const LanguageSettingsCard(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ExpansionTile(
                title: const Text(
                  'Reading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: _readerExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _readerExpanded = expanded;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sentence Combining in Sentence Reader '),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Combine sentences with'),
                            const SizedBox(width: 8),
                            Text(
                              '${settings.combineShortSentences ?? 3} terms or less',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: (settings.combineShortSentences ?? 3)
                              .toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: (settings.combineShortSentences ?? 3)
                              .toString(),
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
                            color: context.appColorScheme.text.primary
                                .withValues(alpha: 0.6),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                            color: context.appColorScheme.text.primary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Page Navigation'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Enable swipe navigation'),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: textSettings.swipeNavigationEnabled,
                                onChanged: (value) {
                                  ref
                                      .read(
                                        textFormattingSettingsProvider.notifier,
                                      )
                                      .updateSwipeNavigationEnabled(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Mark pages as read when swiping'),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: textSettings.swipeMarksRead,
                                onChanged: (value) {
                                  ref
                                      .read(
                                        textFormattingSettingsProvider.notifier,
                                      )
                                      .updateSwipeMarksRead(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Page Turn Animations'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Enable page turn animations'),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.pageTurnAnimations,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updatePageTurnAnimations(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Page Preloading'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Enable page preloading',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Preload next page for faster navigation',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.enablePagePreload,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateEnablePagePreload(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Tooltip Caching'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Enable tooltip caching',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Cache tooltips for faster loading (48 hour expiry)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.enableTooltipCaching,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateEnableTooltipCaching(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (settings.enableTooltipCaching) ...[
                          const SizedBox(height: 16),
                          NumberField(
                            label: 'Max Concurrent Tooltip Fetches',
                            initialValue: settings.maxConcurrentTooltipFetches
                                .toString(),
                            hint: '1-10',
                            minValue: 1,
                            maxValue: 10,
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateMaxConcurrentTooltipFetches(
                                      intValue,
                                    );
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text('Show stats bar in reader'),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.showStatsBar,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateShowStatsBar(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Show known terms count',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Display known terms count in stats bar (requires API calls)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.showKnownTermsCount,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateShowKnownTermsCount(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Triple-tap to mark as known',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Quickly mark words as known by tapping three times',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: settings.enableTripleTapToMarkKnown,
                                onChanged: (value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateEnableTripleTapToMarkKnown(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ExpansionTile(
                title: const Text(
                  'Terms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Show Term Stats Card'),
                          value: settings.showTermStatsCard,
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateShowTermStatsCard(value);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TTSSettingsSection(),
            const SizedBox(height: 16),
            const AISettingsSection(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ExpansionTile(
                title: const Text(
                  'Book Stats Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: _bookStatsExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _bookStatsExpanded = expanded;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NumberField(
                          label: 'Calc Sample Size',
                          initialValue: settings.statsCalcSampleSize.toString(),
                          hint: '1-500',
                          minValue: 1,
                          maxValue: 500,
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateStatsCalcSampleSize(intValue);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Auto Refresh Full Stats'),
                          value: settings.autoRefreshFullStats,
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateAutoRefreshFullStats(value);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (settings.autoRefreshFullStats) ...[
                          const SizedBox(height: 8),
                          NumberField(
                            label: 'Books to Process at Once',
                            initialValue: settings.statsRefreshBatchSize
                                .toString(),
                            hint: '1-5',
                            minValue: 1,
                            maxValue: 5,
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateStatsRefreshBatchSize(intValue);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          NumberField(
                            label: 'Cooldown Before Refresh (hours)',
                            initialValue: settings.statsRefreshCooldownHours
                                .toString(),
                            hint: '1-336 (14 days)',
                            minValue: 1,
                            maxValue: 336,
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateStatsRefreshCooldownHours(intValue);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          NumberField(
                            label: 'Full Refresh Sample Size',
                            initialValue: settings.stats500SampleSize
                                .toString(),
                            hint: '1-500',
                            minValue: 1,
                            maxValue: 500,
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateStats500SampleSize(intValue);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
                          label: Text(_getThemeLabel(themeSettings)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getThemeDescription(themeSettings),
                      style: TextStyle(
                        color: context.appColorScheme.text.primary.withValues(
                          alpha: 0.6,
                        ),
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
                        color: context.appColorScheme.text.primary.withValues(
                          alpha: 0.6,
                        ),
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
                                    _localUrlController.text = ref
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
                          foregroundColor: context.error,
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
                color: context.appColorScheme.text.primary.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeSettings themeSettings) {
    if (themeSettings.selectedUserTheme != null) {
      return themeSettings.selectedUserTheme!.name;
    }
    final themeType = themeSettings.themeType;
    switch (themeType) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.blackAndWhite:
        return 'Black and White device';
    }
  }

  String _getThemeDescription(ThemeSettings themeSettings) {
    if (themeSettings.selectedUserTheme != null) {
      return 'Custom theme';
    }
    final themeType = themeSettings.themeType;
    switch (themeType) {
      case ThemeType.light:
        return 'Bright, clean interface';
      case ThemeType.dark:
        return 'Dark interface for low light';
      case ThemeType.blackAndWhite:
        return 'Optimized for black and white screens';
    }
  }
}
