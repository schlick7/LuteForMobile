- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
  
Lets do a performance review of this app starting with the ReadScreen 

Look at flutter logs and cleanup issues


Are we still doing http request to homepage on app launch after the server is confirmed connected? we need to do this so the server backups can trigger correctly. 

If i change the seversecltion to termux the server only stats temporarily and then shuts down. I think this is because the silent notification is never created maybe? but it works no problem if i go over to the termux integration and press the start server button. Whats is happening different? isn't all of the server launch supposed to be the same process??? Research this please. 

When we prefetch tooltips why does it rebuild the textdisplay everysingle time?? And why is it make 2 fetches of the exact samething? seems like we have a duplicate issues. logs: 02-04 20:12:59.339 27200 27200 I flutter : API RESPONSE: GET http://192.168.1.152:5001/read/termpopup/23793 - 200
02-04 20:12:59.339 27200 27200 I flutter : API RESPONSE: GET http://192.168.1.152:5001/read/termpopup/23793 - 200
02-04 20:12:59.339 27200 27200 I flutter : HTML Parser: Paragraph innerHtml: "to come, come over"
02-04 20:12:59.339 27200 27200 I flutter : HTML Parser: Final translation: "to come, come over"
02-04 20:12:59.340 27200 27200 I flutter : HTML Parser: Paragraph innerHtml: "to come, come over"
02-04 20:12:59.340 27200 27200 I flutter : HTML Parser: Final translation: "to come, come over"
02-04 20:12:59.340 27200 27200 I flutter : API REQUEST: GET http://192.168.1.152:5001/read/termpopup/23793
02-04 20:12:59.340 27200 27200 I flutter : API REQUEST: GET http://192.168.1.152:5001/read/termpopup/23793
02-04 20:12:59.345 27200 27200 I flutter : DEBUG: ReaderScreen.build - pageData=54
02-04 20:12:59.345 27200 27200 I flutter : DEBUG: TextDisplay rebuild #174 (paragraphs: 42)


Are we preloading pages on the readscreen without the readscreen being the active screen? if so can we stop that?


---

https://wiki.termux.com/wiki/Main_Page
https://github.com/termux/termux-packages/wiki/Mirrors
https://github.com/termux/termux-tools/tree/master/mirrors

---
 
Can we use the PWA that we have to handle backup and restore on our local (not on device) server?

# Termux
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.


# Requests 
 
# Reader
- Disable swipe navigation by default. 

# Sentence Reader
-

# TTS
- 

# AI
- 

# Books Screen
- Why isn't the page number on the book cards updating?
- Add a settings toggle to "Always Refresh for Book Details" default to on. Then we need to hook up the code so that it always triggers that bookstats500pagesample

# Terms Screen
- Default to currentbook languages. Used to do this?

# Statistics Screen  
- Default language to that of currentbook

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
