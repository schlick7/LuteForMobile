import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/network/tts_service.dart';
import 'package:lute_for_mobile/core/providers/tts_provider.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';

class KokoroVoiceChips extends ConsumerStatefulWidget {
  const KokoroVoiceChips({super.key});

  @override
  ConsumerState<KokoroVoiceChips> createState() => _KokoroVoiceChipsState();
}

class _KokoroVoiceChipsState extends ConsumerState<KokoroVoiceChips> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final config = ref
        .watch(ttsSettingsProvider)
        .providerConfigs[TTSProvider.kokoroTTS];
    final voices = config?.kokoroVoices ?? [];
    final canAddVoice = voices.length < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (voices.isEmpty)
          const Text('No voices selected', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (int i = 0; i < voices.length; i++) ...[
                if (i > 0)
                  const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                _VoiceChip(
                  voice: voices[i],
                  canAddVoice: canAddVoice,
                  onEditWeight: () =>
                      _showWeightDialog(context, ref, voices[i]),
                  onRemove: () {
                    ref
                        .read(ttsSettingsProvider.notifier)
                        .removeKokoroVoice(voices[i].voice);
                    setState(() => _error = null);
                  },
                ),
              ],
            ],
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: canAddVoice
              ? () => _showAddVoiceDialog(context, ref)
              : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Voice'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddVoiceDialog(BuildContext context, WidgetRef ref) async {
    setState(() => _error = null);

    final config = ref
        .read(ttsSettingsProvider)
        .providerConfigs[TTSProvider.kokoroTTS];
    final voices = config?.kokoroVoices ?? [];

    if (voices.length >= 2) {
      setState(() => _error = 'Maximum 2 voices allowed for mixing');
      return;
    }

    final service = ref.read(ttsServiceProvider);

    if (service is! KokoroTTSService) {
      setState(() => _error = 'TTS service is not KokoroTTS');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _VoiceSelectionDialog(),
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
            errorText: 'Weight must be between 1 and 10',
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
              if (weight != null && weight >= 1 && weight <= 10) {
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

class _VoiceSelectionDialog extends ConsumerStatefulWidget {
  const _VoiceSelectionDialog();

  @override
  ConsumerState<_VoiceSelectionDialog> createState() =>
      _VoiceSelectionDialogState();
}

class _VoiceSelectionDialogState extends ConsumerState<_VoiceSelectionDialog> {
  List<String>? _availableVoices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAvailableVoices();
  }

  Future<void> _fetchAvailableVoices() async {
    final service = ref.read(ttsServiceProvider);

    if (service is! KokoroTTSService) {
      setState(() {
        _isLoading = false;
        _error = 'TTS service is not KokoroTTS';
      });
      return;
    }

    try {
      final voices = await service.getAvailableVoices();
      setState(() {
        _availableVoices = voices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(ttsSettingsProvider);
    final config = settings.providerConfigs[TTSProvider.kokoroTTS];
    final selectedVoices = config?.kokoroVoices ?? [];

    return AlertDialog(
      title: const Text('Add Voice'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchAvailableVoices,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _availableVoices?.length ?? 0,
                itemBuilder: (context, index) {
                  final voice = _availableVoices![index];
                  final isSelected = selectedVoices.any(
                    (v) => v.voice == voice,
                  );
                  return ListTile(
                    title: Text(voice),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    enabled: !isSelected,
                    onTap: isSelected
                        ? null
                        : () async {
                            final success = await ref
                                .read(ttsSettingsProvider.notifier)
                                .addKokoroVoice(voice, 1);
                            if (success && mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
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
