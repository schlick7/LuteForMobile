import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';

class TTSSettingsSection extends ConsumerWidget {
  const TTSSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(ttsSettingsProvider);
    final provider = settings.provider;
    final config = settings.providerConfigs[provider];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TTS Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TTSProvider>(
              value: provider,
              decoration: const InputDecoration(
                labelText: 'TTS Provider',
                border: OutlineInputBorder(),
              ),
              items: TTSProvider.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(_providerDisplayName(p)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(ttsSettingsProvider.notifier).updateProvider(value);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildProviderSettings(context, ref, provider, config),
          ],
        ),
      ),
    );
  }

  String _providerDisplayName(TTSProvider provider) {
    switch (provider) {
      case TTSProvider.onDevice:
        return 'On Device';
      case TTSProvider.kokoroTTS:
        return 'KokoroTTS';
      case TTSProvider.localOpenAI:
        return 'Local OpenAI';
      case TTSProvider.openAI:
        return 'OpenAI';
      case TTSProvider.none:
        return 'None';
    }
  }

  Widget _buildProviderSettings(
    BuildContext context,
    WidgetRef ref,
    TTSProvider provider,
    TTSSettingsConfig? config,
  ) {
    switch (provider) {
      case TTSProvider.onDevice:
        return _buildOnDeviceSettings(context, ref, config);
      case TTSProvider.kokoroTTS:
        return _buildKokoroSettings(context, ref, config);
      case TTSProvider.openAI:
        return _buildOpenAISettings(context, ref, config);
      case TTSProvider.localOpenAI:
        return _buildLocalOpenAISettings(context, ref, config);
      case TTSProvider.none:
        return const Text(
          'TTS is disabled',
          style: TextStyle(color: Colors.grey),
        );
    }
  }

  Widget _buildOnDeviceSettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Voice',
            hintText: 'e.g., en-us',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.voice),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOnDeviceConfig(config!.copyWith(voice: value));
          },
        ),
        const SizedBox(height: 16),
        Text('Rate: ${(config?.rate ?? 1.0).toStringAsFixed(2)}'),
        Slider(
          value: config?.rate ?? 1.0,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOnDeviceConfig(config!.copyWith(rate: value));
          },
        ),
        const SizedBox(height: 16),
        Text('Pitch: ${(config?.pitch ?? 1.0).toStringAsFixed(2)}'),
        Slider(
          value: config?.pitch ?? 1.0,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOnDeviceConfig(config!.copyWith(pitch: value));
          },
        ),
        const SizedBox(height: 16),
        Text('Volume: ${(config?.volume ?? 1.0).toStringAsFixed(2)}'),
        Slider(
          value: config?.volume ?? 1.0,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOnDeviceConfig(config!.copyWith(volume: value));
          },
        ),
      ],
    );
  }

  Widget _buildKokoroSettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'http://localhost:8880/v1',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.endpointUrl),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateKokoroConfig(config!.copyWith(endpointUrl: value));
          },
        ),
        const SizedBox(height: 16),
        Text('Speed: ${(config?.speed ?? 1.0).toStringAsFixed(2)}'),
        Slider(
          value: config?.speed ?? 1.0,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateKokoroConfig(config!.copyWith(speed: value));
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Use Streaming'),
          subtitle: const Text('Enable for long texts (future enhancement)'),
          value: config?.useStreaming ?? false,
          onChanged: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateKokoroConfig(config!.copyWith(useStreaming: value));
          },
        ),
      ],
    );
  }

  Widget _buildOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          controller: TextEditingController(text: config?.apiKey),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOpenAIConfig(config!.copyWith(apiKey: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., tts-1',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.model),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOpenAIConfig(config!.copyWith(model: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Voice',
            hintText: 'e.g., alloy, echo, fable',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.openAIVoice),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOpenAIConfig(config!.copyWith(openAIVoice: value));
          },
        ),
      ],
    );
  }

  Widget _buildLocalOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'http://localhost:port/v1',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.endpointUrl),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateLocalOpenAIConfig(config!.copyWith(endpointUrl: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., tts-1',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.model),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateLocalOpenAIConfig(config!.copyWith(model: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Voice',
            hintText: 'e.g., alloy, echo, fable',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.voice),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateLocalOpenAIConfig(config!.copyWith(voice: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'API Key (optional)',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          controller: TextEditingController(text: config?.apiKey),
          onSubmitted: (value) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateLocalOpenAIConfig(
                  config!.copyWith(apiKey: value.isEmpty ? null : value),
                );
          },
        ),
      ],
    );
  }
}
