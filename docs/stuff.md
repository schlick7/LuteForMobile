- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main


Change opacity for termlist

Reader not remembering book between app launches

lazy loading?

are we reparsing the entire sentence on status change?

Add percentage lext to the total of each status amount in book details popup

Remove the decimal from the seconds in the book details popup

?Don't load tooltips for unknown(status98) terms in the sentencereader. Also, don't load known(status99) terms tooltips if the toggle to show known terms is toggled off. 

make sure that ontap isn't using cached data

can the server handle async requests for tooltips?

Reader screen seems to load in then flash blank and then load in again. 

Sentence Reader is calling parsetermtooltip in the normal ReaderScreen before it is every opend and it seems to be doing it for the ENTIRE page. We only want this to get trigger when the sentence reader opens and then we only want it to happen for the first sentence! this is way to much loading data right away

Rename the 'Sentence Combining' settings label to be 'Sentence Combining in Sentence Reader'

The bookcard status bar needs to recompute the values to take into account that we aren't showing status98 terms anymore. 

Green checkmark appears in the serverurl textbox even if the URL test connection fails. It should only be there if the test passes

The Server URL isn't saving correctly. Every single time I launch the app the server textbox is on the default server. The current settings shows the correct server however

When pressing save settings for the server configuration we should also trigger a connection test, the same exact one triggered by the test connecton button

Add an auto save toggle to the term form. When toggled on this will auto save the term form when clicking out of the form and causing it to close. Cancel should still cancel. The auto save ONLY triggers when the form closes. 








Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
