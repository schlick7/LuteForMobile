import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/ai_settings_provider.dart';
import 'package:lute_for_mobile/features/settings/widgets/model_selector.dart';

class AISettingsSection extends ConsumerStatefulWidget {
  const AISettingsSection({super.key});

  @override
  ConsumerState<AISettingsSection> createState() => _AISettingsSectionState();
}

class _AISettingsSectionState extends ConsumerState<AISettingsSection> {
  bool _isExpanded = false;
  final Map<AIPromptType, bool> _promptExpanded = {};

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final provider = settings.provider;
    final config = settings.providerConfigs[provider];

    return Card(
      child: ExpansionTile(
        title: const Text(
          'AI Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      ref
                          .read(aiSettingsProvider.notifier)
                          .updateProvider(value);
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
        ],
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
    return _OpenAISettings(
      config: config,
      onApiKeyChanged: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateOpenAIConfig(config.copyWith(apiKey: value));
        }
      },
      onBaseUrlChanged: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateOpenAIConfig(
                config.copyWith(baseUrl: value.isEmpty ? null : value),
              );
        }
      },
      onModelSelected: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateOpenAIConfig(config.copyWith(model: value));
        }
      },
    );
  }

  Widget _buildLocalOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    AISettingsConfig? config,
  ) {
    return _LocalOpenAISettings(
      config: config,
      onEndpointUrlChanged: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateLocalOpenAIConfig(config.copyWith(endpointUrl: value));
        }
      },
      onModelSelected: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateLocalOpenAIConfig(config.copyWith(model: value));
        }
      },
      onApiKeyChanged: (value) {
        if (config != null) {
          ref
              .read(aiSettingsProvider.notifier)
              .updateLocalOpenAIConfig(
                config.copyWith(apiKey: value.isEmpty ? null : value),
              );
        }
      },
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
        const SizedBox(height: 16),
        _buildPromptConfigSection(
          context,
          ref,
          settings,
          AIPromptType.virtualDictionary,
          'Virtual Dictionary',
        ),
        const SizedBox(height: 16),
        _buildPromptConfigSection(
          context,
          ref,
          settings,
          AIPromptType.termExplanation,
          'Term Explanation',
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
    final isExpanded = _promptExpanded[type] ?? false;

    return ExpansionTile(
      title: Text(title),
      subtitle: Text(config?.enabled ?? true ? 'Enabled' : 'Disabled'),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _promptExpanded[type] = expanded;
        });
      },
      leading: Switch(
        value: config?.enabled ?? true,
        onChanged: (value) {
          ref
              .read(aiSettingsProvider.notifier)
              .updatePromptConfig(type, config!.copyWith(enabled: value));
        },
      ),
      children: [
        if (config?.enabled ?? true) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PromptEditor(
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
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
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
                                  AIPromptConfig(
                                    customPrompt: null,
                                    enabled: config!.enabled,
                                  ),
                                );
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Reset to Default'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPlaceholdersHint(context, placeholders),
          ),
          const SizedBox(height: 16),
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
      case AIPromptType.virtualDictionary:
        return [
          const PlaceholderInfo(
            placeholder: '[sentence]',
            description: 'The sentence to analyze',
            example: 'El perro corre rápido.',
          ),
          const PlaceholderInfo(
            placeholder: '[language]',
            description: 'The source language',
            example: 'Spanish',
          ),
        ];
      case AIPromptType.termExplanation:
        return [
          const PlaceholderInfo(
            placeholder: '[term]',
            description: 'The term to explain',
            example: 'perro',
          ),
          const PlaceholderInfo(
            placeholder: '[sentence]',
            description: 'The context sentence (optional)',
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

  Widget _buildPlaceholdersHint(
    BuildContext context,
    List<PlaceholderInfo> placeholders,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    if (widget.initialText != oldWidget.initialText &&
        _controller.text != widget.initialText) {
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

class _OpenAISettings extends ConsumerStatefulWidget {
  final AISettingsConfig? config;
  final ValueChanged<String> onApiKeyChanged;
  final ValueChanged<String> onBaseUrlChanged;
  final ValueChanged<String?> onModelSelected;

  const _OpenAISettings({
    required this.config,
    required this.onApiKeyChanged,
    required this.onBaseUrlChanged,
    required this.onModelSelected,
  });

  @override
  ConsumerState<_OpenAISettings> createState() => _OpenAISettingsState();
}

class _OpenAISettingsState extends ConsumerState<_OpenAISettings> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _baseUrlController = TextEditingController(
      text: widget.config?.baseUrl ?? '',
    );
  }

  @override
  void didUpdateWidget(_OpenAISettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.apiKey != oldWidget.config?.apiKey &&
        _apiKeyController.text != (widget.config?.apiKey ?? '')) {
      _apiKeyController.text = widget.config?.apiKey ?? '';
    }
    if (widget.config?.baseUrl != oldWidget.config?.baseUrl &&
        _baseUrlController.text != (widget.config?.baseUrl ?? '')) {
      _baseUrlController.text = widget.config?.baseUrl ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          controller: _apiKeyController,
          onSubmitted: widget.onApiKeyChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Base URL (optional)',
            hintText: 'https://api.openai.com',
            border: OutlineInputBorder(),
          ),
          controller: _baseUrlController,
          onSubmitted: widget.onBaseUrlChanged,
        ),
        const SizedBox(height: 16),
        ModelSelector(
          selectedModel: widget.config?.model,
          labelText: 'Model',
          hintText: 'e.g., gpt-4o',
          onModelSelected: widget.onModelSelected,
        ),
      ],
    );
  }
}

class _LocalOpenAISettings extends ConsumerStatefulWidget {
  final AISettingsConfig? config;
  final ValueChanged<String> onEndpointUrlChanged;
  final ValueChanged<String?> onModelSelected;
  final ValueChanged<String> onApiKeyChanged;

  const _LocalOpenAISettings({
    required this.config,
    required this.onEndpointUrlChanged,
    required this.onModelSelected,
    required this.onApiKeyChanged,
  });

  @override
  ConsumerState<_LocalOpenAISettings> createState() =>
      _LocalOpenAISettingsState();
}

class _LocalOpenAISettingsState extends ConsumerState<_LocalOpenAISettings> {
  late TextEditingController _endpointUrlController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _endpointUrlController = TextEditingController(
      text: widget.config?.endpointUrl ?? '',
    );
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
  }

  @override
  void didUpdateWidget(_LocalOpenAISettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.endpointUrl != oldWidget.config?.endpointUrl &&
        _endpointUrlController.text != (widget.config?.endpointUrl ?? '')) {
      _endpointUrlController.text = widget.config?.endpointUrl ?? '';
    }
    if (widget.config?.apiKey != oldWidget.config?.apiKey &&
        _apiKeyController.text != (widget.config?.apiKey ?? '')) {
      _apiKeyController.text = widget.config?.apiKey ?? '';
    }
  }

  @override
  void dispose() {
    _endpointUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'http://localhost:port/v1',
            border: OutlineInputBorder(),
          ),
          controller: _endpointUrlController,
          onSubmitted: widget.onEndpointUrlChanged,
        ),
        const SizedBox(height: 16),
        ModelSelector(
          selectedModel: widget.config?.model,
          labelText: 'Model',
          hintText: 'e.g., gpt-4o',
          onModelSelected: widget.onModelSelected,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'API Key (optional)',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          controller: _apiKeyController,
          onSubmitted: widget.onApiKeyChanged,
        ),
      ],
    );
  }
}
