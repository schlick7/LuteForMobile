- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

fixed? Pretty sure we had an old bug creap back in. We seem to be overwhelming the server when refreshing the books. screen. it is supposed to be doing a quick fetch of the bookstable with the calc sample at the server setting of 5pages in case any of the book is stale. And then once that is complete we change the calc sample size to what is used in the 500samplesize method and then mark all as stale, and then add them all to a queue and recalculate them. What i am pretty sure is happening is that both those things run in parallel which is causing all the books to recalc at the exact same time at the 500samplesize setting which overwhelms the server. Do some research


Why the fuck do we check if the book has audio EVERY page turn!?! we only need to set this value exactly once when we save the selected book to currentbook. The book can never magically gets audio, it either has it or doesn't have it so we can do this check once and then save it. 




Why doesn't the autobackup ever fucking trigger???

I still don't think we're completely clearing and refreshing everything on a server change. On a fresh install the stats and terms screen don't work unless i do an entire app restart after adding the localurl. Maybe we need to force and entire app restart?



fix backup location after restore
/data/data/com.termux/files/home/.local/share/Lute3/backups


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
- Needs to default to off/none

# AI
- 

# Books Screen
- 

# Terms Screen
- 

# Statistics Screen  
- 

# Help Screen
- Tooltip batch size



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
