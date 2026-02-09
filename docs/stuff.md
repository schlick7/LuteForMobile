- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
  
  
  
  
Lets do a performance review of this app starting with the ReadScreen 

Look at flutter logs and cleanup issues


If i change the severselection to termux the server only starts temporarily and then shuts down. I think this is because the silent notification is never created maybe? but it works no problem if i go over to the termux integration and press the start server button. Whats is happening different? isn't all of the server launch supposed to be the same process??? Research this please. 


I still don't think we're completely clearly and refreshing everything on a server change. On a fresh install the stats and terms screen don't work unless i do an entire app restart after adding the localurl. Maybe we need to force and entire app restart?


fix backup location after restore
/data/data/com.termux/files/home/.local/share/Lute3/backups

---

https://wiki.termux.com/wiki/Main_Page
https://github.com/termux/termux-packages/wiki/Mirrors
https://github.com/termux/termux-tools/tree/master/mirrors

---
 
Can we use the PWA that we have to handle backup and restore on our local (not on device) server?

# Termux
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.

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
- 

# Statistics Screen  
- 

# Help Screen
- Triple tap
- Termux 



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
