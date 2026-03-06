- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

I want a New theme button in the theme selection. I want this to open a window to add a theme. With the ability to prefill the options from a current theme or start from completely scratch. We want Examples of each theme option next to the color value (add a color picker as well). Does the theme plans cover this? 

All terms status themes(0,1,2,3,4,5,98,99) should support either text,background, or none. whichever the theme creator wants. Opacity is fully controlled by the theme as well for the status colors. 0% opacity should be considered hidden in reader, but there are a few places (like stats screen) that will need to still show these

Is the alpha for terms statuses still hardcoded? if not is the proper themes updated with the transparency instead?

Change the color picker to same type of better color selected so users can pick on a "map" this should include a slider for opacity. Show the selected colors hex value still

# Termux
- We want an easy way for Users to download/update the lute3 files so that they can sync them with other servers.
  - no idea how without creating a "micro service"

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
- done? gemini

# Books Screen
- 

# Terms Screen
- 
 
# Statistics Screen  
- 

# Help Screen
- Can't copy text

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
