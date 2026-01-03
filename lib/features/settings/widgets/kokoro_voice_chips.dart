import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';

class KokoroVoiceChips extends ConsumerWidget {
  const KokoroVoiceChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref
        .watch(ttsSettingsProvider)
        .providerConfigs[TTSProvider.kokoroTTS];
    final voices = config?.kokoroVoices ?? [];

    if (voices.isEmpty) {
      return const Text(
        'No voices selected',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (int i = 0; i < voices.length; i++) ...[
          if (i > 0)
            const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
          _VoiceChip(
            voice: voices[i],
            canAddVoice: voices.length < 2,
            onEditWeight: () => _showWeightDialog(context, ref, voices[i]),
            onRemove: () => ref
                .read(ttsSettingsProvider.notifier)
                .removeKokoroVoice(voices[i].voice),
          ),
        ],
      ],
    );
  }

  void _showWeightDialog(
    BuildContext context,
    WidgetRef ref,
    KokoroVoiceWeight voice,
  ) {
    final controller = TextEditingController(text: voice.weight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Weight for ${voice.voice}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight',
            hintText: '1-10',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = int.tryParse(controller.text);
              if (weight != null && weight > 0) {
                ref
                    .read(ttsSettingsProvider.notifier)
                    .updateKokoroVoiceWeight(voice.voice, weight);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final KokoroVoiceWeight voice;
  final bool canAddVoice;
  final VoidCallback onEditWeight;
  final VoidCallback onRemove;

  const _VoiceChip({
    required this.voice,
    required this.canAddVoice,
    required this.onEditWeight,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onEditWeight,
      child: Chip(
        label: Text(
          voice.weight > 1 ? '${voice.voice}(${voice.weight})' : voice.voice,
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onRemove,
        avatar: const Icon(Icons.record_voice_over, size: 20),
      ),
    );
  }
}
