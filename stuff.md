- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main


Change opacity for termlist

Reader not remembering book between app launches

The bookcard status bar needs to recompute the values to take into account that we aren't showing status98 terms anymore. 

Green checkmark appears in the serverurl textbox even if the URL test connection fails. It should only be there if the test passes

The Server URL isn't saving correctly. Every single time I launch the app the server textbox is on the default server. The current settings shows the correct server however

When pressing save settings for the server configuration we should also trigger a connection test, the same exact one triggered by the test connecton button

Add an auto save toggle to the term form. When toggled on this will auto save the term form when clicking out of the form and causing it to close. Cancel should still cancel. The auto save ONLY triggers when the form closes. 

*fixed?
I get this message over and over none stop if I don't have a book selected for the Reader. Is ther any way to stop this and only have this action run if there is a book active in the reader?
DEBUG SentenceReaderScreen._monitorAndInitialize: isLoading=false, hasPageData=false, _hasInitialized=false
js_primitives.dart:28 DEBUG SentenceReaderScreen._monitorAndInitialize: Waiting for data, will retry...
js_primitives.dart:28 DEBUG SentenceReaderScreen._monitorAndInitialize called


Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.






**Fixed!** The issue was that `ReaderNotifier` was caching the repository reference and never updating it when settings changed.

**The Problem:**
```dart
late ReaderRepository _repository;

@override
ReaderState build() {
  _repository = ref.read(readerRepositoryProvider);  // ← Set once, never updated!
  return const ReaderState();
}
```

When `apiServiceProvider` recreated with the correct server URL after settings loaded, the provider chain updated, but the notifier still used the **old repository** with the **old ApiService** (empty baseUrl).

**The Fix:**
```dart
@override
ReaderState build() {
  ref.watch(readerRepositoryProvider);  // ← Watch for changes
  return const ReaderState();
}

ReaderRepository get _repository => ref.read(readerRepositoryProvider);  // ← Get fresh each time
```

Now:
1. Settings load from storage with correct URL
2. `apiServiceProvider` watches settings, recreates ApiService with correct URL  
3. `contentServiceProvider` watches `apiServiceProvider`, recreates with new ApiService
4. `readerRepositoryProvider` watches `contentServiceProvider`, recreates with new service
5. `ReaderNotifier` watches `readerRepositoryProvider`, gets notified
6. Each call to `_repository` getter fetches the **new** repository with correct ApiService

Run the app again and tap a book - it should now work correctly!
