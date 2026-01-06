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
      'Using the sentence "[sentence]" Translate only the following term from [language] to English: [term]. Respond with the 2 most common translations',
    AIPromptType.sentenceTranslation:
      'Translate the following sentence from [language] to English: [sentence]',
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

#### Reader Integration
- Add TTS button to sentence reader
- Add AI tab to term dictionary (only visible when AI provider != 'None' AND term translation toggle is ON)
  - Fetches translation only when AI tab is opened
  - Caches translation to avoid re-fetch
- Add sentence translation via AI in sentence reader (button only visible when AI provider != 'None' AND sentence translation toggle is ON)
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
**Status**: COMPLETE ✅

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
   - Placeholder fetch logic (to be implemented in Part 2)

7. Create Kokoro voice chips widget
   - Display voices as chips with weights
   - Show mixing arrows when voices.length > 1
   - Add/edit/remove voice functionality
   - Generate voice mix string in "af_bella(2)+af_sky(1)" format

---

## PART 1: Complete TTS Implementation
**Status**: Part 1, Phase 3 (Next Phase)

**Goal**: Implement all TTS functionality end-to-end including services, settings UI, and reader integration

### Part 1, Phase 1: TTS Service Implementation

1. Implement `OnDeviceTTSService`
   - Voice selection from flutter_tts
   - Rate, pitch, volume controls
   - Language setting
   - Stop functionality
   - Get available voices functionality

2. Implement `KokoroTTSService`
   - Use dio to call Kokoro-FastAPI endpoint
   - Call `/v1/audio/speech` with model="kokoro"
   - Support voice mixing with weights
   - Always use mp3 format
   - Implement `/v1/audio/voices` endpoint fetching
   - Generate voice mix string from List<KokoroVoiceWeight>
   - Play audio via audioplayers
   - Stop functionality
   - Get available voices functionality
   - Handle API errors with user-friendly messages

3. Implement `OpenAITTSService`
   - Use openai_dart to generate speech
   - Play generated audio via audioplayers
   - Stop functionality
   - Get available voices functionality
   - Handle API errors with user-friendly messages

4. Implement `LocalOpenAITTSService`
   - Use dio to call local endpoint
   - OpenAI-compatible API calls (`/v1/audio/speech`)
   - Play audio via audioplayers
   - Stop functionality
   - Get available voices functionality
   - Handle API errors with user-friendly messages

5. Complete `NoTTSService`
   - No-op implementations for all methods
   - Return early with logged warnings

6. Testing Checklist - Part 1, Phase 1
    - [ ] On-device TTS works with voice/rate/pitch/volume settings
    - [ ] KokoroTTS generates and plays audio with correct voice/format/speed
    - [ ] KokoroTTS voice mixing with weights works correctly
    - [ ] KokoroTTS voice mix string generated in "af_bella(2)+af_sky(1)" format
    - [ ] KokoroTTS fetches available voices from /v1/audio/voices endpoint
    - [ ] OpenAI TTS generates and plays audio correctly
    - [ ] Local-OpenAI TTS works with custom endpoint
    - [ ] All TTS services handle errors gracefully

---

### Part 1, Phase 2: TTS Settings UI

1. Enhance `KokoroVoiceChips` widget
   - Implement "Add Voice" button that fetches available voices from `/v1/audio/voices`
   - **Validate: Prevent adding 3rd voice (2-voice maximum limit)**
   - Show error message when limit reached: "Maximum 2 voices allowed for mixing"
   - Disable "Add Voice" button when at limit
   - Edit weight dialog with input validation (1-10 range)
   - Remove voice (X button on chip)
   - Show mixing arrows (→) when voices.length > 1
   - Display chips with weights in format: `af_bella(2)` or `af_bella`

2. Update TTS Settings UI
   - Add "Test Speech" button for each provider
   - Show loading state during audio generation/playback
   - Display error messages inline
   - Verify all settings persist correctly
   - Ensure UI updates when settings change

3. Connect TTS settings to services
   - Update `ttsServiceProvider` factory to use real implementations
   - Ensure service updates when settings change
   - Apply settings changes at runtime

4. Testing Checklist - Part 1, Phase 2
    - [ ] KokoroTTS voice chips UI displays correctly
    - [ ] KokoroTTS mixing arrows show when voices.length > 1
    - [ ] KokoroTTS **2-voice limit enforced** (cannot add 3rd voice)
    - [ ] KokoroTTS "Add Voice" button disabled when at limit
    - [ ] KokoroTTS error message shown when trying to add 3rd voice
    - [ ] KokoroTTS add/edit/remove voice functions work
    - [ ] Test Speech button works for all TTS providers
    - [ ] Loading states display correctly
    - [ ] Error handling displays user-friendly messages
    - [ ] Settings persist correctly across app restarts

---

### Part 1, Phase 3: TTS Reader Integration

1. Add TTS to Sentence Reader
   - Add TTS button to sentence reader (play/pause toggle)
   - Visual feedback when playing (icon animation or color change)
   - Stop TTS when navigating away from sentence
   - Stop TTS when switching sentences
   - Don't need to enforce a language as the langue is set automatically by the voice

2. Error handling and retry for TTS
   - Clear error messages for failed TTS calls
   - Retry mechanism (automatic or manual)
   - Fallback to "none" provider on critical errors after N retries
   - User-friendly error messages with actionable next steps

 3. Testing Checklist - Part 1, Phase 3 - COMPLETED ✅
     - [x] TTS button in sentence reader works correctly
     - [x] TTS controls (play/pause) work correctly
     - [x] TTS visual feedback displays correctly
     - [x] TTS stops when navigating away from sentence
     - [x] TTS stops when switching sentences
     - [x] TTS respects current language settings
     - [x] TTS error handling is user-friendly
     - [x] TTS retry mechanism works
     - [ ] TTS fallback to "none" works on critical errors (fallback logic exists but UI integration not added)

---

### Part 1, Phase 4: TTS TermForm integration COMPLETED ✅
1. Add TTS to term form
  - button to the right of the term label
  - Reads only term name
  - Doesn't need stop or pause - no other controls
  
---

### Part 1, Phase 5: TTS page in sentence dictionary COMPLETED ✅
1. Add TTS to SentenceTranslation dictionary
  - Add a button to the right of the 'Orginal' label. 

___

### Part 1, Phase 6: End-to-End TTS Testing

1. Comprehensive TTS testing
   - Test complete flow: settings → reader → TTS usage
   - Test with all TTS provider options (onDevice✅, kokoroTTS✅, OpenAI, local-OpenAI, none)
   - Test with different languages ✅
   - Test switching between providers at runtime ✅
   - Test all provider-specific settings

2. Edge case testing
   - Test TTS with very long sentences
   - Test TTS with special characters
   - Test TTS with empty text
   - Test TTS when network is unavailable
   - Test TTS with invalid API keys
   - Test TTS with invalid endpoint URLs

3. Testing Checklist - Part 1, Phase 4
    - [ ] Complete end-to-end flow: settings → reader → TTS usage works
    - [ ] All TTS provider options work correctly
    - [ ] Switching TTS providers at runtime works
    - [ ] Different languages work correctly with TTS
    - [ ] All provider-specific settings apply correctly
    - [ ] TTS handles long sentences correctly
    - [ ] TTS handles special characters correctly
    - [ ] TTS handles empty text gracefully
    - [ ] TTS handles network unavailability gracefully
    - [ ] TTS handles invalid API keys gracefully
    - [ ] TTS handles invalid endpoint URLs gracefully

---

## PART 2: Complete AI Implementation
**Status**: Part 2, Phase 4 (Next Phase)

**Goal**: Implement all AI functionality end-to-end including services, model fetching, prompt customization, and reader integration

### Part 2, Phase 1: AI Service Implementation

1. Implement `OpenAIService`
   - `translateTerm(String term, String language)` method
   - `translateSentence(String sentence, String language)` method
   - `fetchAvailableModels()` method using openai_dart
   - `getPromptForType(AIPromptType type)` to load custom or default prompts
   - Placeholder replacement logic: `[term]`, `[sentence]`, `[language]`
   - Handle API errors with user-friendly messages

2. Implement `LocalOpenAIService`
   - Same methods as OpenAIService
   - Use dio to call local endpoint
   - OpenAI-compatible API calls:
     - `/v1/chat/completions` for translations
     - `/v1/models` for model fetching
   - Handle API errors with user-friendly messages

3. Implement `NoAIService`
   - No-op implementations for all methods
   - Return early with logged warnings

4. Testing Checklist - Part 2, Phase 1
    - [ ] OpenAI service translates terms correctly
    - [ ] OpenAI service translates sentences correctly
    - [ ] Local-OpenAI service works with custom endpoint
    - [ ] Prompt templates apply correctly
    - [ ] Placeholder replacement works for all three types: `[term]`, `[sentence]`, `[language]`
    - [ ] All AI services handle errors gracefully

---

### Part 2, Phase 2: Model Fetching - COMPLETE ✅

1. Implement model fetching
   - `fetchAvailableModels()` calls `/v1/models` endpoint ✅
   - Cache models in SharedPreferences to avoid repeated calls ✅
   - On-demand fetching (when user clicks refresh, not on startup) ✅
   - Handle offline/error scenarios gracefully ✅

2. Enhance `ModelSelector` widget
   - On-tap refresh button fetches models from current AI provider ✅
   - Show loading indicator during fetch ✅
   - Display fetched models in dropdown ✅
   - Display error message on fetch failure ✅
   - Cache models in SharedPreferences ✅
   - Manual refresh button ✅

3. Complete `AISettingsSection` widget
   - Model selector for OpenAI and local-OpenAI providers ✅
   - Ensure model selector integrates with provider-specific configs ✅

4. Testing Checklist - Part 2, Phase 2 - COMPLETE ✅
     - [x] Model fetching works on-refresh
     - [x] Models display correctly in dropdown
     - [x] Models are cached in SharedPreferences
     - [x] Refresh button works
     - [x] Errors are handled gracefully for model fetching
     - [x] Model selector integrates correctly with AI settings

---

### Part 2, Phase 3: Prompt Customization - COMPLETE ✅

1. Complete prompt configuration UI
   - Term translation prompt section:
     - Enable/disable toggle
     - Textarea for custom prompt
     - Placeholders hint: `[term]`, `[language]`, '[sentence]',
     - Example tooltip
   - Sentence translation prompt section:
     - Enable/disable toggle
     - Textarea for custom prompt
     - Placeholders hint: `[sentence]`, `[language]`
     - Example tooltip

2. Add placeholder hints and tooltips
   - Show available placeholders: `[term]`, `[sentence]`, `[language]`
   - Provide examples in tooltips
   - Document each placeholder's purpose

3. Add default template restoration
   - "Reset to Default" button for each prompt type
   - Confirm dialog before reset
   - Reload default template from `AIPromptTemplates`

4. Implement prompt configuration logic
   - Load custom prompts from SharedPreferences
   - Apply placeholders at runtime (`_replacePlaceholders()`)
   - Handle missing placeholders gracefully (use default values)
   - Persist prompt changes immediately

5. Testing Checklist - Part 2, Phase 3
    - [ ] Custom prompts save and load correctly
    - [ ] Enable/disable toggles work for prompts
    - [ ] Default template restoration works
    - [ ] Placeholders are documented with examples in UI
    - [ ] Prompt changes persist across app restarts

---

### Part 2, Phase 4: AI Reader Integration

1. Add AI tab to longpress Dictionary
    - Add "AI" tab in term dictionary (similar to web dictionaries)
    - AI tab only appears when BOTH: AI provider is NOT set to 'None' AND term translation toggle is ON
    - Lazy loading: translation fetches ONLY when AI tab is opened
    - Loading state during AI call (spinner in tab content)
    - Display translation result in tab content
    - Error handling for failed translations
    - Cache translation result to avoid re-fetching when switching back to AI tab

2. Add sentence translation via AI
    - Add "Translate" button to the left of the TTS button
    - Button only appears when BOTH: AI provider is NOT set to 'None' AND sentence translation toggle is ON
    - Display translation inline below sentence or in dialog
    - Loading state during AI call
    - Error handling for failed translations

3. Error handling and retry for AI
    - Clear error messages for failed AI calls
    - Retry mechanism (automatic or manual)
    - Fallback to "none" provider on critical errors after N retries
    - User-friendly error messages with actionable next steps

4. Testing Checklist - Part 2, Phase 4
     - [ ] AI tab appears only when AI provider != 'None' AND term translation toggle is ON
     - [ ] AI tab is hidden when either AI provider = 'None' OR term translation toggle is OFF
     - [ ] AI tab fetches translation only when opened
     - [ ] AI tab caches translation (no re-fetch on tab switch)
     - [ ] Sentence translation button appears only when AI provider != 'None' AND sentence translation toggle is ON
     - [ ] Sentence translation button is hidden when either condition is not met
     - [ ] Term translation via AI works with all AI providers
     - [ ] Sentence translation via AI works with all AI providers
     - [ ] Loading states display correctly for AI calls
     - [ ] Error messages are clear and actionable
     - [ ] Retry mechanism works for failed AI calls
     - [ ] Fallback to "none" provider works on critical errors

---

### Part 2, Phase 5: End-to-End AI Testing

1. Comprehensive AI testing
   - Test complete flow: settings → reader → AI usage
   - Test with all AI provider options (OpenAI, local-OpenAI, none)
   - Test with different languages
   - Test switching between providers at runtime
   - Test all provider-specific settings
   - Test custom prompts
   - Test model selection

2. Edge case testing
   - Test AI translation with very long text
   - Test AI translation with special characters
   - Test AI translation with empty text
   - Test AI when network is unavailable
   - Test AI with invalid API keys
   - Test AI with invalid endpoint URLs
   - Test AI with missing prompt placeholders

3. Testing Checklist - Part 2, Phase 5
    - [ ] Complete end-to-end flow: settings → reader → AI usage works
    - [ ] All AI provider options work correctly
    - [ ] Switching AI providers at runtime works
    - [ ] Different languages work correctly with AI
    - [ ] All provider-specific settings apply correctly
    - [ ] Custom prompts work correctly
    - [ ] Model selection works correctly
    - [ ] AI handles long text correctly
    - [ ] AI handles special characters correctly
    - [ ] AI handles empty text gracefully
    - [ ] AI handles network unavailability gracefully
    - [ ] AI handles invalid API keys gracefully
    - [ ] AI handles invalid endpoint URLs gracefully
    - [ ] AI handles missing prompt placeholders gracefully

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

## Testing Checklist Summary

### Phase 1 (Foundation) - COMPLETE ✅
- [x] Data models created and compile
- [x] Settings providers persist and load correctly
- [x] UI sections display in settings screen
- [x] Provider dropdowns work
- [x] Settings are saved to SharedPreferences

### Part 1: Complete TTS Implementation

#### Part 1, Phase 1 (TTS Services)
- [ ] On-device TTS works with voice/rate/pitch/volume
- [ ] KokoroTTS generates and plays audio with correct voice/format/speed
- [ ] KokoroTTS voice mixing with weights works correctly
- [ ] KokoroTTS voice mix string generated in "af_bella(2)+af_sky(1)" format
- [ ] KokoroTTS fetches available voices from /v1/audio/voices
- [ ] OpenAI TTS generates and plays audio
- [ ] Local-OpenAI TTS works with custom endpoint
- [ ] All TTS services handle errors gracefully

#### Part 1, Phase 2 (TTS Settings UI) - COMPLETE ✅
- [x] KokoroTTS voice chips UI displays correctly
- [x] KokoroTTS mixing arrows show when voices.length > 1
- [x] KokoroTTS **2-voice limit enforced** (cannot add 3rd voice)
- [x] KokoroTTS "Add Voice" button disabled when at limit
- [x] KokoroTTS error message shown when trying to add 3rd voice
- [x] KokoroTTS add/edit/remove voice functions work
- [x] Test Speech button works for all TTS providers
- [x] Loading states display correctly
- [x] Error handling displays user-friendly messages
- [x] Settings persist correctly

#### Part 1, Phase 3 (TTS Reader Integration) - COMPLETED ✅
- [x] TTS button in sentence reader works correctly
- [x] TTS controls (play/pause/stop) work correctly
- [x] TTS visual feedback displays correctly
- [x] TTS stops when navigating away
- [x] TTS stops when switching sentences
- [x] TTS respects current language settings
- [x] TTS error handling is user-friendly
- [x] TTS retry mechanism works
- [ ] TTS fallback to "none" works (fallback logic exists but UI integration not added)

#### Part 1, Phase 4 (TTS End-to-End Testing)
- [ ] Complete end-to-end flow: settings → reader → TTS usage works
- [ ] All TTS provider options work correctly
- [ ] Switching TTS providers at runtime works
- [ ] Different languages work correctly
- [ ] All provider-specific settings apply correctly
- [ ] TTS handles edge cases (long text, special chars, empty text, network issues)

### Part 2: Complete AI Implementation

#### Part 2, Phase 1 (AI Services)
- [ ] OpenAI service translates terms correctly
- [ ] OpenAI service translates sentences correctly
- [ ] Local-OpenAI service works with custom endpoint
- [ ] Prompt templates apply correctly
- [ ] Placeholder replacement works for all types
- [ ] All AI services handle errors gracefully

#### Part 2, Phase 2 (Model Fetching) - COMPLETE ✅
- [x] Model fetching works on-refresh
- [x] Models display correctly in dropdown
- [x] Models are cached in SharedPreferences
- [x] Refresh button works
- [x] Errors are handled gracefully
- [x] Model selector integrates correctly

#### Part 2, Phase 3 (Prompt Customization) - COMPLETE ✅
- [x] Custom prompts save and load correctly
- [x] Enable/disable toggles work
- [x] Default template restoration works
- [x] Placeholders are documented with examples
- [x] Prompt changes persist

#### Part 2, Phase 4 (AI Reader Integration)
- [ ] AI tab appears only when AI provider != 'None' AND term translation toggle is ON
- [ ] AI tab hidden when either condition is not met
- [ ] AI tab fetches translation only when opened
- [ ] AI tab caches translation (no re-fetch on tab switch)
- [ ] Sentence translation button appears only when AI provider != 'None' AND sentence translation toggle is ON
- [ ] Sentence translation button hidden when either condition is not met
- [ ] Term translation via AI works with all providers
- [ ] Sentence translation via AI works with all providers
- [ ] Loading states display correctly
- [ ] Error messages are clear
- [ ] Retry mechanism works
- [ ] Fallback to "none" works

#### Part 2, Phase 5 (AI End-to-End Testing)
- [ ] Complete end-to-end flow: settings → reader → AI usage works
- [ ] All AI provider options work correctly
- [ ] Switching AI providers at runtime works
- [ ] Different languages work correctly
- [ ] All provider-specific settings apply correctly
- [ ] Custom prompts work correctly
- [ ] Model selection works correctly
- [ ] AI handles edge cases (long text, special chars, empty text, network issues, missing placeholders)

---

## Notes

- This plan focuses on complete TTS implementation (Part 1) after foundation
- Part 2 implements all AI features independently
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
// Streaming can be added in Part 1+ as an enhancement for long texts
```
