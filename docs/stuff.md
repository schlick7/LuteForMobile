- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

---

Total term status change by time period. So total status1 terms 1 week ago and the status1 terms today. Then showing the number of change like +13. Can the server show this information or would we need to store this locally?

---

the terms added today is wrong. You got something wrong. it is showing 91 for today and 7742 for the record. i should only have around 30 for today. and the record seems to be all of the status0 terms

---

The install termux button brings you to the github
Tapping termux in the status bring you to play store

---

# Termux
-

# Requests 
-

# Settings
- 

# Reader
- 

# Sentence Reader
-

# TTS
- 

# AI
- done? gemini

Add a translategemma ai prompt for terms as well in @AIprompts.md

Now you need to go through all those 6 results and rank them. The absolute best outcome is to results both with correct translations (correr = to run is better than correr = run). The 2nd best is having 1 of the 2 results be correct. The absolute worst would be incorrect answer, be they single words or phrase. Less than ideal but potential acceptable would be correct answers but in phrases or with boundary term leaks. Put less wait on proper nouns as they matter much less. Give slightly better ranking for terms that result in 2 distinct results that are both correct

# Books Screen
- 

# Terms Screen
- 
 
# Statistics Screen  
- 

# Help Screen
- Can't copy text

# Theme
-



# Future:
- add a toggle to book details to select between Server parsing or App parsing
  - include hint
  - put this in the edit button and move the confirmation to the edit button popup for editing the term.
- add a selector in language settings to apply TTS voices based on languages.
