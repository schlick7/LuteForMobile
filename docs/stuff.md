- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
Lets do a performance review of this app starting with the ReadScreen 

# Termux
- We want the settings to check if termux is installed and if lute3 is installed when switching the connection to termux.
  - if termux is install but lute3 isn't we should show an install button
  - if termux and lute3 are both detected as installed we should show other settings like buttons for start, stop, update and data like lute3 version (if available), termux version (if available)

- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.
  - We for sure need to be able to trigger db backups and then be able to download/save the db to a local folder (like downloads) and to upload/restore/overwrite the db file to the termux install location. We can possibly just use the lute3 backup/restore functionality for this. 
  - Does the db file contain EVERYTHING that we need?


- Some way to trigger backups. 
- When the app is opened we should somehow make sure that the backup system is triggered. Not a manual backup. The way the current Lute Webpage works is that when you open it for the first time that day it somehow triggers a backup to run. Our app never triggers that. Look into the @lute-v3 code and find out what is triggering this. 

# Requests 
 
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
