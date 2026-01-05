import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import '../providers/sentence_reader_provider.dart';
import '../providers/reader_provider.dart';
import '../../../../app.dart';

class ReaderDrawerSettings extends ConsumerWidget {
  final int currentIndex;

  const ReaderDrawerSettings({super.key, required this.currentIndex});

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
    final settings = ref.watch(settingsProvider);
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
          const SizedBox(height: 16),
          _buildFullscreenToggle(context, ref, textSettings),
          const SizedBox(height: 32),
          Consumer(
            builder: (context, ref, _) {
              final reader = ref.watch(readerProvider);
              if (reader.pageData?.hasAudio == true) {
                return Column(
                  children: [
                    Text(
                      'Audio Player',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildAudioPlayerToggle(context, ref, settings),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final error = ref.watch(sentenceReaderProvider).errorMessage;

              if (error != null) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sentence Reader Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  ref
                                      .read(sentenceReaderProvider.notifier)
                                      .clearError();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final reader = ref.read(readerProvider);
                                    if (reader.pageData != null) {
                                      await ref
                                          .read(sentenceReaderProvider.notifier)
                                          .parseSentencesForPage(
                                            _getLangId(reader),
                                            initialIndex: 0,
                                          );
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(sentenceReaderProvider.notifier)
                            .triggerFlushAndRebuild();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache flushed and rebuilt!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.view_headline),
                      label: const Text('Flush Cache & Rebuild'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Show Known Terms',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: settings.showKnownTermsInSentenceReader,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateShowKnownTermsInSentenceReader(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (currentIndex == 3) {
                        await ref
                            .read(sentenceReaderProvider.notifier)
                            .triggerFlushAndRebuild();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache flushed and rebuilt!'),
                            ),
                          );
                        }
                      } else {
                        ref.read(navigationProvider).navigateToScreen(0);
                        Future.microtask(
                          () =>
                              ref.read(navigationProvider).navigateToScreen(3),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.view_headline),
                    label: currentIndex == 3
                        ? const Text('Flush Cache & Rebuild')
                        : const Text('Open Sentence Reader'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (currentIndex == 3)
                    Row(
                      children: [
                        const Text(
                          'Show Known Terms',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: settings.showKnownTermsInSentenceReader,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateShowKnownTermsInSentenceReader(value);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
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
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: textSettings.isItalic,
            onChanged: (value) {
              ref
                  .read(textFormattingSettingsProvider.notifier)
                  .updateIsItalic(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenToggle(
    BuildContext context,
    WidgetRef ref,
    dynamic textSettings,
  ) {
    return Row(
      children: [
        const Text(
          'Fullscreen Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: textSettings.fullscreenMode,
            onChanged: (value) {
              ref
                  .read(textFormattingSettingsProvider.notifier)
                  .updateFullscreenMode(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayerToggle(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
  ) {
    return Row(
      children: [
        const Text(
          'Show Audio Player',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: settings.showAudioPlayer,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowAudioPlayer(value);
            },
          ),
        ),
      ],
    );
  }

  int _getLangId(ReaderState reader) {
    if (reader.pageData?.paragraphs.isNotEmpty == true &&
        reader.pageData!.paragraphs[0].textItems.isNotEmpty) {
      return reader.pageData!.paragraphs[0].textItems.first.langId ?? 0;
    }
    return 0;
  }
}
