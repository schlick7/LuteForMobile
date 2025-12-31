- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main

add custom button for accent colors



puncuation is appearing a the start of the new sentence instead of at the end of the last sentence, the parser must be set up wrong. 

Don't show ignored(status98) terms in Sentencereader termslist
add toggle under the 'Open Sentence Reader' button to show/hide known (status99) terms in the termslist

In status_colors the ignored(status98) terms should have no color at all. They should just display as normal text with no highlighting

When I open sentence reader on a book for the first time i get now data. I need to press open again for it to load all of the data. 


Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
