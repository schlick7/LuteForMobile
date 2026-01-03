# TTS and AI Options Implementation Plan

## Overview

Implementation of Text-to-Speech (TTS) and AI features with multiple provider options and custom prompt templates.

## Requirements

### TTS Options
- **On device**: Use flutter_tts package
- **KokoroTTS**: Kokoro-FastAPI local server with OpenAI-compatible TTS API
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
  kokoroTTS,
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
class KokoroVoiceWeight {
  final String voice;
  final int weight;
  const KokoroVoiceWeight({required this.voice, this.weight = 1});
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

  // KokoroTTS settings
  final List<KokoroVoiceWeight>? kokoroVoices; // List of voices with weights for chips UI
  final double? speed; // Playback speed (default 1.0)
  final bool? useStreaming; // Enable streaming for long texts (future enhancement)
  // Audio format: Always mp3 for universal compatibility
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
- Methods: `updateProvider()`, `updateOnDeviceConfig()`, `updateKokoroTTSConfig()`, `updateOpenAIConfig()`, `updateLocalOpenAIConfig()`
- KokoroTTS methods:
  - `addKokoroVoice(String voice, int weight)`
  - `removeKokoroVoice(String voice)`
  - `updateKokoroVoiceWeight(String voice, int weight)`
  - `generateKokoroVoiceString()` - Returns "af_bella(2)+af_sky(1)" format
- Keys: `tts_provider`, `on_device_tts_config`, `kokoro_tts_config`, `openai_tts_config`, `local_openai_tts_config`

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

class KokoroTTSService implements TTSService {
  // Uses dio to call Kokoro-FastAPI endpoint
  // OpenAI-compatible /v1/audio/speech endpoint
  // Supports voice mixing with weights: "af_bella(2)+af_sky(1)"
  // Always uses mp3 format for universal compatibility
  // Default port: 8880, base URL: http://localhost:8880/v1
  // Voices stored as List<KokoroVoiceWeight> for UI chips management
  // Supports streaming (future enhancement for long texts)
  // Currently uses non-streaming for simplicity (sufficient for short texts like sentences)
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
    case TTSProvider.kokoroTTS:
      return KokoroTTSService(
        endpointUrl: config?.endpointUrl ?? 'http://localhost:8880/v1',
        voices: config?.kokoroVoices ?? [],
        audioFormat: 'mp3', // Always mp3 for universal compatibility
        speed: config?.speed ?? 1.0,
      );
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
- Provider dropdown (On device, KokoroTTS, OpenAI, local-OpenAI, None)
- Provider-specific settings panels:
  - **On device**: Voice dropdown, Rate slider, Pitch slider, Volume slider
  - **KokoroTTS**:
    - Endpoint URL field (default: http://localhost:8880/v1)
    - **Voice chips UI**:
      - Display selected voices as chips (e.g., [af_bella])
      - When multiple voices selected, show mixing arrows between chips
      - Example for 2 voices: [af_bella(2)] → [af_sky(1)]
      - Example for 3 voices: [af_bella(2)] → [af_sky(1)] → [am_michael(1)]
      - Tap chip to edit weight (opens weight input dialog)
      - Swipe left/right or tap delete button to remove voice from mix
      - Add voice button shows available voices list from /v1/audio/voices
      - Maximum 2 voices allowed (API limit)
    - **Streaming toggle** (optional - future enhancement):
      - Enable/disable for long texts (books, paragraphs)
      - Default: disabled (use non-streaming for short texts)
      - When enabled: Use `with_streaming_response.create()` for real-time playback
    - Speed slider
  - **OpenAI**: API key field, Model field (e.g., tts-1), Voice field (alloy/echo/fable)
  - **local-OpenAI**: Endpoint URL field, Model field, Voice field, API key field (optional)

#### `lib/features/settings/widgets/kokoro_voice_chips.dart`
- Widget for displaying and managing KokoroTTS voice selection
- State: List of `{voice: String, weight: int}`
- **Constraints**: Maximum 2 voices allowed (API limit based on documentation examples)
- Methods:
  - `addVoice(String voiceName, int weight)` - Validates < 2 voices before adding
  - `removeVoice(String voiceName)`
  - `updateWeight(String voiceName, int newWeight)`
  - `generateVoiceString()` - Returns "af_bella(2)+af_sky(1)" format
- UI behavior:
  - Single voice: `Chip(af_bella)`
  - Multiple voices (2 max): `Chip(af_bella(2)) → Chip(af_sky(1))`
  - Arrow only appears when voices.length > 1
  - Weight shown in parentheses
  - Dismissible chips (swipe or X button)
  - **"Add Voice" button disabled** when voices.length >= 2
  - **Error message** shown when trying to add 3rd voice: "Maximum 2 voices allowed for mixing"

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
│   │       ├── kokoro_voice_chips.dart   # NEW - voice chips with mixing UI
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
   - `TTSSettings`, `TTSSettingsConfig`, `TTSProvider` enum (include kokoroTTS)
   - `AISettings`, `AISettingsConfig`, `AIPromptConfig`, `AIProvider`, `AIPromptType` enums
   - `AIPromptTemplates` with default prompts
   - Modify `Settings` model to add `ttsProvider` and `aiProvider` fields

2. Create service interfaces
   - `TTSService` abstract class with method signatures
   - `AIService` abstract class with method signatures
   - Placeholder implementations (empty/stubs for now)

3. Create provider infrastructure
   - `TTSSettingsNotifier` with SharedPreferences persistence (include kokoroTTS methods)
   - `AISettingsNotifier` with SharedPreferences persistence
   - `ttsServiceProvider` factory (returns placeholder for now)
   - `aiServiceProvider` factory (returns placeholder for now)
   - `aiModelsProvider` FutureProvider for model fetching

4. Add basic UI cards
   - `TTSSettingsSection` with provider dropdown (include KokoroTTS)
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

7. Create Kokoro voice chips widget
   - Display voices as chips with weights
   - Show mixing arrows when voices.length > 1
   - Add/edit/remove voice functionality
   - Generate voice mix string in "af_bella(2)+af_sky(1)" format

---

### Phase 2: TTS Implementation

1. Implement `OnDeviceTTSService`
   - Voice selection from flutter_tts
   - Rate, pitch, volume controls
   - Language setting

2. Implement `KokoroTTSService`
   - Use dio to call Kokoro-FastAPI endpoint
   - Call `/v1/audio/speech` with model="kokoro"
   - Support voice mixing with weights
   - Always use mp3 format
   - Implement `/v1/audio/voices` fetching
   - Generate voice mix string from List<KokoroVoiceWeight>
   - Play audio via audioplayers
   - **Optional**: Implement streaming for long texts (useStreaming flag)
     - Kokoro-FastAPI supports streaming via OpenAI-compatible API
     - Can use `with_streaming_response.create()` for real-time playback
     - Streaming benefits: faster time-to-first-byte, better UX for long texts
   - Handle API errors

3. Implement `KokoroVoiceChips` widget
   - Display selected voices as chips with weights
   - Show mixing arrows (→) when voices.length > 1
   - Add voice button with available voices from `/v1/audio/voices`
   - **Validate: Prevent adding 3rd voice (2-voice maximum limit)**
   - Edit weight dialog
   - Remove voice (swipe or X button)
   - Persist voice list in SharedPreferences

3. Implement `OpenAITTSService`
   - Use openai_dart to generate speech
   - Play generated audio via audioplayers
   - Handle API errors

4. Implement `LocalOpenAITTSService`
   - Use dio to call local endpoint
   - OpenAI-compatible API calls
   - Play audio via audioplayers

5. Connect TTS settings to services
   - Update factory provider to use real implementations
   - Apply settings changes at runtime

6. Add TTS to reader (basic)
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

#### `/v1/audio/speech` (for KokoroTTS)
- OpenAI-compatible TTS endpoint for Kokoro-FastAPI
- Generates audio from text
- Parameters:
  - `model`: "kokoro" (or custom model)
  - `input`: Text to speak
  - `voice`: Voice name or voice mix (e.g., "af_bella", "af_bella(2)+af_sky(1)")
  - `response_format`: Always "mp3" for universal compatibility
  - `speed`: Playback speed (default 1.0)
- Default port: 8880
- No API key required for local instance

#### `/v1/audio/voices` (for KokoroTTS)
- Returns list of available voices
- Example: `{"voices": ["af_bella", "af_sky", "af_heart", "am_michael", "am_adam", ...]}`
- Supports voice mixing with weighted combinations

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
- [ ] KokoroTTS generates and plays audio with correct voice/format/speed
- [ ] KokoroTTS voice chips UI displays correctly
- [ ] KokoroTTS voice mixing with weights works correctly
- [ ] KokoroTTS voice mix string generated in "af_bella(2)+af_sky(1)" format
- [ ] KokoroTTS mixing arrows show when voices.length > 1
- [ ] KokoroTTS **2-voice limit enforced** (cannot add 3rd voice)
- [ ] KokoroTTS "Add Voice" button disabled when at limit
- [ ] KokoroTTS error message shown when trying to add 3rd voice
- [ ] KokoroTTS fetches available voices from /v1/audio/voices
- [ ] KokoroTTS add/edit/remove voice functions work
- [ ] **KokoroTTS streaming support** (optional - future enhancement for long texts)
  - [ ] Streaming toggle in settings
  - [ ] Use `with_streaming_response.create()` for real-time playback
  - [ ] Handle streaming chunks in audio player
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

### KokoroTTS Specific Notes

**Kokoro-FastAPI Integration:**
- Repository: https://github.com/remsky/Kokoro-FastAPI
- OpenAI-compatible TTS API at `/v1/audio/speech`
- Default port: 8880, base URL: `http://localhost:8880/v1`
- No API key required for local instances
- Supports multi-language (English, Japanese, Chinese, Vietnamese coming soon)

**Voice System:**
- Voice names use format: `af_bella`, `af_sky`, `af_heart`, `am_michael`, `am_adam`, etc.
  - `af_*` = American English female
  - `am_*` = American English male
- Supports voice mixing with weights: `"af_bella(2)+af_sky(1)"` = 67%/33% mix
- Weights are automatically normalized to sum to 100%
- Available voices endpoint: `GET /v1/audio/voices`
- **Maximum 2 voices** can be mixed (based on API documentation examples)
- API only shows 2-voice mixing examples in documentation

**Voice Selection UI (Chips):**
- Single voice: `[af_bella]`
- Mixed voices (2 voices max): `[af_bella(2)] → [af_sky(1)]` with mixing arrows
- Mixing arrows (→) only show when voices.length > 1
- Chips show voice weight in parentheses
- Tap chip to edit weight (opens weight input dialog)
- Swipe left/right or tap X to remove voice from mix
- **Validation**: Cannot add 3rd voice - show error "Maximum 2 voices allowed for mixing"
- "Add Voice" button shows all available voices from `/v1/audio/voices` (disabled when at 2 voice limit)
- Voice list shows: af_*, am_* voices (American English, Japanese, Chinese)

**Voice Mix String Generation:**
```dart
String generateKokoroVoiceString(List<KokoroVoiceWeight> voices) {
  if (voices.isEmpty) return '';
  if (voices.length == 1) {
    return voices.first.voice;
  }
  return voices
      .map((v) => '${v.voice}(${v.weight})')
      .join('+');
}

// Examples:
// Single voice: "af_bella"
// Two voices: "af_bella(2)+af_sky(1)"
// Three voices: NOT SUPPORTED - API limit is 2 voices
```

**Validation Logic:**
```dart
// In TTSSettingsNotifier
Future<void> addKokoroVoice(String voice, int weight) async {
  final currentVoices = config.kokoroVoices ?? [];
  
  if (currentVoices.length >= 2) {
    // Show error: "Maximum 2 voices allowed for mixing"
    return;
  }
  
  final newVoices = [...currentVoices, KokoroVoiceWeight(voice: voice, weight: weight)];
  updateKokoroConfig(newVoices);
}

// In KokoroVoiceChips widget - disable add button when limit reached
bool get _canAddVoice => voices.length < 2;
```

**Audio Formats:**
- App always uses mp3 format for universal compatibility
- Reasoning:
  - Works on all platforms (Android, iOS, Web)
  - Supported by all audio players
  - Compatible with oldest to newest devices
  - Reasonable file size and quality
  - No compatibility headaches for users
- Opus considered but rejected due to limited support on older Android versions and some browsers

**Model:**
- Primary model: "kokoro" (based on Kokoro-82M)
- Custom models may be supported if endpoint allows
- No `/models` endpoint like OpenAI (model selection is limited)

**Additional Features:**
- Streaming support for real-time playback
- Natural boundary detection and auto-stitching
- Per-word timestamped caption generation
- Phoneme-based audio generation
- Debug endpoints for monitoring (threads, storage, system stats)

**Setup (for users):**
```bash
# Quick start with Docker
docker run -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:latest
# Or GPU:
docker run --gpus all -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-gpu:latest
```

**Example API Usage:**
```dart
// Using dio
final voices = [
  KokoroVoiceWeight(voice: 'af_bella', weight: 2),
  KokoroVoiceWeight(voice: 'af_sky', weight: 1),
];
final voiceString = generateKokoroVoiceString(voices); // "af_bella(2)+af_sky(1)"

final response = await dio.post(
  'http://localhost:8880/v1/audio/speech',
  data: {
    'model': 'kokoro',
    'input': 'Hello world!',
    'voice': voiceString,  // "af_bella(2)+af_sky(1)" or "af_bella" for single
    'response_format': 'mp3', // Always mp3 for universal compatibility
    'speed': 1.0,
  },
  options: Options(responseType: ResponseType.bytes),
);
// Play audio via audioplayers
```

**Streaming Support (Future Enhancement):**
```dart
// Kokoro-FastAPI supports streaming via OpenAI-compatible API
// Can use for long texts (books, paragraphs) to reduce latency
// Implementation would use:
//   - client.audio.speech.with_streaming_response.create()
//   - Stream chunks to audioplayers or custom audio player
//   - Benefit: Time-to-first-byte ~300ms vs waiting for full audio
//
// Note: For ground work (Phase 1), use simple non-streaming approach
// Streaming can be added in Phase 2+ as an enhancement for long texts
```
