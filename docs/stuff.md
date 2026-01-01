- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main


When opening sentencereader the status highlights are still not being updated. no matter how many times I open or close it. The only thing that works is that i need to change the status of any term on the sentencereader. then i can close it and make any changes i want on the readerscreen and they are shown correctly on the sentencereader when i load in. What is causing this weird issue? is the status function not being initialized until a edit a term in the sentencereader? 

Edge Case? After changing Server - When I open the sentence reader for the first time on a new book it says 'no sentence available' and 'no terms in this sentence'

Change opacity for termlist

Reader not remembering book between app launches

lazy loading?

are we reparsing the entire sentence on status change?

make sure that ontap isn't using cached data

can the server handle async requests for tooltips?

The Server URL isn't saving correctly. Every single time I launch the app the server textbox is on the default server. The current settings shows the correct server however








Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
