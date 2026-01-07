import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../shared/providers/language_data_provider.dart';

class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
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
          Text(
            'Display Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Show Tags',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: settings.showTags,
                  onChanged: (value) async {
                    ref.read(settingsProvider.notifier).updateShowTags(value);
                    await ref.read(booksProvider.notifier).loadBooks();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Show Last Read',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: settings.showLastRead,
                  onChanged: (value) async {
                    ref
                        .read(settingsProvider.notifier)
                        .updateShowLastRead(value);
                    await ref.read(booksProvider.notifier).loadBooks();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by Language',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<String>(
              value: settings.languageFilter,
              isExpanded: true,
              underline: const SizedBox.shrink(),
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
                ref.read(settingsProvider.notifier).updateLanguageFilter(value);
                await ref.read(booksProvider.notifier).loadBooks();
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Stats Refresh Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: ref.read(contentServiceProvider).getStatsSampleSize(),
            builder: (context, snapshot) {
              final controller = TextEditingController(
                text: snapshot.data?.toString() ?? '15',
              );
              return TextField(
                key: ValueKey('stats_pages_${snapshot.data}'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pages to Refresh',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                controller: controller,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _MaxValueFormatter(500),
                ],
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue > 0 && intValue <= 500) {
                    ref
                        .read(contentServiceProvider)
                        .setUserSetting(
                          'stats_calc_sample_size',
                          intValue.toString(),
                        );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Book Details Refresh Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String?>(
            future: ref
                .read(contentServiceProvider)
                .getUserSetting('details_calc_sample_size_override'),
            builder: (context, snapshot) {
              final controller = TextEditingController(
                text: snapshot.data ?? '500',
              );
              return TextField(
                key: ValueKey('details_pages_${snapshot.data ?? '500'}'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pages to Refresh',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                controller: controller,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _MaxValueFormatter(500),
                ],
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue > 0 && intValue <= 500) {
                    ref
                        .read(contentServiceProvider)
                        .setUserSetting(
                          'details_calc_sample_size_override',
                          intValue.toString(),
                        );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(booksProvider.notifier).refreshAllStats();
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
}
