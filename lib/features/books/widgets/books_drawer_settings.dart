import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';

class BooksDrawerSettings extends ConsumerWidget {
  const BooksDrawerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final languagesState = ref.watch(languagesProvider);

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
          SwitchListTile(
            title: const Text('Show Tags'),
            value: settings.showTags,
            onChanged: (value) async {
              ref.read(settingsProvider.notifier).updateShowTags(value);
              await ref.read(booksProvider.notifier).loadBooks();
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          SwitchListTile(
            title: const Text('Show Last Read'),
            value: settings.showLastRead,
            onChanged: (value) async {
              ref.read(settingsProvider.notifier).updateShowLastRead(value);
              await ref.read(booksProvider.notifier).loadBooks();
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
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
