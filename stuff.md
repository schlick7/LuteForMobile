- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main

Reader page turns aren't saving?

Audio player support in Reader
- add/fix rest of controls

toggling audio player makes the reader book go away. navigating back to books shows no books available until i manually f5

Why does settings rebuild so often? and when it rebuilds why does it keep making shit disappear? Is it setting things to null? if so, why?

The problem:** When `settingsProvider` updates, the provider chain triggers a rebuild:
- `apiServiceProvider` watches `settingsProvider` → rebuilds
- `contentServiceProvider` watches `apiServiceProvider` → rebuilds  
- `readerRepositoryProvider` watches `contentServiceProvider` → rebuilds
- `ReaderNotifier.build()` watches `readerRepositoryProvider` → **CALLED**
- This returns `const ReaderState()` → **everything resets to null**

The `ReaderNotifier.build()` is being called and returning a fresh state, wiping out `pageData`!