- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

fixed? Pretty sure we had an old bug creap back in. We seem to be overwhelming the server when refreshing the books. screen. it is supposed to be doing a quick fetch of the bookstable with the calc sample at the server setting of 5pages in case any of the book is stale. And then once that is complete we change the calc sample size to what is used in the 500samplesize method and then mark all as stale, and then add them all to a queue and recalculate them. What i am pretty sure is happening is that both those things run in parallel which is causing all the books to recalc at the exact same time at the 500samplesize setting which overwhelms the server. Do some research

When i select a book it makes the termscreen show "no terms" and makes the stats screen have an error with a retry button. pressing the retry button makes the stats screen load properly. For the terms screen i need to change the filter and then it loads in correctly. I don't think these are properly reloading when the book gets changed. 

Why doesn't the autobackup ever fucking trigger???

I still don't think we're completely clearing and refreshing everything on a server change. On a fresh install the stats and terms screen don't work unless i do an entire app restart after adding the localurl. Maybe we need to force and entire app restart?

---
statsState` (x2) | ⚠️ **Risky** | Could be intentional to keep provider alive |

## Potential Issue

The `statsState` variables I removed could have been **intentionally watched** to:
1. Keep the stats provider "warm" 
2. Trigger rebuilds when stats change (even if not displayed on that screen)
---

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
- 

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
