import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/ai_settings_provider.dart';
import 'package:lute_for_mobile/features/settings/widgets/model_selector.dart';

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
              initialValue: provider,
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
        ModelSelector(
          selectedModel: config?.model,
          labelText: 'Model',
          hintText: 'e.g., gpt-4o',
          onModelSelected: (value) {
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
        ModelSelector(
          selectedModel: config?.model,
          labelText: 'Model',
          hintText: 'e.g., gpt-4o',
          onModelSelected: (value) {
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
    final currentPrompt =
        config?.customPrompt ?? AIPromptTemplates.getDefault(type);
    final isCustom = config?.customPrompt?.isNotEmpty ?? false;
    final placeholders = _getPlaceholders(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: Text(title),
                subtitle: Text(
                  config?.enabled ?? true ? 'Enabled' : 'Disabled',
                ),
                value: config?.enabled ?? true,
                onChanged: (value) {
                  ref
                      .read(aiSettingsProvider.notifier)
                      .updatePromptConfig(
                        type,
                        config!.copyWith(enabled: value),
                      );
                },
              ),
            ),
            if (isCustom)
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Reset to Default'),
                      content: const Text(
                        'Are you sure you want to reset this prompt to the default template?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(aiSettingsProvider.notifier)
                                .updatePromptConfig(
                                  type,
                                  config!.copyWith(customPrompt: null),
                                );
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset'),
              ),
          ],
        ),
        if (config?.enabled ?? true) ...[
          _PromptEditor(
            initialText: currentPrompt,
            onChanged: (value) {
              ref
                  .read(aiSettingsProvider.notifier)
                  .updatePromptConfig(
                    type,
                    config!.copyWith(customPrompt: value),
                  );
            },
          ),
          const SizedBox(height: 8),
          _buildPlaceholdersHint(placeholders),
        ],
      ],
    );
  }

  List<PlaceholderInfo> _getPlaceholders(AIPromptType type) {
    switch (type) {
      case AIPromptType.termTranslation:
        return [
          const PlaceholderInfo(
            placeholder: '[term]',
            description: 'The term to translate',
            example: 'perro',
          ),
          const PlaceholderInfo(
            placeholder: '[sentence]',
            description: 'The context sentence',
            example: 'El perro corre rápido.',
          ),
          const PlaceholderInfo(
            placeholder: '[language]',
            description: 'The source language',
            example: 'Spanish',
          ),
        ];
      case AIPromptType.sentenceTranslation:
        return [
          const PlaceholderInfo(
            placeholder: '[sentence]',
            description: 'The sentence to translate',
            example: 'El perro corre rápido.',
          ),
          const PlaceholderInfo(
            placeholder: '[language]',
            description: 'The source language',
            example: 'Spanish',
          ),
        ];
    }
  }

  Widget _buildPlaceholdersHint(List<PlaceholderInfo> placeholders) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Placeholders:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...placeholders.map(
              (p) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.placeholder}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${p.description} (e.g., "${p.example}")',
                        style: const TextStyle(fontSize: 12),
                      ),
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
}

class _PromptEditor extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;

  const _PromptEditor({required this.initialText, required this.onChanged});

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(_PromptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Prompt',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}

class PlaceholderInfo {
  final String placeholder;
  final String description;
  final String example;

  const PlaceholderInfo({
    required this.placeholder,
    required this.description,
    required this.example,
  });
}
