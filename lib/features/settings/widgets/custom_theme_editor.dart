import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../../../shared/theme/theme_definitions.dart';
import '../../../shared/theme/theme_extensions.dart';

class CustomThemeEditor extends ConsumerStatefulWidget {
  final String themeId;

  const CustomThemeEditor({super.key, required this.themeId});

  @override
  ConsumerState<CustomThemeEditor> createState() => _CustomThemeEditorState();
}

class _CustomThemeEditorState extends ConsumerState<CustomThemeEditor> {
  AppThemeColorScheme? _workingScheme;
  Map<int, StatusMode>? _workingModes;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _onColorForPreview(Color background) {
    return background.computeLuminance() > 0.5
        ? const Color(0xFF1C1B1F)
        : const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeSettingsProvider);
    UserThemeDefinition? theme;
    for (final item in settings.userThemes) {
      if (item.id == widget.themeId) {
        theme = item;
        break;
      }
    }

    if (theme == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theme Editor')),
        body: const Center(child: Text('Theme not found.')),
      );
    }
    final currentTheme = theme;

    _workingScheme ??= currentTheme.colorScheme;
    _workingModes ??= Map<int, StatusMode>.from(currentTheme.statusModes);
    if (_nameController.text.isEmpty) {
      _nameController.text = currentTheme.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Editor'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _workingScheme = currentTheme.colorScheme;
                _workingModes = Map<int, StatusMode>.from(
                  currentTheme.statusModes,
                );
                _nameController.text = currentTheme.name;
              });
            },
            child: const Text('Revert'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(themeSettingsProvider.notifier);
              final name = _nameController.text.trim();
              if (name.isNotEmpty && name != currentTheme.name) {
                await notifier.renameTheme(currentTheme.id, name);
              }
              await notifier.updateThemeScheme(
                currentTheme.id,
                _workingScheme!,
              );
              for (final entry in _workingModes!.entries) {
                await notifier.updateThemeStatusMode(
                  currentTheme.id,
                  entry.key,
                  entry.value,
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Theme saved')));
              }
            },
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Theme name'),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(context, 'Status Colors', [
            _statusRow(0, _workingScheme!.status.status0, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status0: c)),
              );
            }),
            _statusRow(1, _workingScheme!.status.status1, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status1: c)),
              );
            }),
            _statusRow(2, _workingScheme!.status.status2, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status2: c)),
              );
            }),
            _statusRow(3, _workingScheme!.status.status3, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status3: c)),
              );
            }),
            _statusRow(4, _workingScheme!.status.status4, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status4: c)),
              );
            }),
            _statusRow(5, _workingScheme!.status.status5, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status5: c)),
              );
            }),
            _statusRow(98, _workingScheme!.status.status98, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status98: c)),
              );
            }),
            _statusRow(99, _workingScheme!.status.status99, (c) {
              _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(status99: c)),
              );
            }),
            _colorRow(
              context,
              label: 'Status Highlighted Text',
              color: _workingScheme!.status.highlightedText,
              description: 'Text color on status highlights',
              preview: _chipPreview(
                bg: _workingScheme!.status.status3,
                fg: _workingScheme!.status.highlightedText,
                text: 'Highlighted',
              ),
              onChanged: (c) => _updateScheme(
                (s) =>
                    s.copyWith(status: s.status.copyWith(highlightedText: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Word Glow',
              color: _workingScheme!.status.wordGlowColor,
              description: 'Glow color for focused words',
              preview: Text(
                'Glow',
                style: TextStyle(
                  color: _workingScheme!.status.wordGlowColor,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: _workingScheme!.status.wordGlowColor,
                    ),
                  ],
                ),
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(status: s.status.copyWith(wordGlowColor: c)),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Text Colors', [
            _colorRow(
              context,
              label: 'Primary',
              color: _workingScheme!.text.primary,
              description: 'Main body text',
              preview: Text(
                'Aa Primary text',
                style: TextStyle(color: _workingScheme!.text.primary),
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(primary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Secondary',
              color: _workingScheme!.text.secondary,
              description: 'Secondary/metadata text',
              preview: Text(
                'Aa Secondary',
                style: TextStyle(color: _workingScheme!.text.secondary),
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(secondary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Disabled',
              color: _workingScheme!.text.disabled,
              description: 'Disabled controls',
              preview: Text(
                'Disabled',
                style: TextStyle(color: _workingScheme!.text.disabled),
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(disabled: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Headline',
              color: _workingScheme!.text.headline,
              description: 'Headings',
              preview: Text(
                'Headline',
                style: TextStyle(
                  color: _workingScheme!.text.headline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(headline: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Primary',
              color: _workingScheme!.text.onPrimary,
              description: 'Text on primary surfaces',
              preview: _chipPreview(
                bg: _workingScheme!.material3.primary,
                fg: _workingScheme!.text.onPrimary,
                text: 'Primary',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(onPrimary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Secondary',
              color: _workingScheme!.text.onSecondary,
              description: 'Text on secondary surfaces',
              preview: _chipPreview(
                bg: _workingScheme!.material3.secondary,
                fg: _workingScheme!.text.onSecondary,
                text: 'Secondary',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(onSecondary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Primary Container',
              color: _workingScheme!.text.onPrimaryContainer,
              description: 'Text on primary containers',
              preview: _chipPreview(
                bg: _workingScheme!.material3.primaryContainer,
                fg: _workingScheme!.text.onPrimaryContainer,
                text: 'Container',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(onPrimaryContainer: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Secondary Container',
              color: _workingScheme!.text.onSecondaryContainer,
              description: 'Text on secondary containers',
              preview: _chipPreview(
                bg: _workingScheme!.material3.secondaryContainer,
                fg: _workingScheme!.text.onSecondaryContainer,
                text: 'Container',
              ),
              onChanged: (c) => _updateScheme(
                (s) =>
                    s.copyWith(text: s.text.copyWith(onSecondaryContainer: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Tertiary',
              color: _workingScheme!.text.onTertiary,
              description: 'Text on tertiary surfaces',
              preview: _chipPreview(
                bg: _workingScheme!.material3.tertiary,
                fg: _workingScheme!.text.onTertiary,
                text: 'Tertiary',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(text: s.text.copyWith(onTertiary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Tertiary Container',
              color: _workingScheme!.text.onTertiaryContainer,
              description: 'Text on tertiary containers',
              preview: _chipPreview(
                bg: _workingScheme!.material3.tertiaryContainer,
                fg: _workingScheme!.text.onTertiaryContainer,
                text: 'Container',
              ),
              onChanged: (c) => _updateScheme(
                (s) =>
                    s.copyWith(text: s.text.copyWith(onTertiaryContainer: c)),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Background Colors', [
            _colorRow(
              context,
              label: 'Background',
              color: _workingScheme!.background.background,
              description: 'Main screen background',
              preview: _boxPreview(_workingScheme!.background.background),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  background: s.background.copyWith(background: c),
                ),
              ),
            ),
            _colorRow(
              context,
              label: 'Surface',
              color: _workingScheme!.background.surface,
              description: 'Cards and panels',
              preview: _boxPreview(_workingScheme!.background.surface),
              onChanged: (c) => _updateScheme(
                (s) =>
                    s.copyWith(background: s.background.copyWith(surface: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Surface Variant',
              color: _workingScheme!.background.surfaceVariant,
              description: 'Alternative surface backgrounds',
              preview: _boxPreview(_workingScheme!.background.surfaceVariant),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  background: s.background.copyWith(surfaceVariant: c),
                ),
              ),
            ),
            _colorRow(
              context,
              label: 'Surface Container Highest',
              color: _workingScheme!.background.surfaceContainerHighest,
              description: 'Headers and emphasized containers',
              preview: _boxPreview(
                _workingScheme!.background.surfaceContainerHighest,
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  background: s.background.copyWith(surfaceContainerHighest: c),
                ),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Material 3 Colors', [
            _colorRow(
              context,
              label: 'Primary',
              color: _workingScheme!.material3.primary,
              description: 'Primary brand color',
              preview: _chipPreview(
                bg: _workingScheme!.material3.primary,
                fg: _workingScheme!.text.onPrimary,
                text: 'Primary',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(material3: s.material3.copyWith(primary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Secondary',
              color: _workingScheme!.material3.secondary,
              description: 'Secondary brand color',
              preview: _chipPreview(
                bg: _workingScheme!.material3.secondary,
                fg: _workingScheme!.text.onSecondary,
                text: 'Secondary',
              ),
              onChanged: (c) => _updateScheme(
                (s) =>
                    s.copyWith(material3: s.material3.copyWith(secondary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Tertiary',
              color: _workingScheme!.material3.tertiary,
              description: 'Tertiary accent color',
              preview: _chipPreview(
                bg: _workingScheme!.material3.tertiary,
                fg: _workingScheme!.text.onTertiary,
                text: 'Tertiary',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(material3: s.material3.copyWith(tertiary: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Primary Container',
              color: _workingScheme!.material3.primaryContainer,
              description: 'Container for primary content',
              preview: _boxPreview(_workingScheme!.material3.primaryContainer),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  material3: s.material3.copyWith(primaryContainer: c),
                ),
              ),
            ),
            _colorRow(
              context,
              label: 'Secondary Container',
              color: _workingScheme!.material3.secondaryContainer,
              description: 'Container for secondary content',
              preview: _boxPreview(
                _workingScheme!.material3.secondaryContainer,
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  material3: s.material3.copyWith(secondaryContainer: c),
                ),
              ),
            ),
            _colorRow(
              context,
              label: 'Tertiary Container',
              color: _workingScheme!.material3.tertiaryContainer,
              description: 'Container for tertiary content',
              preview: _boxPreview(_workingScheme!.material3.tertiaryContainer),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(
                  material3: s.material3.copyWith(tertiaryContainer: c),
                ),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Semantic Colors', [
            _semanticRow('Success', _workingScheme!.semantic.success, (c) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(success: c)),
              );
            }),
            _semanticRow('Warning', _workingScheme!.semantic.warning, (c) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(warning: c)),
              );
            }),
            _semanticRow('Error', _workingScheme!.semantic.error, (c) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(error: c)),
              );
            }),
            _semanticRow('Info', _workingScheme!.semantic.info, (c) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(info: c)),
              );
            }),
            _semanticRow('Connected', _workingScheme!.semantic.connected, (c) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(connected: c)),
              );
            }),
            _semanticRow(
              'Disconnected',
              _workingScheme!.semantic.disconnected,
              (c) {
                _updateScheme(
                  (s) => s.copyWith(
                    semantic: s.semantic.copyWith(disconnected: c),
                  ),
                );
              },
            ),
            _semanticRow('AI Provider', _workingScheme!.semantic.aiProvider, (
              c,
            ) {
              _updateScheme(
                (s) => s.copyWith(semantic: s.semantic.copyWith(aiProvider: c)),
              );
            }),
            _semanticRow(
              'Local Provider',
              _workingScheme!.semantic.localProvider,
              (c) {
                _updateScheme(
                  (s) => s.copyWith(
                    semantic: s.semantic.copyWith(localProvider: c),
                  ),
                );
              },
            ),
          ]),
          _buildSectionCard(context, 'Border Colors', [
            _colorRow(
              context,
              label: 'Outline',
              color: _workingScheme!.border.outline,
              description: 'Main border color',
              preview: _borderPreview(_workingScheme!.border.outline),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(border: s.border.copyWith(outline: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Outline Variant',
              color: _workingScheme!.border.outlineVariant,
              description: 'Subtle border color',
              preview: _borderPreview(_workingScheme!.border.outlineVariant),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(border: s.border.copyWith(outlineVariant: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Divider',
              color: _workingScheme!.border.dividerColor,
              description: 'Divider lines',
              preview: Divider(color: _workingScheme!.border.dividerColor),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(border: s.border.copyWith(dividerColor: c)),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Audio Colors', [
            _colorRow(
              context,
              label: 'Audio Background',
              color: _workingScheme!.audio.background,
              description: 'Player background',
              preview: _chipPreview(
                bg: _workingScheme!.audio.background,
                fg: _workingScheme!.audio.icon,
                text: 'Play',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(audio: s.audio.copyWith(background: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Audio Icon',
              color: _workingScheme!.audio.icon,
              description: 'Player icons and text',
              preview: Icon(
                Icons.play_arrow,
                color: _workingScheme!.audio.icon,
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(audio: s.audio.copyWith(icon: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Audio Bookmark',
              color: _workingScheme!.audio.bookmark,
              description: 'Bookmark indicators',
              preview: Icon(
                Icons.bookmark,
                color: _workingScheme!.audio.bookmark,
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(audio: s.audio.copyWith(bookmark: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Audio Error',
              color: _workingScheme!.audio.error,
              description: 'Audio error text/icons',
              preview: Icon(Icons.error, color: _workingScheme!.audio.error),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(audio: s.audio.copyWith(error: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'Audio Error Background',
              color: _workingScheme!.audio.errorBackground,
              description: 'Audio error panel background',
              preview: _boxPreview(_workingScheme!.audio.errorBackground),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(audio: s.audio.copyWith(errorBackground: c)),
              ),
            ),
          ]),
          _buildSectionCard(context, 'Error Palette', [
            _colorRow(
              context,
              label: 'Error',
              color: _workingScheme!.error.error,
              description: 'Material error color',
              preview: _chipPreview(
                bg: _workingScheme!.error.error,
                fg: _workingScheme!.error.onError,
                text: 'Error',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(error: s.error.copyWith(error: c)),
              ),
            ),
            _colorRow(
              context,
              label: 'On Error',
              color: _workingScheme!.error.onError,
              description: 'Text on error surfaces',
              preview: _chipPreview(
                bg: _workingScheme!.error.error,
                fg: _workingScheme!.error.onError,
                text: 'On Error',
              ),
              onChanged: (c) => _updateScheme(
                (s) => s.copyWith(error: s.error.copyWith(onError: c)),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    List<Widget> rows,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _semanticRow(
    String label,
    Color color,
    ValueChanged<Color> onChanged,
  ) {
    return _colorRow(
      context,
      label: label,
      color: color,
      description: '$label semantic color',
      preview: _chipPreview(
        bg: color,
        fg: _onColorForPreview(color),
        text: label,
      ),
      onChanged: onChanged,
    );
  }

  Widget _statusRow(int status, Color color, ValueChanged<Color> onChanged) {
    final statusLabel = _statusLabel(status);
    final mode = _workingModes![status] ?? StatusMode.background;
    final modeDescription = switch (mode) {
      StatusMode.background => 'Used as highlight background',
      StatusMode.text => 'Used as text color',
      StatusMode.none => 'No status styling in reader',
    };
    final preview = switch (mode) {
      StatusMode.background => _chipPreview(
        bg: color,
        fg: _workingScheme!.status.highlightedText,
        text: statusLabel,
      ),
      StatusMode.text => Text(statusLabel, style: TextStyle(color: color)),
      StatusMode.none => Text(
        statusLabel,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.appColorScheme.border.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _colorRow(
            context,
            label: statusLabel,
            color: color,
            description: modeDescription,
            preview: preview,
            onChanged: onChanged,
            withBorder: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatusModeChip(
                      label: 'Background',
                      selected: mode == StatusMode.background,
                      onTap: () {
                        setState(() {
                          _workingModes![status] = StatusMode.background;
                        });
                      },
                    ),
                    _buildStatusModeChip(
                      label: 'Text',
                      selected: mode == StatusMode.text,
                      onTap: () {
                        setState(() {
                          _workingModes![status] = StatusMode.text;
                        });
                      },
                    ),
                    _buildStatusModeChip(
                      label: 'None',
                      selected: mode == StatusMode.none,
                      onTap: () {
                        setState(() {
                          _workingModes![status] = StatusMode.none;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0:
        return 'unknown (0)';
      case 98:
        return 'ignored (98)';
      case 99:
        return 'known (99)';
      default:
        return 'Status $status';
    }
  }

  Widget _buildStatusModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _colorRow(
    BuildContext context, {
    required String label,
    required String description,
    required Color color,
    required Widget preview,
    required ValueChanged<Color> onChanged,
    bool withBorder = true,
  }) {
    final content = Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: context.appColorScheme.border.outline.withValues(
                  alpha: 0.35,
                ),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                Text(_hex(color), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(flex: 2, child: Center(child: preview)),
          IconButton(
            tooltip: 'Pick color',
            onPressed: () => _showColorPickerDialog(context, color, onChanged),
            icon: const Icon(Icons.palette),
          ),
        ],
      );

    if (!withBorder) {
      return content;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.appColorScheme.border.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }

  Future<void> _showColorPickerDialog(
    BuildContext context,
    Color current,
    ValueChanged<Color> onChanged,
  ) async {
    Color previewColor = current;
    HSVColor hsv = HSVColor.fromColor(current.withValues(alpha: 1.0));
    double alpha = current.a;
    final controller = TextEditingController(text: _hex(current));
    // Intentional fixed palette for quick-pick colors in the editor UI.
    final presetColors = <Color>[
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.brown,
      Colors.grey,
      const Color(0xFF6750A4),
      const Color(0xFF1976D2),
    ];

    void updateFromHsvAndAlpha(StateSetter setState) {
      setState(() {
        previewColor = hsv.toColor().withValues(alpha: alpha);
        controller.text = _hex(previewColor);
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pick Color'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SaturationValuePicker(
                      hue: hsv.hue,
                      saturation: hsv.saturation,
                      value: hsv.value,
                      onChanged: (saturation, value) {
                        hsv = hsv.withSaturation(saturation).withValue(value);
                        updateFromHsvAndAlpha(setState);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Hue', style: Theme.of(context).textTheme.bodySmall),
                    Slider(
                      value: hsv.hue,
                      min: 0,
                      max: 360,
                      onChanged: (value) {
                        hsv = hsv.withHue(value);
                        updateFromHsvAndAlpha(setState);
                      },
                    ),
                    Text(
                      'Opacity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: alpha,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        alpha = value;
                        updateFromHsvAndAlpha(setState);
                      },
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetColors.map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              previewColor = color.withValues(alpha: alpha);
                              hsv = HSVColor.fromColor(
                                color.withValues(alpha: 1.0),
                              );
                              controller.text = _hex(previewColor);
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: previewColor == color
                                    ? context.appColorScheme.material3.primary
                                    : context.appColorScheme.border.outline
                                          .withValues(alpha: 0.35),
                                width: previewColor == color ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Hex',
                        hintText: '#AARRGGBB',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final parsed = _parseColor(value);
                        if (parsed != null) {
                          setState(() {
                            previewColor = parsed;
                            alpha = parsed.a;
                            hsv = HSVColor.fromColor(
                              parsed.withValues(alpha: 1.0),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.appColorScheme.border.outline
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(previewColor);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chipPreview({
    required Color bg,
    required Color fg,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11)),
    );
  }

  Widget _boxPreview(Color color) {
    return Container(
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.appColorScheme.border.outline.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _borderPreview(Color borderColor) {
    return Container(
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  void _updateScheme(
    AppThemeColorScheme Function(AppThemeColorScheme) updater,
  ) {
    setState(() {
      _workingScheme = updater(_workingScheme!);
    });
  }

  String _hex(Color color) {
    return '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  Color? _parseColor(String raw) {
    final value = raw.trim();
    final sanitized = value.startsWith('#') ? value.substring(1) : value;
    if (sanitized.length != 6 && sanitized.length != 8) return null;
    final parsed = int.tryParse(sanitized, radix: 16);
    if (parsed == null) return null;
    if (sanitized.length == 8) return Color(parsed);
    return Color(0xFF000000 | parsed);
  }
}

class _SaturationValuePicker extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValuePicker({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanDown: (details) => _handleGesture(details.localPosition, size),
        onPanUpdate: (details) => _handleGesture(details.localPosition, size),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.35),
                ),
                color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.transparent],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
            Positioned(
              left: saturation * size - 8,
              top: (1 - value) * size - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 2,
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

  void _handleGesture(Offset position, double size) {
    final clampedX = position.dx.clamp(0.0, size);
    final clampedY = position.dy.clamp(0.0, size);
    final nextSaturation = clampedX / size;
    final nextValue = 1 - (clampedY / size);
    onChanged(nextSaturation, nextValue);
  }
}
