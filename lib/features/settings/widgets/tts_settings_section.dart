import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/network/tts_service.dart';
import 'package:lute_for_mobile/core/providers/tts_provider.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';
import 'package:lute_for_mobile/features/settings/widgets/kokoro_voice_chips.dart';
import 'package:lute_for_mobile/features/settings/widgets/on_device_voice_selector.dart';
import 'package:lute_for_mobile/shared/theme/theme_extensions.dart';

class TTSSettingsSection extends ConsumerStatefulWidget {
  const TTSSettingsSection({super.key});

  @override
  ConsumerState<TTSSettingsSection> createState() => _TTSSettingsSectionState();
}

class _TTSSettingsSectionState extends ConsumerState<TTSSettingsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(ttsSettingsProvider);
    final provider = settings.provider;
    final config = settings.providerConfigs[provider];

    return Card(
      child: ExpansionTile(
        title: const Text(
          'TTS Settings',
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
                DropdownButtonFormField<TTSProvider>(
                  initialValue: provider,
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
                      ref
                          .read(ttsSettingsProvider.notifier)
                          .updateProvider(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildProviderSettings(context, ref, provider, config),
              ],
            ),
          ),
        ],
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
      case TTSProvider.supertonicFastApi:
        return 'Supertonic FastAPI';
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
      case TTSProvider.supertonicFastApi:
        return _buildSupertonicFastApiSettings(context, ref, config);
      case TTSProvider.none:
        return Text(
          'TTS is disabled',
          style: TextStyle(color: context.appColorScheme.text.secondary),
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
        OnDeviceVoiceSelector(
          selectedVoice: config?.voice,
          selectedVoiceLocale: config?.voiceLocale,
          onVoiceChanged: (voiceName, voiceLocale) {
            ref
                .read(ttsSettingsProvider.notifier)
                .updateOnDeviceConfig(
                  config!.copyWith(voice: voiceName, voiceLocale: voiceLocale),
                );
          },
        ),
        const SizedBox(height: 16),
        Text('Rate: ${(config?.rate ?? 0.5).toStringAsFixed(2)}'),
        Slider(
          value: config?.rate ?? 0.5,
          min: 0.1,
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
        const SizedBox(height: 16),
        _TestSpeechButton(provider: TTSProvider.onDevice),
      ],
    );
  }

  Widget _buildKokoroSettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return _KokoroSettings(
      config: config,
      onEndpointUrlChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateKokoroConfig(config.copyWith(endpointUrl: value));
        }
      },
      onSpeedChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateKokoroConfig(config.copyWith(speed: value));
        }
      },
      onStreamingChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateKokoroConfig(config.copyWith(useStreaming: value));
        }
      },
    );
  }

  Widget _buildOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return _OpenAITTSSettings(
      config: config,
      onApiKeyChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateOpenAIConfig(config.copyWith(apiKey: value));
        }
      },
      onModelChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateOpenAIConfig(config.copyWith(model: value));
        }
      },
      onVoiceChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateOpenAIConfig(config.copyWith(voice: value));
        }
      },
    );
  }

  Widget _buildLocalOpenAISettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return _LocalOpenAITTSSettings(
      config: config,
      onEndpointUrlChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateLocalOpenAIConfig(config.copyWith(endpointUrl: value));
        }
      },
      onModelChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateLocalOpenAIConfig(config.copyWith(model: value));
        }
      },
      onVoiceChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateLocalOpenAIConfig(config.copyWith(voice: value));
        }
      },
      onApiKeyChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateLocalOpenAIConfig(
                config.copyWith(apiKey: value.isEmpty ? null : value),
              );
        }
      },
    );
  }

  Widget _buildSupertonicFastApiSettings(
    BuildContext context,
    WidgetRef ref,
    TTSSettingsConfig? config,
  ) {
    return _SupertonicFastApiTTSSettings(
      config: config,
      onEndpointUrlChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateSupertonicFastApiConfig(
                config.copyWith(endpointUrl: value),
              );
        }
      },
      onVoiceChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateSupertonicFastApiConfig(config.copyWith(voice: value));
        }
      },
      onLanguageCodeChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateSupertonicFastApiConfig(
                config.copyWith(languageCode: value),
              );
        }
      },
      onTotalStepsChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateSupertonicFastApiConfig(
                config.copyWith(totalSteps: value),
              );
        }
      },
      onSpeedChanged: (value) {
        if (config != null) {
          ref
              .read(ttsSettingsProvider.notifier)
              .updateSupertonicFastApiConfig(config.copyWith(speed: value));
        }
      },
    );
  }
}

class _KokoroSettings extends ConsumerStatefulWidget {
  final TTSSettingsConfig? config;
  final ValueChanged<String> onEndpointUrlChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onStreamingChanged;

  const _KokoroSettings({
    required this.config,
    required this.onEndpointUrlChanged,
    required this.onSpeedChanged,
    required this.onStreamingChanged,
  });

  @override
  ConsumerState<_KokoroSettings> createState() => _KokoroSettingsState();
}

class _KokoroSettingsState extends ConsumerState<_KokoroSettings> {
  late TextEditingController _endpointUrlController;

  @override
  void initState() {
    super.initState();
    _endpointUrlController = TextEditingController(
      text: widget.config?.endpointUrl ?? '',
    );
  }

  @override
  void didUpdateWidget(_KokoroSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.endpointUrl != oldWidget.config?.endpointUrl &&
        _endpointUrlController.text != (widget.config?.endpointUrl ?? '')) {
      _endpointUrlController.text = widget.config?.endpointUrl ?? '';
    }
  }

  @override
  void dispose() {
    _endpointUrlController.dispose();
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
            hintText: 'http://localhost:8880/v1',
            border: OutlineInputBorder(),
          ),
          controller: _endpointUrlController,
          onSubmitted: widget.onEndpointUrlChanged,
        ),
        const SizedBox(height: 16),
        const Text('Voices', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const KokoroVoiceChips(),
        const SizedBox(height: 16),
        Text('Speed: ${(widget.config?.speed ?? 1.0).toStringAsFixed(2)}'),
        Slider(
          value: widget.config?.speed ?? 1.0,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: widget.onSpeedChanged,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Use Streaming'),
          subtitle: const Text('Enable for long texts (future enhancement)'),
          value: widget.config?.useStreaming ?? false,
          onChanged: widget.onStreamingChanged,
        ),
        const SizedBox(height: 16),
        _TestSpeechButton(provider: TTSProvider.kokoroTTS),
      ],
    );
  }
}

class _OpenAITTSSettings extends ConsumerStatefulWidget {
  final TTSSettingsConfig? config;
  final ValueChanged<String> onApiKeyChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onVoiceChanged;

  const _OpenAITTSSettings({
    required this.config,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    required this.onVoiceChanged,
  });

  @override
  ConsumerState<_OpenAITTSSettings> createState() => _OpenAITTSSettingsState();
}

class _OpenAITTSSettingsState extends ConsumerState<_OpenAITTSSettings> {
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _voiceController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _modelController = TextEditingController(text: widget.config?.model ?? '');
    _voiceController = TextEditingController(text: widget.config?.voice ?? '');
  }

  @override
  void didUpdateWidget(_OpenAITTSSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.apiKey != oldWidget.config?.apiKey &&
        _apiKeyController.text != (widget.config?.apiKey ?? '')) {
      _apiKeyController.text = widget.config?.apiKey ?? '';
    }
    if (widget.config?.model != oldWidget.config?.model &&
        _modelController.text != (widget.config?.model ?? '')) {
      _modelController.text = widget.config?.model ?? '';
    }
    if (widget.config?.voice != oldWidget.config?.voice &&
        _voiceController.text != (widget.config?.voice ?? '')) {
      _voiceController.text = widget.config?.voice ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _voiceController.dispose();
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
            labelText: 'Model',
            hintText: 'e.g., tts-1',
            border: OutlineInputBorder(),
          ),
          controller: _modelController,
          onSubmitted: widget.onModelChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Voice',
            hintText: 'e.g., alloy, echo, fable',
            border: OutlineInputBorder(),
          ),
          controller: _voiceController,
          onSubmitted: widget.onVoiceChanged,
        ),
        const SizedBox(height: 16),
        _TestSpeechButton(provider: TTSProvider.openAI),
      ],
    );
  }
}

class _LocalOpenAITTSSettings extends ConsumerStatefulWidget {
  final TTSSettingsConfig? config;
  final ValueChanged<String> onEndpointUrlChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<String> onApiKeyChanged;

  const _LocalOpenAITTSSettings({
    required this.config,
    required this.onEndpointUrlChanged,
    required this.onModelChanged,
    required this.onVoiceChanged,
    required this.onApiKeyChanged,
  });

  @override
  ConsumerState<_LocalOpenAITTSSettings> createState() =>
      _LocalOpenAITTSSettingsState();
}

class _LocalOpenAITTSSettingsState
    extends ConsumerState<_LocalOpenAITTSSettings> {
  late TextEditingController _endpointUrlController;
  late TextEditingController _modelController;
  late TextEditingController _voiceController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _endpointUrlController = TextEditingController(
      text: widget.config?.endpointUrl ?? '',
    );
    _modelController = TextEditingController(text: widget.config?.model ?? '');
    _voiceController = TextEditingController(text: widget.config?.voice ?? '');
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
  }

  @override
  void didUpdateWidget(_LocalOpenAITTSSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.endpointUrl != oldWidget.config?.endpointUrl &&
        _endpointUrlController.text != (widget.config?.endpointUrl ?? '')) {
      _endpointUrlController.text = widget.config?.endpointUrl ?? '';
    }
    if (widget.config?.model != oldWidget.config?.model &&
        _modelController.text != (widget.config?.model ?? '')) {
      _modelController.text = widget.config?.model ?? '';
    }
    if (widget.config?.voice != oldWidget.config?.voice &&
        _voiceController.text != (widget.config?.voice ?? '')) {
      _voiceController.text = widget.config?.voice ?? '';
    }
    if (widget.config?.apiKey != oldWidget.config?.apiKey &&
        _apiKeyController.text != (widget.config?.apiKey ?? '')) {
      _apiKeyController.text = widget.config?.apiKey ?? '';
    }
  }

  @override
  void dispose() {
    _endpointUrlController.dispose();
    _modelController.dispose();
    _voiceController.dispose();
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
        TextField(
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., tts-1',
            border: OutlineInputBorder(),
          ),
          controller: _modelController,
          onSubmitted: widget.onModelChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Voice',
            hintText: 'e.g., alloy, echo, fable',
            border: OutlineInputBorder(),
          ),
          controller: _voiceController,
          onSubmitted: widget.onVoiceChanged,
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
        const SizedBox(height: 16),
        _TestSpeechButton(provider: TTSProvider.localOpenAI),
      ],
    );
  }
}

class _SupertonicFastApiTTSSettings extends ConsumerStatefulWidget {
  final TTSSettingsConfig? config;
  final ValueChanged<String> onEndpointUrlChanged;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<String> onLanguageCodeChanged;
  final ValueChanged<int> onTotalStepsChanged;
  final ValueChanged<double> onSpeedChanged;

  const _SupertonicFastApiTTSSettings({
    required this.config,
    required this.onEndpointUrlChanged,
    required this.onVoiceChanged,
    required this.onLanguageCodeChanged,
    required this.onTotalStepsChanged,
    required this.onSpeedChanged,
  });

  @override
  ConsumerState<_SupertonicFastApiTTSSettings> createState() =>
      _SupertonicFastApiTTSSettingsState();
}

class _SupertonicFastApiTTSSettingsState
    extends ConsumerState<_SupertonicFastApiTTSSettings> {
  static const List<String> _supportedLanguages = [
    'en',
    'ko',
    'es',
    'pt',
    'fr',
  ];

  late TextEditingController _endpointUrlController;
  List<TTSVoice>? _availableVoices;
  bool _isLoadingVoices = false;
  String? _voiceError;

  @override
  void initState() {
    super.initState();
    _endpointUrlController = TextEditingController(
      text: widget.config?.endpointUrl ?? '',
    );
    _loadVoices();
  }

  @override
  void didUpdateWidget(_SupertonicFastApiTTSSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.endpointUrl != oldWidget.config?.endpointUrl &&
        _endpointUrlController.text != (widget.config?.endpointUrl ?? '')) {
      _endpointUrlController.text = widget.config?.endpointUrl ?? '';
      _loadVoices();
    }
  }

  @override
  void dispose() {
    _endpointUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    final endpointUrl = _endpointUrlController.text.trim();
    if (endpointUrl.isEmpty) {
      setState(() {
        _availableVoices = null;
        _voiceError = 'Enter an endpoint URL to load voices.';
        _isLoadingVoices = false;
      });
      return;
    }

    setState(() {
      _isLoadingVoices = true;
      _voiceError = null;
    });

    final service = SupertonicFastApiTTSService(
      endpointUrl: endpointUrl,
      voice: widget.config?.voice ?? 'M1',
      languageCode: widget.config?.languageCode ?? 'en',
      totalSteps: widget.config?.totalSteps ?? 5,
      speed: widget.config?.speed ?? 1.05,
    );

    try {
      final voices = await service.getAvailableVoices();
      if (!mounted) return;

      setState(() {
        _availableVoices = voices;
        _isLoadingVoices = false;
        _voiceError = voices.isEmpty
            ? 'No voices returned from /voices.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableVoices = null;
        _isLoadingVoices = false;
        _voiceError = e.toString();
      });
    } finally {
      service.dispose();
    }
  }

  Future<void> _saveEndpointAndRefreshVoices() async {
    final endpointUrl = _endpointUrlController.text.trim();
    if (endpointUrl.isNotEmpty && endpointUrl != widget.config?.endpointUrl) {
      widget.onEndpointUrlChanged(endpointUrl);
    }
    await _loadVoices();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVoice = widget.config?.voice ?? 'M1';
    final List<TTSVoice> voiceOptions = [
      ...?_availableVoices,
      if ((_availableVoices ?? []).every(
        (voice) => voice.name != selectedVoice,
      ))
        TTSVoice(
          name: selectedVoice,
          locale: widget.config?.languageCode ?? 'en',
        ),
    ];
    final String selectedLanguage =
        widget.config?.languageCode != null &&
            _supportedLanguages.contains(widget.config!.languageCode)
        ? widget.config!.languageCode!
        : 'en';
    final int qualitySteps = (widget.config?.totalSteps ?? 5).clamp(2, 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'http://192.168.1.159:8800',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _isLoadingVoices
                  ? null
                  : _saveEndpointAndRefreshVoices,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh voices',
            ),
          ),
          controller: _endpointUrlController,
          onSubmitted: (_) => _saveEndpointAndRefreshVoices(),
        ),
        const SizedBox(height: 16),
        if (_voiceError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _voiceError!,
              style: TextStyle(
                color: context.appColorScheme.error.error,
                fontSize: 12,
              ),
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: voiceOptions.any((voice) => voice.name == selectedVoice)
              ? selectedVoice
              : null,
          decoration: InputDecoration(
            labelText: 'Voice',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoadingVoices
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: voiceOptions
              .map(
                (voice) => DropdownMenuItem<String>(
                  value: voice.name,
                  child: Text(voice.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onVoiceChanged(value);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedLanguage,
          decoration: const InputDecoration(
            labelText: 'Language Code',
            border: OutlineInputBorder(),
          ),
          items: _supportedLanguages
              .map(
                (language) => DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onLanguageCodeChanged(value);
            }
          },
        ),
        const SizedBox(height: 16),
        Text('Quality Steps: $qualitySteps'),
        Slider(
          value: qualitySteps.toDouble(),
          min: 2,
          max: 15,
          divisions: 13,
          label: '$qualitySteps',
          onChanged: (value) {
            widget.onTotalStepsChanged(value.round());
          },
        ),
        Text(
          'Higher values improve quality by increasing Supertonic denoising steps. Default is 5; 10 is a documented higher-quality setting with slower inference.',
          style: TextStyle(
            color: context.appColorScheme.text.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Text('Speed: ${(widget.config?.speed ?? 1.05).toStringAsFixed(2)}'),
        Slider(
          value: widget.config?.speed ?? 1.05,
          min: 0.7,
          max: 2.0,
          divisions: 13,
          onChanged: widget.onSpeedChanged,
        ),
        const SizedBox(height: 8),
        Text(
          'Uses GET /voices and POST $_supertonicPath with voice=$selectedVoice, lang=$selectedLanguage, total_steps=$qualitySteps.',
          style: TextStyle(
            color: context.appColorScheme.text.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _TestSpeechButton(provider: TTSProvider.supertonicFastApi),
      ],
    );
  }

  static const String _supertonicPath = '/synthesize';
}

class _TestSpeechButton extends ConsumerStatefulWidget {
  final TTSProvider provider;

  const _TestSpeechButton({required this.provider});

  @override
  ConsumerState<_TestSpeechButton> createState() => _TestSpeechButtonState();
}

class _TestSpeechButtonState extends ConsumerState<_TestSpeechButton> {
  bool _isPlaying = false;
  String? _error;

  Future<void> _testSpeech() async {
    setState(() {
      _isPlaying = true;
      _error = null;
    });

    try {
      final service = ref.read(ttsServiceProvider);
      await service.speak('Hello, this is a test of the text to speech.');
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _error!,
              style: TextStyle(
                color: context.appColorScheme.error.error,
                fontSize: 12,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isPlaying ? null : _testSpeech,
          icon: _isPlaying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.volume_up, size: 18),
          label: Text(_isPlaying ? 'Playing...' : 'Test Speech'),
        ),
      ],
    );
  }
}
