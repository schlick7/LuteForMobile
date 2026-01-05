import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/ai_settings_provider.dart';

class AISettingsSection extends ConsumerWidget {
  const AISettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final provider = settings.provider;
    final config = settings.providerConfigs[provider];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIProvider>(
              value: provider,
              decoration: const InputDecoration(
                labelText: 'AI Provider',
                border: OutlineInputBorder(),
              ),
              items: AIProvider.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(_providerDisplayName(p)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(aiSettingsProvider.notifier).updateProvider(value);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildProviderSettings(context, ref, provider, config),
            const Divider(height: 32),
            const Text(
              'Prompt Configurations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPromptSettings(context, ref, settings),
          ],
        ),
      ),
    );
  }

  String _providerDisplayName(AIProvider provider) {
    switch (provider) {
      case AIProvider.localOpenAI:
        return 'Local OpenAI';
      case AIProvider.openAI:
        return 'OpenAI';
      case AIProvider.none:
        return 'None';
    }
  }

  Widget _buildProviderSettings(
    BuildContext context,
    WidgetRef ref,
    AIProvider provider,
    AISettingsConfig? config,
  ) {
    switch (provider) {
      case AIProvider.openAI:
        return _buildOpenAISettings(context, ref, config);
      case AIProvider.localOpenAI:
        return _buildLocalOpenAISettings(context, ref, config);
      case AIProvider.none:
        return const Text(
          'AI features are disabled',
          style: TextStyle(color: Colors.grey),
        );
    }
  }

  Widget _buildOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    AISettingsConfig? config,
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
                .read(aiSettingsProvider.notifier)
                .updateOpenAIConfig(config!.copyWith(apiKey: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Base URL (optional)',
            hintText: 'https://api.openai.com',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.baseUrl),
          onSubmitted: (value) {
            ref
                .read(aiSettingsProvider.notifier)
                .updateOpenAIConfig(
                  config!.copyWith(baseUrl: value.isEmpty ? null : value),
                );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., gpt-4o',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.model),
          onSubmitted: (value) {
            ref
                .read(aiSettingsProvider.notifier)
                .updateOpenAIConfig(config!.copyWith(model: value));
          },
        ),
      ],
    );
  }

  Widget _buildLocalOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    AISettingsConfig? config,
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
                .read(aiSettingsProvider.notifier)
                .updateLocalOpenAIConfig(config!.copyWith(endpointUrl: value));
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., gpt-4o',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: config?.model),
          onSubmitted: (value) {
            ref
                .read(aiSettingsProvider.notifier)
                .updateLocalOpenAIConfig(config!.copyWith(model: value));
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
                .read(aiSettingsProvider.notifier)
                .updateLocalOpenAIConfig(
                  config!.copyWith(apiKey: value.isEmpty ? null : value),
                );
          },
        ),
      ],
    );
  }

  Widget _buildPromptSettings(
    BuildContext context,
    WidgetRef ref,
    AISettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPromptConfigSection(
          context,
          ref,
          settings,
          AIPromptType.termTranslation,
          'Term Translation',
        ),
        const SizedBox(height: 16),
        _buildPromptConfigSection(
          context,
          ref,
          settings,
          AIPromptType.sentenceTranslation,
          'Sentence Translation',
        ),
      ],
    );
  }

  Widget _buildPromptConfigSection(
    BuildContext context,
    WidgetRef ref,
    AISettings settings,
    AIPromptType type,
    String title,
  ) {
    final config = settings.promptConfigs[type];
    final defaultPrompt = AIPromptTemplates.getDefault(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(config?.enabled ?? true ? 'Enabled' : 'Disabled'),
          value: config?.enabled ?? true,
          onChanged: (value) {
            ref
                .read(aiSettingsProvider.notifier)
                .updatePromptConfig(type, config!.copyWith(enabled: value));
          },
        ),
        if (config?.enabled ?? true) ...[
          TextField(
            decoration: InputDecoration(
              labelText: 'Custom Prompt',
              hintText: defaultPrompt,
              helperText: 'Placeholders: [term], [sentence], [language]',
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
            controller: TextEditingController(text: config?.customPrompt),
            onSubmitted: (value) {
              ref
                  .read(aiSettingsProvider.notifier)
                  .updatePromptConfig(
                    type,
                    config!.copyWith(
                      customPrompt: value.isEmpty ? null : value,
                    ),
                  );
            },
          ),
        ],
      ],
    );
  }
}
