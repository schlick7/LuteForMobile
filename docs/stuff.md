- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main



# Terms Screen
- Use Termform for term editing

lazy loading?

## Add page turn animation? - First attempt broke hard!

add readme

TTS options: On device, local-OpenAI endpoint, OpenAI, None
  - unique settings for each option
AI options: local-OpenAI endpoint, OpenAI, None, others in the future.
  - support auto model fetching
  - unique settings for each option

edge case? upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Maybe fixed? When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences

Add next page preload to ReaderScreen

Make parent chips horizontal scrollable


Add more custom theme options
  - have custom open up a window?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
  - status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 


  make the text weight slider smart and only show options available for that font family



Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
