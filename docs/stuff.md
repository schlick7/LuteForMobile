- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main


Edge Case? auto save on close only works when i click away if I first press the close button. from then on a can click away and it works everytime, its like it doesn't activate until i press the actual close button

Change opacity for termlist

lazy loading?

Add page turn animation? - First attempt broke hard!

can the server handle async requests for tooltips?

On the termform lets add longpress on the termlabel to open a popup and have a textbox to edit the term text. popup has save and cancel buttons. Make sure this can not be saved without pressing save. We can not allow the user to change the number of characters in the term. The ONLY thing allowed is to change the capitalization of the letters, thats it. Save should only be allowed if it follows all of these rules! 'This to this' and 'this to THIs' is ok. 'this to thi' or 'this to thiss' is NOT ok

Fixed? the ONLY thing that we should do when we know the phone has woken from sleep (however it is we know that) is to it make 1 fetch to the sever for the books metadata to make sure that the servers current pagenum matchs the page that the reader is on. if they match to NOTHING. if they DON'T match than trigger a navigation to goto the page that the server is on

upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences

Add more custom theme options
  - have custom open up a popup?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
    
Themes for colorblind?
    
status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 




Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
