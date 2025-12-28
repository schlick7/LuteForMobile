# LuteForMobile #
- Frontend end for the lutev3 server
- Targeted primarily at android (it is the test device) but also should work with iphone - maybe through PWA


Menu:
- Reader
  - Keep it very uncluttered, main goal is for easy and clean reading
  - Term Form
    - Opens on double tap
    - Web Dictionary
  - Sentence Reader
    - TTS
    - AI Translation
  - Translation popup (from Server)
    - Opens on tap
  - Sentence Translation
    - Uses web dictionary?
        - Gets links from server
    - Uses AI?
    - We probably want both and then have something in settings to pick which one we want
- Books
  - Card based UI
- Terms
- Statistics
- Settings
  - App Settings
    - Server URL
    - AI setup
    - TTS setup
    - Theme
  - Lute Server Settings
    - Everything that is available from the webview/endpoint 
    
Architecture:
central location for all network calls

Other Features:
- AI connectivity (Should be a selector to pick provider: Local (openai compatible), Openai, (more in future))
  - OpenAI - Local endpoints
    - Get models automatically
    - Prompts for word Translation
    - Prompts for sentence Translation
  - OpenAI
  - maybe others in future
- TTS Manager
  - KokoroTTS
  - NativeTTS?

Test Server: 192.168.1.100:5001
