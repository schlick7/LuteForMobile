import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

class AppDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final bool isSettingsView;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.isSettingsView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: isSettingsView ? 80 : 320,
      child: Drawer(
        child: Row(
          children: [
            _buildNavigationColumn(context),
            if (!isSettingsView) _buildSettingsColumn(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationColumn(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNavItem(context, Icons.book, 0, 'Reader'),
          _buildNavItem(context, Icons.settings, 1, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon),
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            onPressed: () {
              onNavigate(index);
              Navigator.of(context).pop();
            },
            tooltip: label,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsColumn(BuildContext context, WidgetRef ref) {
    final textSettings = ref.watch(textFormattingSettingsProvider);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Text Formatting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTextSizeSlider(context, ref, textSettings),
            const SizedBox(height: 16),
            _buildLineSpacingSlider(context, ref, textSettings),
            const SizedBox(height: 16),
            _buildFontDropdown(context, ref, textSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeSlider(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Size: ${textSettings.textSize.toInt()}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: textSettings.textSize,
          min: 12,
          max: 30,
          divisions: 18,
          onChanged: (value) {
            ref
                .read(textFormattingSettingsProvider.notifier)
                .updateTextSize(value);
          },
        ),
      ],
    );
  }

  Widget _buildLineSpacingSlider(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Spacing: ${textSettings.lineSpacing.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: textSettings.lineSpacing,
          min: 0.6,
          max: 2.0,
          divisions: 14,
          onChanged: (value) {
            ref
                .read(textFormattingSettingsProvider.notifier)
                .updateLineSpacing(value);
          },
        ),
      ],
    );
  }

  Widget _buildFontDropdown(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
  ) {
    final List<String> fonts = [
      'Roboto',
      'AtkinsonHyperlegibleNext',
      'Vollkorn',
      'LinBiolinum',
      'Literata',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: textSettings.fontFamily,
          isExpanded: true,
          items: fonts.map((String font) {
            return DropdownMenuItem<String>(value: font, child: Text(font));
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              ref
                  .read(textFormattingSettingsProvider.notifier)
                  .updateFontFamily(newValue);
            }
          },
        ),
      ],
    );
  }
}
