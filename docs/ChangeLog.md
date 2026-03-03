# Requires Uninstalling Version v0.8.5 or earlier first

# Bug Fixes
- Stop autobackups from triggering every app launch
- Fixed some excessive Cache calls
- Fixed a BUNCH of excessive Fetch calls
- Fixed some incorrect Rebuilds triggering
- Fixed ondevice TTS
- TermScreen no longer scrolls on TermForm exit
- Tags now work properly in TermsForm

# New Feature
- Termux Integration (Android APK only)
  - Requires Termux and F-Droid
  - Install with *almost* no manual setup
  - Launch/Stop Lute3 Server
  - Trigger Db backups and Download Db backups

# Other Changes
- Make tooltips open instantly
- Add icon for server not connected
- Adjust SentenceTranslation popup height
- Adjust SentenceReader Ratio


# Changes from PreReleases
- Change backup directory on backup restores so backing up between devices works seamlessly.
- Change how autobackup works again again
- Many little tweaks
- Many little bug fixes
- Fixed Books not loading
- For real this time fixed release key changing
- Added configuration for Book Stats loading
- Added configuration of tooltip caching


Fixed term status count loading in TermScreen - This is a major performance fix
