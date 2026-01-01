# Server URL Loading Plan

## Problem
- Server URL loads with empty default first, then async overwrites with saved value
- This causes unnecessary rebuilds and displays "no books loaded" initially
- Only URL needs to change when user saves in settings screen

## Solution: Pre-load ServerURL in main()

### Step 1: Modify `main.dart`
- Add `WidgetsFlutterBinding.ensureInitialized()`
- `await SharedPreferences.getInstance()`
- Load serverUrl: `prefs.getString('server_url') ?? ''`
- Pass via `ProviderScope` override to new provider
- ServerUrl loaded BEFORE any providers are created

### Step 2: Use existing `initialServerUrlProvider` in `initial_providers.dart`
- Provider already exists: `Provider<String>((ref) => ''`
- No async loading, no Notifier
- Will be overridden with pre-loaded value from `main()`

### Step 3: Modify `SettingsNotifier.build()` in `settings_provider.dart`
- Remove `_loadSettings()` call that was causing async cycle
- Read serverUrl from `initialServerUrlProvider` directly (already available)
- Return `Settings.defaultSettings().copyWith(serverUrl: serverUrl, isUrlValid: _isValidUrl(serverUrl))`
- Call `_loadOtherSettingsAsync()` after initial build to load other settings
- Use `state.copyWith()` to update only async-loaded settings (exclude serverUrl to avoid rebuild)

Implementation:
```dart
@override
Settings build() {
  final serverUrl = ref.read(initialServerUrlProvider);
  final settings = Settings.defaultSettings().copyWith(
    serverUrl: serverUrl,
    isUrlValid: _isValidUrl(serverUrl),
  );
  _loadOtherSettingsAsync();
  return settings;
}

Future<void> _loadOtherSettingsAsync() async {
  final prefs = await SharedPreferences.getInstance();
  // Load all settings EXCEPT serverUrl (already loaded sync)
  final translationProvider = prefs.getString(_keyTranslationProvider) ?? 'local';
  final showTags = prefs.getBool(_keyShowTags) ?? true;
  final showLastRead = prefs.getBool(_keyShowLastRead) ?? true;
  final languageFilter = prefs.getString(_keyLanguageFilter);
  final showAudioPlayer = prefs.getBool(_keyShowAudioPlayer) ?? true;
  final currentBookId = prefs.getInt(_keyCurrentBookId);
  final currentBookPage = prefs.getInt(_keyCurrentBookPage);
  final currentBookSentenceIndex = prefs.getInt(_keyCurrentBookSentenceIndex);
  final combineShortSentences = prefs.getInt(_keyCombineShortSentences) ?? 3;
  final showKnownTermsInSentenceReader = prefs.getBool(_keyShowKnownTermsInSentenceReader) ?? true;

  // Update state with only the async-loaded settings (no serverUrl)
  state = state.copyWith(
    translationProvider: translationProvider,
    showTags: showTags,
    showLastRead: showLastRead,
    languageFilter: languageFilter,
    showAudioPlayer: showAudioPlayer,
    currentBookId: currentBookId,
    currentBookPage: currentBookPage,
    currentBookSentenceIndex: currentBookSentenceIndex,
    combineShortSentences: combineShortSentences,
    showKnownTermsInSentenceReader: showKnownTermsInSentenceReader,
  );
}
```

### Step 4: Keep other settings async loading
- Move async loading of other settings to `_loadOtherSettingsAsync()` helper method
- This keeps display prefs, theme settings, etc. loading normally
- Only difference: serverUrl is no longer loaded async, everything else still is
- Use `state.copyWith()` to update state without triggering unnecessary rebuilds

### Step 5: Add app restart when URL changes in settings screen
- Modify `_saveSettings()` in `settings_screen.dart`
- When serverUrl changes, trigger app restart to reload the new URL from SharedPreferences
- This ensures the new URL takes effect immediately on next app launch

## Result
- ServerUrl loaded once in `main()` → available immediately
- No "empty default → async overwrite → rebuild" cycle
- Other settings still load async as before
- Settings provider structure mostly unchanged
- URL only changes when user saves in settings screen (which triggers app restart)

## Why This Works
1. `main()` runs BEFORE `ProviderScope` exists
2. Can await SharedPreferences synchronously
3. Override `initialServerUrlProvider` BEFORE any providers are used
4. When Settings provider builds, serverUrl from `initialServerUrlProvider` is immediately available
5. No async delay for serverUrl - it's ready from the start
6. Other settings load async via `state.copyWith()` which doesn't affect serverUrl
7. `state.copyWith()` avoids the comparison bug from the old `_loadSettings()` approach
