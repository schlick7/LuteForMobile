- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
  
? Why did our nice helpful message in the readscreen get replaced by a scary error message? on a fresh install it nows says error serverurl is not configured and theres a retry button. Previously we had a much nicer no server configured screen with a shortcut button to go to settings
  


If swipe navigation is on then starting the app seems to always trigger a page swipe/turn


I still don't think we're completely clearly and refreshing everything on a server change. On a fresh install the stats and terms screen don't work unless i do an entire app restart after adding the localurl. Maybe we need to force and entire app restart?


fix backup location after restore
/data/data/com.termux/files/home/.local/share/Lute3/backups


Make sure release key is set up properly

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
- 

# Sentence Reader
-

# TTS
- 

# AI
- 

# Books Screen
- Add a settings toggle to "Always Refresh for Book Details" default to on. Then we need to hook up the code so that it always triggers that stats500samplesize, it will need to do the same thing that makes the server recalculate the book. The Book details should load from chache first and then refresh when the new data is ready

# Terms Screen
- in the termsscreen Editing a term scrolls to the top when closing the termform. 

# Statistics Screen  
- 

# Help Screen
- Triple tap
- Termux 
- Add note that to restore back to the localurl (server on computer) users will need to overwrite lute.db manually. We should list about default locations of this file. 



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
