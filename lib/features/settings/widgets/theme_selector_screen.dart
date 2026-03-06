import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/widget_logger.dart';
import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../../../shared/theme/theme_definitions.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'custom_theme_editor.dart';
import 'new_theme_dialog.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  static int _buildCount = 0;

  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _buildCount++;
    WidgetLogger.logRebuild('ThemeSelectorScreen', _buildCount);

    final themeSettings = ref.watch(themeSettingsProvider);
    final currentThemeType = themeSettings.themeType;
    final selectedThemeId = themeSettings.selectedThemeId;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Built-in Themes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const NewThemeDialog(),
                  );
                  if (result == null || !context.mounted) return;
                  final name = result['name'] as String? ?? 'Custom Theme';
                  final mode =
                      result['mode'] as ThemeInitMode? ??
                      ThemeInitMode.fromCurrent;
                  final id = await ref
                      .read(themeSettingsProvider.notifier)
                      .createTheme(name: name, mode: mode);
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomThemeEditor(themeId: id),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Theme'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ThemeType.values.map(
            (themeType) => _buildThemeCard(
              context,
              ref,
              themeType,
              currentThemeType,
              selectedThemeId == null,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'My Themes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (themeSettings.userThemes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No custom themes yet. Tap New Theme to create one.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            ...themeSettings.userThemes.map((theme) {
              final isSelected = theme.id == selectedThemeId;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(theme.name),
                  subtitle: Text(
                    'Updated ${theme.updatedAt.toLocal()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.material3.primary,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomThemeEditor(themeId: theme.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'select') {
                            await ref
                                .read(themeSettingsProvider.notifier)
                                .selectUserTheme(theme.id);
                            return;
                          }
                          if (value == 'duplicate') {
                            await ref
                                .read(themeSettingsProvider.notifier)
                                .duplicateTheme(theme.id);
                            return;
                          }
                          if (value == 'rename') {
                            final name = await _showRenameDialog(
                              context,
                              currentName: theme.name,
                            );
                            if (name != null && name.trim().isNotEmpty) {
                              await ref
                                  .read(themeSettingsProvider.notifier)
                                  .renameTheme(theme.id, name.trim());
                            }
                            return;
                          }
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Theme'),
                                content: Text(
                                  'Delete "${theme.name}"? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(themeSettingsProvider.notifier)
                                  .deleteTheme(theme.id);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'select', child: Text('Select')),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => ref
                      .read(themeSettingsProvider.notifier)
                      .selectUserTheme(theme.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeType themeType,
    ThemeType currentThemeType,
    bool usingBuiltInTheme,
  ) {
    final isSelected = usingBuiltInTheme && themeType == currentThemeType;
    final themeData = switch (themeType) {
      ThemeType.light => AppTheme.lightTheme(ref.watch(themeSettingsProvider)),
      ThemeType.dark => AppTheme.darkTheme(ref.watch(themeSettingsProvider)),
      ThemeType.blackAndWhite => AppTheme.blackAndWhiteTheme(
        ref.watch(themeSettingsProvider),
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () {
          ref
              .read(themeSettingsProvider.notifier)
              .selectBuiltInTheme(themeType);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.appColorScheme.material3.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      themeData.colorScheme.primary,
                      themeData.colorScheme.secondary,
                      themeData.scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getThemeLabel(themeType),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.appColorScheme.text.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getThemeDescription(themeType),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.appColorScheme.text.primary.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? context.appColorScheme.material3.primary
                    : context.appColorScheme.text.primary.withValues(
                        alpha: 0.5,
                      ),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context, {
    required String currentName,
  }) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Theme'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Theme name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.blackAndWhite:
        return 'Black and White device';
    }
  }

  String _getThemeDescription(ThemeType themeType) {
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
