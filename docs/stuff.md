- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main



# Terms Screen
- Use Termform for term editing

lazy loading?

## Add page turn animation? - First attempt broke hard!

add readme

TTS options: On device, local-OpenAI endpoint, OpenAI endpoint
  - unique settings for each option
AI options: local-OpenAI endpoint, OpenAI, others in the future.
  - support auto model fetching
  - unique settings for each option

edge case? upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Maybe fixed? When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences

Add next page preload to ReaderScreen


Fullscreen Mode for ReaderScreen
- embed page buttons at the bottom of the text body. 
- hide top/bottom bar unless at the top of the screen
  - Triggers when close and then opens with a 2 second time and then closes
  

Make parent chips horizontal scrollable

Lets add a 3rd theme. Make theme 'Black and White device' with proper colors that will look good on a black and white screen. Lets start from the light theme and edit from there. The background should be pure white. and then we need two find 2 text colors that work together, one for the normal text and then one for the status 0 text. Then we need a nice dark to light highlight gradient going from status 1 (darkest) to status 5 (lightest)

Add more custom theme options
  - have custom open up a popup?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
  - status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 


  make the text weight slider smart and only show options available for that font family



Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
