- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

# Terms Screen
- Use Termform for term editing

Add todays read stats to bottom nav bar 

## Add page turn animation? - First attempt broke hard!

fixed? Some users are reporting that tooltips aren't showing. They work perfectly in my testing. Lets look into how to solve this. Maybe with retry logic of sometype? I think this is an issue with a slow server. All of our testing servers are really fast but some users may have slow servers 
  - how hard to add elsewhere?

### TTS options: On device, local-OpenAI endpoint, OpenAI, None
  - Future: add a selector in language settings to apply TTS voices based on languages. 
  - add test server button
  
### AI options: local-OpenAI endpoint, OpenAI, None, others in the future.
  - support auto model fetching
  - unique settings for each option
  - "Using the sentence '[sentence]' Translate only the following term from [language] to English: [term]. Respond with the 2 most common translations"
  - "Translate the following sentence from [language] to English: [sentence]"
  - longpress Dictionary has AI tab that (ONLY) when opened fetches translation

edge case? upside down '?' are at the start (and ? at the end as well) of spanish question words but the sentence parser doesn't pull them in if its at the start of new sentence and it stays on the last sentence. Any way to do this intelligently from the language settings that we have access to or would we need to hard code this in the parser. 

Maybe fixed? When we combine sentences with the sentence parser lets make sure theres at least 1 space between the sentences



Add more custom theme options
  - have custom open up a window?
    - include examples for everything if possible. 
  - have a create theme button
    - have a create from selector where we pick one of the already existing themes or select none. This will auto fill in all of the options with those colors. This is so users can have a custom theme with minor changes or a custom theme with major changes -- best of both worlds. 
  - status should have a toggle for showing the selected color as the background highlight(like 1-5) or the text color (like status0) 




# Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
- When page marked as done and a popup to navigate to books to pick out another. Add a great job or something and a animation of some kind to celebrate the completetion of a book. Include number of words in the book? 
- add a selector in language settings to apply TTS voices based on languages. 


# PWA
## Build the web app first
flutter build web

## Add script
cp setup_pwa.py build/web/

## Fix permissions
cd build/web
sudo find build/web -type f -exec chmod 644 {} \;
sudo find build/web -type d -exec chmod 755 {} \;
sudo chown -R $USER:$USER build/web

## Create the zip
zip -r ../../LuteForMobilePWA.zip * -x "*.last_build_id"
