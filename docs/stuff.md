- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main




lazy loading?

## Add page turn animation? - First attempt broke hard!

Fixed? the ONLY thing that we should do when we know the phone has woken from sleep (however it is we know that) is to it make 1 fetch to the sever for the books metadata to make sure that the servers current pagenum matchs the page that the reader is on. if they match to NOTHING. if they DON'T match than trigger a navigation to goto the page that the server is on

edge case? upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Maybe fixed? When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences




Add more custom theme options
  - have custom open up a popup?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
    

status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 




Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
