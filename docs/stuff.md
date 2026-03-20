- vivaldi --disable-web-security --user-data-dir=/tmp/vivaldi_dev
- flutter run -d web-server --debug 
- source myenv/bin/activate
  - python3 -m lute.main
  

---

Expose independent recalculation controls on the book stats endpoint.

- Keep the default `/book/table_stats/<id>` behavior cache-first.
- Support `?force_recalc=true` to recalculate sampled stats in a single call.
- Support `?full_book=true` to recalculate full-book stats in a single call.

This makes it possible to:

- force a fresh sampled recalculation when needed
- force a full-book recalculation when needed

---


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
