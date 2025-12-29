import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

class ReaderDrawerSettings extends ConsumerWidget {
  const ReaderDrawerSettings({super.key});

  final List<FontWeight> _availableWeights = const [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.normal,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.bold,
    FontWeight.w800,
  ];

  final List<String> _weightLabels = const [
    'Extra Light',
    'Light',
    'Regular',
    'Medium',
    'Semi Bold',
    'Bold',
    'Extra Bold',
  ];

  FontWeight _getWeightFromIndex(double index) {
    final idx = index.round().clamp(0, _availableWeights.length - 1);
    return _availableWeights[idx];
  }

  String _getWeightLabel(double index) {
    final idx = index.round().clamp(0, _weightLabels.length - 1);
    return _weightLabels[idx];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSettings = ref.watch(textFormattingSettingsProvider);
    final weightIndex = _availableWeights
        .indexOf(textSettings.fontWeight)
        .toDouble();

    return Container(
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
          const SizedBox(height: 16),
          _buildFontWeightSlider(context, ref, textSettings, weightIndex),
          const SizedBox(height: 16),
          _buildItalicToggle(context, ref, textSettings),
        ],
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

  Widget _buildFontWeightSlider(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
    double weightIndex,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight: ${_getWeightLabel(weightIndex)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: weightIndex,
          min: 0,
          max: _availableWeights.length - 1,
          divisions: _availableWeights.length - 1,
          label: _getWeightLabel(weightIndex),
          onChanged: (value) {
            ref
                .read(textFormattingSettingsProvider.notifier)
                .updateFontWeight(_getWeightFromIndex(value));
          },
        ),
      ],
    );
  }

  Widget _buildItalicToggle(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
  ) {
    return Row(
      children: [
        const Text('Italic', style: TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Switch(
          value: textSettings.isItalic,
          onChanged: (value) {
            ref
                .read(textFormattingSettingsProvider.notifier)
                .updateIsItalic(value);
          },
        ),
      ],
    );
  }
}
