- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
Lets do a performance review of this app starting with the ReadScreen 



Look at flutter logs and cleanup issues

Hive cache affected by termuxurl and localurl usage?



---

https://wiki.termux.com/wiki/Main_Page
https://github.com/termux/termux-packages/wiki/Mirrors
https://github.com/termux/termux-tools/tree/master/mirrors

---
 
Can we use the PWA that we have to handle backup and restore on our local (not on device) server?

# Termux
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.
- What happens if f-droid is not installed?
  - add a shortcut to install it?


# Requests 
 
# Reader
- Can we make the tooltips appear instantly (after 100ms or ) and then make a doubleclick action (or really any action) close the tooltip so it doesn't get in the way? This would make the tooltips appear much faster and independent of the doubclick timeout. We just need to be careful that the tooltip displaying doesn't break the doubleclick

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
- 


edge case? upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Maybe fixed? When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences


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
