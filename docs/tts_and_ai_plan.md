# TTS and AI Options Implementation Plan

## Overview

Implementation of Text-to-Speech (TTS) and AI features with multiple provider options and custom prompt templates.

## Requirements

### TTS Options
- **On device**: Use flutter_tts package
- **local-OpenAI endpoint**: Custom local server with OpenAI-compatible TTS API
- **OpenAI**: Official OpenAI TTS API
- **None**: Disable TTS functionality
- Unique settings for each option

### AI Options
- **local-OpenAI endpoint**: Custom local server with OpenAI-compatible API
- **OpenAI**: Official OpenAI API
- **None**: Disable AI functionality
- Two prompt types: term translation, sentence translation
- Same model for both prompt types
- Customizable prompts with placeholders: `[term]`, `[sentence]`, `[language]`
- On-demand model fetching (when user clicks model selector, NOT on app startup)
- Fetch models from `/v1/models` endpoint

---

## Architecture

### Data Models

#### `lib/features/settings/models/tts_settings.dart`
```dart
enum TTSProvider {
  onDevice,
  localOpenAI,
  openAI,
  none,
}

@immutable
class TTSSettings {
  final TTSProvider provider;
  final Map<TTSProvider, TTSSettingsConfig> providerConfigs;
}

@immutable
class TTSSettingsConfig {
  // On-device settings
  final String? voice;
  final double? rate;
  final double? pitch;
  final double? volume;

  // OpenAI settings (both OpenAI and local-OpenAI)
  final String? apiKey;
  final String? model;
  final String? voice; // OpenAI voice name (e.g., "alloy", "echo", "fable")

  // Local endpoint settings only
  final String? endpointUrl;
}
```

#### `lib/features/settings/models/ai_settings.dart`
```dart
enum AIProvider {
  localOpenAI,
  openAI,
  none,
}

enum AIPromptType {
  termTranslation,
  sentenceTranslation,
}

@immutable
class AISettings {
  final AIProvider provider;
  final Map<AIProvider, AISettingsConfig> providerConfigs;
  final Map<AIPromptType, AIPromptConfig> promptConfigs;
}

@immutable
class AISettingsConfig {
  final String? apiKey;
  final String? baseUrl;
  final String? model;
  final String? endpointUrl; // Local endpoint only
}

@immutable
class AIPromptConfig {
  final String? customPrompt; // Supports [term], [sentence], [language] placeholders
  final bool enabled;
  final String? language; // Target language override (optional)
}

// Default prompt templates
class AIPromptTemplates {
  static const Map<AIPromptType, String> defaults = {
    AIPromptType.termTranslation:
      'Translate this [language] term to English: [term]',
    AIPromptType.sentenceTranslation:
      'Translate this [language] sentence to English: [sentence]',
  };
}
```

#### Modified `lib/features/settings/models/settings.dart`
Add fields:
```dart
final TTSProvider? ttsProvider;  // Default: TTSProvider.onDevice
final AIProvider? aiProvider;      // Default: AIProvider.none
```

---

### Settings Providers

#### `lib/features/settings/providers/tts_settings_provider.dart`
- `TTSSettingsNotifier` with SharedPreferences persistence
- Methods: `updateProvider()`, `updateOnDeviceConfig()`, `updateOpenAIConfig()`, `updateLocalOpenAIConfig()`
- Keys: `tts_provider`, `on_device_tts_config`, `openai_tts_config`, `local_openai_tts_config`

#### `lib/features/settings/providers/ai_settings_provider.dart`
- `AISettingsNotifier` with SharedPreferences persistence
- Methods: `updateProvider()`, `updateOpenAIConfig()`, `updateLocalOpenAIConfig()`, `updatePromptConfig()`
- Keys: `ai_provider`, `openai_config`, `local_openai_config`, `ai_prompt_configs`

---

### Service Layer

#### `lib/core/network/tts_service.dart`
```dart
abstract class TTSService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String languageCode);
  Future<void> setSettings(TTSSettingsConfig config);
  Future<List<String>> getAvailableVoices();
}

class OnDeviceTTSService implements TTSService {
  // Uses flutter_tts package
}

class OpenAITTSService implements TTSService {
  // Uses openai_dart package, generates speech, plays via audioplayers
}

class LocalOpenAITTSService implements TTSService {
  // Uses dio to call local endpoint (OpenAI-compatible API)
}

class NoTTSService implements TTSService {
  // No-op implementations
}
```

#### `lib/core/network/ai_service.dart`
```dart
abstract class AIService {
  Future<String> translateTerm(String term, String language);
  Future<String> translateSentence(String sentence, String language);
  Future<List<String>> fetchAvailableModels();
  Future<String> getPromptForType(AIPromptType type);
}

class OpenAIService implements AIService {
  // Uses openai_dart package
  // Implements placeholder replacement: [term], [sentence], [language]
  // Fetches models from /v1/models endpoint
}

class LocalOpenAIService implements AIService {
  // Uses dio to call local endpoint
  // Endpoint should be OpenAI-compatible: /v1/chat/completions, /v1/models
  // Same prompt replacement logic as OpenAIService
}
```

---

### Provider Factory

#### `lib/core/providers/tts_provider.dart`
```dart
final ttsServiceProvider = Provider<TTSService>((ref) {
  final settings = ref.watch(ttSSettingsProvider);
  final provider = settings.provider;
  final config = settings.providerConfigs[provider];

  switch (provider) {
    case TTSProvider.onDevice:
      final service = OnDeviceTTSService();
      if (config != null) service.setSettings(config);
      return service;
    case TTSProvider.openAI:
      return OpenAITTSService(
        apiKey: config?.apiKey ?? '',
        model: config?.model,
        voice: config?.voice,
      );
    case TTSProvider.localOpenAI:
      return LocalOpenAITTSService(
        endpointUrl: config?.endpointUrl ?? '',
        model: config?.model,
        voice: config?.voice,
        apiKey: config?.apiKey,
      );
    case TTSProvider.none:
      return NoTTSService();
  }
});
```

#### `lib/core/providers/ai_provider.dart`
```dart
final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  final provider = settings.provider;
  final config = settings.providerConfigs[provider];

  switch (provider) {
    case AIProvider.openAI:
      return OpenAIService(
        apiKey: config?.apiKey ?? '',
        baseUrl: config?.baseUrl,
        model: config?.model,
      );
    case AIProvider.localOpenAI:
      return LocalOpenAIService(
        endpointUrl: config?.endpointUrl ?? '',
        model: config?.model,
        apiKey: config?.apiKey,
      );
    case AIProvider.none:
      return NoAIService();
  }
});

// Helper provider for fetching models (cached stateful)
final aiModelsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(aiServiceProvider);
  return await service.fetchAvailableModels();
});
```

---

### UI Components

#### `lib/features/settings/widgets/tts_settings_section.dart`

Structure:
- Provider dropdown (On device, OpenAI, local-OpenAI, None)
- Provider-specific settings panels:
  - **On device**: Voice dropdown, Rate slider, Pitch slider, Volume slider
  - **OpenAI**: API key field, Model field (e.g., tts-1), Voice field (alloy/echo/fable)
  - **local-OpenAI**: Endpoint URL field, Model field, Voice field, API key field (optional)

#### `lib/features/settings/widgets/ai_settings_section.dart`

Structure:
- Provider dropdown (OpenAI, local-OpenAI, None)
- Provider-specific settings panels:
  - **OpenAI**: API key field, Model selector (on-demand fetch), Base URL field (optional)
  - **local-OpenAI**: Endpoint URL field, Model selector, API key field (optional)
- Prompt Configurations section:
  - **Term Translation Prompt**: Enable/disable toggle, Custom prompt textarea with placeholders hint
  - **Sentence Translation Prompt**: Enable/disable toggle, Custom prompt textarea with placeholders hint

#### `lib/features/settings/widgets/model_selector.dart`

Features:
- Text field or dropdown for model selection
- When user clicks/taps the field, fetch models from `/v1/models` endpoint
- Show loading indicator during fetch
- Display fetched models in dropdown
- Cache fetched models in SharedPreferences
- Add error handling for failed fetches

---

### Integration Points

#### Settings Screen
Add two new cards after "Reading" section:
1. **TTS Settings Card**
2. **AI Settings Card**

#### Reader Integration (Future phases)
- Add TTS button to sentence reader
- Add term translation via AI in tooltip or separate action
- Add sentence translation via AI in sentence reader
- Display loading states for AI calls

---

## File Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── tts_service.dart              # NEW - abstract + implementations
│   │   ├── ai_service.dart               # NEW - abstract + implementations
│   │   ├── api_service.dart              # EXISTING
│   │   └── ...
│   └── providers/
│       ├── tts_provider.dart              # NEW - factory provider
│       ├── ai_provider.dart              # NEW - factory provider + aiModelsProvider
│       └── ...
├── features/
│   ├── settings/
│   │   ├── models/
│   │   │   ├── settings.dart             # MODIFY - add ttsProvider, aiProvider fields
│   │   │   ├── tts_settings.dart         # NEW
│   │   │   └── ai_settings.dart          # NEW
│   │   ├── providers/
│   │   │   ├── settings_provider.dart    # MODIFY - add TTS/AI keys and methods
│   │   │   ├── tts_settings_provider.dart # NEW
│   │   │   └── ai_settings_provider.dart  # NEW
│   │   └── widgets/
│   │       ├── settings_screen.dart      # MODIFY - add TTS/AI sections
│   │       ├── tts_settings_section.dart  # NEW
│   │       ├── ai_settings_section.dart   # NEW
│   │       └── model_selector.dart       # NEW - on-demand model fetching
│   └── reader/
│       ├── widgets/
│       │   ├── sentence_reader.dart       # MODIFY - add TTS/AI controls
│       │   └── tts_controls_widget.dart  # NEW (optional)
│       └── ...
```

---

## Implementation Phases

### Phase 1: Foundation (Ground Work)
**Status**: Current Request

1. Create data models
   - `TTSSettings`, `TTSSettingsConfig`, `TTSProvider` enum
   - `AISettings`, `AISettingsConfig`, `AIPromptConfig`, `AIProvider`, `AIPromptType` enums
   - `AIPromptTemplates` with default prompts
   - Modify `Settings` model to add `ttsProvider` and `aiProvider` fields

2. Create service interfaces
   - `TTSService` abstract class with method signatures
   - `AIService` abstract class with method signatures
   - Placeholder implementations (empty/stubs for now)

3. Create provider infrastructure
   - `TTSSettingsNotifier` with SharedPreferences persistence
   - `AISettingsNotifier` with SharedPreferences persistence
   - `ttsServiceProvider` factory (returns placeholder for now)
   - `aiServiceProvider` factory (returns placeholder for now)
   - `aiModelsProvider` FutureProvider for model fetching

4. Add basic UI cards
   - `TTSSettingsSection` with provider dropdown
   - `AISettingsSection` with provider dropdown
   - Provider-specific settings panels (minimal/placeholder)
   - Prompt configuration UI (minimal)

5. Integrate into settings screen
   - Add TTS settings card
   - Add AI settings card
   - Verify persistence and state management

6. Create model selector widget
   - Basic UI structure
   - Placeholder fetch logic (to be implemented in Phase 4)

---

### Phase 2: TTS Implementation

1. Implement `OnDeviceTTSService`
   - Voice selection from flutter_tts
   - Rate, pitch, volume controls
   - Language setting

2. Implement `OpenAITTSService`
   - Use openai_dart to generate speech
   - Play generated audio via audioplayers
   - Handle API errors

3. Implement `LocalOpenAITTSService`
   - Use dio to call local endpoint
   - OpenAI-compatible API calls
   - Play audio via audioplayers

4. Connect TTS settings to services
   - Update factory provider to use real implementations
   - Apply settings changes at runtime

5. Add TTS to reader (basic)
   - Add speak button to sentence reader
   - Connect to `ttsServiceProvider`
   - Test with different languages

---

### Phase 3: AI Service Implementation

1. Implement `OpenAIService`
   - `translateTerm()` method
   - `translateSentence()` method
   - Placeholder replacement logic: `[term]`, `[sentence]`, `[language]`
   - `getPromptForType()` to load custom or default prompts

2. Implement `LocalOpenAIService`
   - Same methods as OpenAIService
   - Use dio to call local endpoint
   - OpenAI-compatible API (`/v1/chat/completions`, `/v1/models`)

3. Implement prompt configuration
   - Load custom prompts from SharedPreferences
   - Apply placeholders at runtime
   - Handle missing placeholders gracefully

4. Test AI services
   - Test with OpenAI API
   - Test with local endpoint
   - Verify prompt templates work correctly

---

### Phase 4: Model Fetching UI

1. Implement model fetching logic
   - `OpenAIService.fetchAvailableModels()` using openai_dart
   - `LocalOpenAIService.fetchAvailableModels()` using dio
   - Call `/v1/models` endpoint

2. Enhance `ModelSelector` widget
   - On-tap fetch models
   - Show loading indicator
   - Display fetched models in dropdown
   - Cache models in SharedPreferences
   - Handle fetch errors gracefully

3. Add refresh capability
   - Manual refresh button in model dropdown
   - Clear cache option

4. Test model fetching
   - Test with OpenAI API
   - Test with local endpoint
   - Test offline/error scenarios

---

### Phase 5: Prompt Customization UI

1. Complete prompt configuration UI
   - Term translation prompt: enable/disable toggle, textarea, placeholders hint
   - Sentence translation prompt: enable/disable toggle, textarea, placeholders hint

2. Add placeholder hints
   - Show available placeholders: `[term]`, `[sentence]`, `[language]`
   - Provide examples in tooltips

3. Add default template restoration
   - Button to reset to default template
   - Confirm dialog before reset

4. Test prompt templates
   - Test with various inputs
   - Test placeholder replacement
   - Test custom prompts

---

### Phase 6: Reader Integration

1. Add TTS controls to sentence reader
   - Play/pause button for each sentence
   - Stop button
   - Visual feedback when playing

2. Add term translation via AI
   - Translate button in term tooltip
   - Display translation result
   - Loading state during AI call

3. Add sentence translation via AI
   - Translate button in sentence reader
   - Display translation inline or in dialog
   - Loading state during AI call

4. Error handling
   - Clear error messages for failed AI/TTS calls
   - Retry mechanism
   - Fallback to "none" provider on critical errors

5. End-to-end testing
   - Test complete flow: settings → reader → TTS/AI usage
   - Test with all provider options
   - Test with different languages

---

## Key Design Decisions

### 1. Provider Config Pattern
- Store configs keyed by provider enum in a Map
- Each provider has its own isolated settings
- Easy to add new providers without changing data structure

### 2. Service Factory Pattern
- Single `ttsServiceProvider` that returns correct implementation based on settings
- Single `aiServiceProvider` that returns correct implementation based on settings
- Consumers don't need to know which provider is active
- Easy to switch providers at runtime

### 3. Prompt System
- Default templates provided for both prompt types
- Users can override with custom prompts
- Placeholders: `[term]`, `[sentence]`, `[language]`
- Stored per prompt type, can be enabled/disabled independently
- Same model for all AI operations (no per-prompt model)

### 4. Model Fetching Strategy
- On-demand fetching (when user clicks model selector)
- NOT auto-fetched on app startup
- Cached in SharedPreferences to avoid repeated calls
- Fetches from `/v1/models` endpoint
- Manual refresh button available

### 5. State Management
- Use Riverpod Notifiers for all settings
- Separate providers for TTS and AI settings
- Watch-based reactivity for service factory
- SharedPreferences for persistence

### 6. Error Handling
- Graceful degradation if provider fails
- Clear error messages in UI
- Fallback to "none" provider on critical errors
- Retry mechanisms for network failures

---

## Dependencies (Already in pubspec.yaml)

- `flutter_tts: ^4.0.2` - On-device TTS
- `audioplayers: ^6.5.1` - Audio playback
- `openai_dart: ^0.6.2` - OpenAI API integration
- `dio: ^5.9.0` - HTTP client for local endpoints
- `flutter_riverpod: ^3.0.3` - State management
- `shared_preferences: ^2.2.3` - Settings persistence

---

## API Endpoints Required

### OpenAI-compatible Endpoints

#### `/v1/chat/completions`
- Used for AI completions (term/sentence translation)
- Standard OpenAI Chat Completions API format
- Both OpenAI and local-OpenAI endpoints must support this

#### `/v1/models`
- Used to fetch available models
- Returns list of model IDs
- Both OpenAI and local-OpenAI endpoints must support this

#### `/v1/audio/speech` (for OpenAI TTS)
- Used for OpenAI TTS
- Generates audio from text
- OpenAI official endpoint only

#### Local TTS Endpoint (for local-OpenAI TTS)
- Should be OpenAI-compatible or custom format
- Endpoint URL configurable in settings

---

## Testing Checklist

### Phase 1 (Foundation)
- [ ] Data models created and compile
- [ ] Settings providers persist and load correctly
- [ ] UI sections display in settings screen
- [ ] Provider dropdowns work
- [ ] Settings are saved to SharedPreferences

### Phase 2 (TTS)
- [ ] On-device TTS works with voice/rate/pitch/volume
- [ ] OpenAI TTS generates and plays audio
- [ ] Local-OpenAI TTS works with custom endpoint
- [ ] Switching providers works at runtime
- [ ] TTS controls in reader function correctly

### Phase 3 (AI Service)
- [ ] OpenAI service translates terms correctly
- [ ] OpenAI service translates sentences correctly
- [ ] Local-OpenAI service works with custom endpoint
- [ ] Prompt templates apply correctly
- [ ] Placeholder replacement works for all three types

### Phase 4 (Model Fetching)
- [ ] Model fetching works on-tap
- [ ] Models display correctly in dropdown
- [ ] Models are cached in SharedPreferences
- [ ] Refresh button works
- [ ] Errors are handled gracefully

### Phase 5 (Prompt Customization)
- [ ] Custom prompts save and load correctly
- [ ] Enable/disable toggles work
- [ ] Default template restoration works
- [ ] Placeholders are documented with examples

### Phase 6 (Reader Integration)
- [ ] TTS works for sentence playback
- [ ] Term translation via AI works
- [ ] Sentence translation via AI works
- [ ] Loading states display correctly
- [ ] Error messages are clear
- [ ] All providers work end-to-end

---

## Notes

- This plan focuses on ground work (Phase 1) for now
- Future phases will be implemented incrementally
- Design is flexible to add new providers (TTS/AI) and prompt types
- All settings are persisted, so users don't lose configuration
- UI follows existing app patterns (Cards, sliders, dropdowns)
