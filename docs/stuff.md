- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  
  

# Help Screen
- 

# Statistics Screen  
- 

# Terms Screen
-

# Books Screen
- When i load the bookscreen the books all have stats. But Every time i select a book from the bookscreen and then navigate back to the book the status are cleared, why? We aren't supposed to be ever clearing the cache until the new fetch is succesful. Y

- If the user navigates away during a refresh we need to make sure that we finish fetching the currently refreshing book and then properly set the server page stats back to its previous value. Can we insure this happens? 

- make the 'refresh all stats' button use the new 2books at a time full refresh method

# Reader
- 

# TTS
- 

# AI
- 

# Sentence Reader
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
