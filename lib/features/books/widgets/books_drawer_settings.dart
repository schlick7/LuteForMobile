import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../shared/providers/language_data_provider.dart';

final _userSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getUserSettings();
});

class _MinMaxValueFormatter extends TextInputFormatter {
  final int minValue;
  final int maxValue;

  _MinMaxValueFormatter(this.minValue, this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value < minValue || value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

class BooksDrawerSettings extends ConsumerWidget {
  const BooksDrawerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final languagesState = ref.watch(languageNamesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            context,
            title: 'Display',
            icon: Icons.visibility,
            child: Column(
              children: [
                _buildToggleRow(
                  context,
                  label: 'Show Tags',
                  value: settings.showTags,
                  onChanged: (value) async {
                    ref.read(settingsProvider.notifier).updateShowTags(value);
                    await ref.read(booksProvider.notifier).loadBooks();
                  },
                ),
                const SizedBox(height: 8),
                _buildToggleRow(
                  context,
                  label: 'Show Last Read',
                  value: settings.showLastRead,
                  onChanged: (value) async {
                    ref.read(settingsProvider.notifier).updateShowLastRead(value);
                    await ref.read(booksProvider.notifier).loadBooks();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Filters',
            icon: Icons.filter_list,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Language',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdownContainer(
                  context,
                  child: DropdownButton<String>(
                    value: settings.languageFilter,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Languages'),
                      ),
                      ...languagesState.when(
                        data: (languages) => languages.map(
                          (lang) => DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          ),
                        ),
                        loading: () => [],
                        error: (error, _) => [],
                      ),
                    ],
                    onChanged: (value) async {
                      ref
                          .read(settingsProvider.notifier)
                          .updateLanguageFilter(value);
                      await ref.read(booksProvider.notifier).loadBooks();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Stats',
            icon: Icons.bar_chart,
            child: Consumer(
              builder: (context, ref, child) {
                final asyncValue = ref.watch(_userSettingsProvider);
                return asyncValue.when(
                  data: (settings) {
                    final sampleSize =
                        int.tryParse(
                          settings['stats_calc_sample_size']?.toString() ?? '',
                        ) ??
                        5;
                    return _SampleSizeTextField(
                      initialValue: sampleSize.toString(),
                      settingKey: 'stats_calc_sample_size',
                    );
                  },
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => _SampleSizeTextField(
                    initialValue: '15',
                    settingKey: 'stats_calc_sample_size',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(booksProvider.notifier)
                    .refreshExpiredBooks(forceRefreshAll: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book stats refreshed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh All Stats'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, size: 20),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          initiallyExpanded: true,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: child,
    );
  }
}

class _BatchSizeTextField extends ConsumerStatefulWidget {
  final String initialValue;

  const _BatchSizeTextField({required this.initialValue});

  @override
  ConsumerState<_BatchSizeTextField> createState() =>
      _BatchSizeTextFieldState();
}

class _BatchSizeTextFieldState extends ConsumerState<_BatchSizeTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_BatchSizeTextField oldWidget) {
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
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Books to Process at Once',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MinMaxValueFormatter(1, 5),
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 5) {
          ref
              .read(settingsProvider.notifier)
              .updateStatsRefreshBatchSize(intValue);
        }
      },
    );
  }
}

class _CooldownHoursTextField extends ConsumerStatefulWidget {
  final String initialValue;

  const _CooldownHoursTextField({required this.initialValue});

  @override
  ConsumerState<_CooldownHoursTextField> createState() =>
      _CooldownHoursTextFieldState();
}

class _CooldownHoursTextFieldState
    extends ConsumerState<_CooldownHoursTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_CooldownHoursTextField oldWidget) {
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
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Cooldown Before Refresh (hours)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MinMaxValueFormatter(1, 336),
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 336) {
          ref
              .read(settingsProvider.notifier)
              .updateStatsRefreshCooldownHours(intValue);
        }
      },
    );
  }
}

class _SampleSizeTextField extends ConsumerStatefulWidget {
  final String initialValue;
  final String settingKey;

  const _SampleSizeTextField({
    required this.initialValue,
    required this.settingKey,
  });

  @override
  ConsumerState<_SampleSizeTextField> createState() =>
      _SampleSizeTextFieldState();
}

class _SampleSizeTextFieldState extends ConsumerState<_SampleSizeTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_SampleSizeTextField oldWidget) {
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
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Pages to Refresh',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MinMaxValueFormatter(1, 500),
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 500) {
          // updateStatsCalcSampleSize mirrors the value into the lute
          // DB (which is the source of truth) and into Dart, so no
          // extra setUserSetting call is needed here.
          ref
              .read(settingsProvider.notifier)
              .updateStatsCalcSampleSize(intValue);
        }
      },
    );
  }
}

class _Stats500SampleSizeTextField extends ConsumerStatefulWidget {
  final String initialValue;

  const _Stats500SampleSizeTextField({required this.initialValue});

  @override
  ConsumerState<_Stats500SampleSizeTextField> createState() =>
      _Stats500SampleSizeTextFieldState();
}

class _Stats500SampleSizeTextFieldState
    extends ConsumerState<_Stats500SampleSizeTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_Stats500SampleSizeTextField oldWidget) {
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
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '500 Sample Size',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MinMaxValueFormatter(1, 500),
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 500) {
          ref
              .read(settingsProvider.notifier)
              .updateStats500SampleSize(intValue);
        }
      },
    );
  }
}
