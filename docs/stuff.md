- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main


When opening sentencereader the status highlights are still not being updated. no matter how many times I open or close it. The only thing that works is that i need to change the status of any term on the sentencereader. then i can close it and make any changes i want on the readerscreen and they are shown correctly on the sentencereader when i load in. What is causing this weird issue? is the status function not being initialized until a edit a term in the sentencereader? 

Edge Case? After changing Server - When I open the sentence reader for the first time on a new book it says 'no sentence available' and 'no terms in this sentence'

Edge Case? auto save on close only works when i click a way if I first press the close button. from then on a can click away and it works everytime, its like it doesn't activate until i press the actual close button

Change opacity for termlist

Reader not remembering book between app launches

lazy loading?

Remove the ability to close the term form with a downward swipe when the dictionary is open. It is making it so i can't scroll the webviews. 

make swipe to turn page work on the termslist as well. 

can the server handle async requests for tooltips?

termlist chips don't handle multiple parents well

On the termform add longpress on the termlabel to open a popup and have a textbox to edit the term text. popup has save and cancel buttons. Make sure this can not be saved without pressing save. We can not allow the user to change the number of characters in the term. The ONLY thing allow is to change the capitalization of the letters, thats it. Save should only be allowed if it follows all of these rules! 'This to this' and 'this to THIs' is ok. 'this to thi' or 'this to thiss' is NOT ok

##
we need to make sure that the dictionary/webview has vertical scrolling/swiping abilities. 
 We NEED vertical scrolling to work in the webview. 
When we close the dictionary we want to be able to swipe the termform modal away again. Is this possible?
##

When changing the serverurl we need to flush the saved bookid in the reader and navigate to the books screen so the user can choice their book to read

Mouse scroll works in browser for webdictionary, but it doesn't work in the android webviews. 

Fixed? the ONLY thing that we should do when we know the phone has woken from sleep (however it is we know that) so it make 1 fetch to the sever for the books metadata to make sure that the servers current pagenum matchs the page that the reader is on. if they match to NOTHING. if they DON'T match than trigger a navigation to goto the page that the server is on

upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parse doesn't pull them in if its at a new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Add back the add parent button to the termform with dictionary open and parents toggled on. 

Why are we showing(saving?!??) current bookid in the 'Current Settings' display

Add a space between translation textbox newlines. 

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
