- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
Lets do a performance review of this app starting with the ReadScreen 


done? Why does pressing "Start Server" cause a recheck of all the connection statuses?

Fixed?? investigate why we are making the server do several auto backups a day. There seems to be one that runs literally everytime we open the app but the server is only supposed to be doing it once per day. Lets see what we're doing wrong

Look at flutter logs and cleanup issues

Hive cache affected by termuxurl and localurl usage?

Don't fucking increase timeout. That just makes launching the app take FOREVER

I'm having an issue with our termux stealth launch. Sometimes when i open the app it opens up termux. other times it doesn't and goes straight to our app. Then it goes straight to our app I can see termux breifly in my notification drawer but then it disappears. Review what we are doing and make sure that we are using Termux and android systems correctly\


---

https://wiki.termux.com/wiki/Main_Page
https://github.com/termux/termux-packages/wiki/Mirrors
https://github.com/termux/termux-tools/tree/master/mirrors

---
 
Can we use the PWA that we have to handle backup and restore on our local (not on device) server?

# Termux
- Lets work in the settings Termux integration termux backups. Add the ability to "restore" a backup. This is only for the termux server. This means that we need to transfer a db file of the users choosing to the correct lute3 directory and overrite the current db file. We should ask the user if they want to create a backup first before restoring. If yes create the backup first and when finished continue the process, If no then just continue the process. 
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.
  - We for sure need to be able to trigger db backups and then be able to download/save the db to a local folder (like downloads) and to upload/restore/overwrite the db file to the termux install location. We can possibly just use the lute3 backup/restore functionality for this. 
  - Does the db file contain EVERYTHING that we need?
- What happens if f-droid is not installed?
  - add a shortcut to install it?
- Cleanup External Apps popup
- When we download backups can we rename them to add 'termux' to the front if they came from termux and 'localurl' if they came from the localurl server
- When the Server Selection is set to termux we should gray out the text in teh LocalUrl textbox to make it clear that its not being used currently. We should also update the Current Settings card to make it clear that it is set to termux. 
---
The auto backups are triggering constantly instead of the server doing it on its once a day setting
---
- When the app is opened we should somehow make sure that the backup system is triggered. Not a manual backup. The way the current Lute Webpage works is that when you open it for the first time that day it somehow triggers a backup to run. Our app never triggers that. Look into the @lute-v3 code and find out what is triggering this. 

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
