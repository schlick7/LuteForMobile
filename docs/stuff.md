- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  




---
1) Partially fixed? When books are archived, they still show up in the normal view. Maybe this has to do with my sync/stats settings, but seems like that should be independent?

---



Why doesn't the autobackup ever fucking trigger???

fix backup location after restore
/data/data/com.termux/files/home/.local/share/Lute3/backups
- We need to save and restore the entire settings page for this


---
https://wiki.termux.com/wiki/Main_Page
https://github.com/termux/termux-packages/wiki/Mirrors
https://github.com/termux/termux-tools/tree/master/mirrors

# Termux
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.
  - no idea how without creating a "micro service"
- Termux never actually shuts down. Stays in the silent notifications with 1 task forever. Can we actually set up a sleep timer? Lets check the termux docs. https://wiki.termux.com/wiki/Main_Page
---

# Requests 

# Settings
- 

# Reader
- fixed? If the Audio player is toggled off we don't need to sync with server every 10 seconds, Samething if we aren't on the readscreen anymore. If it isn't visible we don't need to save/sync. 

# Sentence Reader
-

# TTS
- Needs to default to off/none

# AI
- 

# Books Screen
- 

# Terms Screen
- Add toggle to hide stats card and therby not make the calls for it either. 
- 
# Statistics Screen  
- 

# Help Screen
- Tooltip batch size
- Show known terms issue under performance


# Theme

Add more custom theme options
  - have custom open up a window?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
  - status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 
  - add underline support
    - and dotted underline?




# Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
- add a selector in language settings to apply TTS voices based on languages.
