- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
  
Update HelpScreen  
  
# Statistics Screen  
- For the Wordcount lets create a Current Day streak and a Longest Day streak stat. any day with a wordcount of 1 or more should count. 

# Terms Screen
-

# Reader
-

# TTS
- Future: add a selector in language settings to apply TTS voices based on languages. 
- Make the audio stopable. Don't need pause. Just play and stop. 

# AI
- Add 'virtual' sentence dictionary to SentenceDictionary popup. 

# Sentence Reader
- If the book page hasn't changed then open to the last setence read intead of starting at 1

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
- When page marked as done and a popup to navigate to books to pick out another. Add a great job or something and a animation of some kind to celebrate the completetion of a book. Include number of words in the book? 
- add a selector in language settings to apply TTS voices based on languages. 
- add todays read stats to bottom nav bar
