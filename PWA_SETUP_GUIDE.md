# LuteForMobile PWA - Local Setup Instructions

## Overview

This PWA allows you to use Lute on your mobile device by hosting the app locally and connecting to your local Lute server. Both the PWA and Lute server run over HTTP on your local network, avoiding browser security restrictions.

**Requirements:**
- Lute server running locally (default: http://192.168.1.100:5001)
- Mobile device connected to same WiFi network
- Computer to host the PWA
- Python installed (comes pre-installed on most systems)

## Step 1: Download PWA Files

Download the PWA files from GitHub Releases:
1. Go to: https://github.com/schlick7/LuteForMobile/releases
2. Download the latest `lute-pwa.zip` file
3. Extract the zip file to a folder on your computer (e.g., `~/lute-pwa/`)

**Alternative: If zip not available, clone the repo:**
```bash
git clone https://github.com/schlick7/LuteForMobile.git
cd LuteForMobile/build/web
# The web folder contains the PWA files
```

## Step 2: Start Local HTTP Server

Navigate to the PWA folder and start the server:

**Windows:**
```cmd
cd lute-pwa
python -m http.server 8000
```

**macOS/Linux:**
```bash
cd ~/lute-pwa
python3 -m http.server 8000
```

You should see:
```
Serving HTTP on 0.0.0.0 port 8000 (http://localhost:8000/) ...
```

**Keep this terminal window open!** The server must remain running to access the PWA.

## Step 3: Find Your Computer's IP Address

**Windows:**
1. Open Command Prompt
2. Run: `ipconfig`
3. Find your network adapter (usually "Wireless LAN adapter Wi-Fi")
4. Note the "IPv4 Address" (e.g., 192.168.1.100)

**macOS:**
```bash
ipconfig getifaddr en0
```

**Linux:**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
```

## Step 4: Access PWA on Mobile Device

1. Make sure your mobile device is on the same WiFi network as your computer
2. Open Safari (iOS) or Chrome (Android)
3. Navigate to: `http://YOUR_IP_ADDRESS:8000`
   - Example: `http://192.168.1.100:8000`

You should see the LuteForMobile app load!

## Step 5: Configure Lute Server Connection

1. Tap the menu icon (≡) in the app
2. Go to Settings
3. Under "Server Configuration", enter your Lute server URL:
   - Default: `http://192.168.1.100:5001`
   - Adjust the IP if your Lute server is on a different machine
4. Save settings

The app should now connect to your Lute server and load your books.

## Step 6: Install as PWA (Add to Home Screen)

**iPhone/iPad (iOS):**
1. Tap the Share button (square with arrow up) in Safari
2. Scroll down and tap "Add to Home Screen"
3. Tap "Add" in the top right corner
4. The LuteForMobile icon will appear on your home screen

**Android:**
1. Tap the three-dot menu in Chrome
2. Tap "Add to Home Screen" or "Install App"
3. Tap "Add" or "Install"
4. The app icon will appear on your home screen

## Step 7: Using the PWA Offline

Once installed and used at least once:
- The PWA caches all assets locally
- You can launch it from your home screen even without internet
- **However:** You still need your local HTTP server running on your computer to access the app
- Books and content sync with your Lute server when available

## Step 8: Stop the Server

To stop the server when you're done:
1. Go to the terminal window where the server is running
2. Press `Ctrl + C`

To start it again later, repeat Step 2.

## Advanced: Running Server in Background

### Windows (using Task Scheduler)
1. Create a batch file `start_lute_pwa.bat`:
   ```bat
   cd C:\path\to\lute-pwa
   python -m http.server 8000
   ```
2. Open Task Scheduler
3. Create Basic Task → "Start Lute PWA Server"
4. Trigger: "When I log on" or "At system startup"
5. Action: Start a program → select your batch file

### macOS (using launchd)
1. Create `~/Library/LaunchAgents/com.lute.pwa.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.lute.pwa</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/bin/python3</string>
           <string>-m</string>
           <string>http.server</string>
           <string>8000</string>
           <string>--directory</string>
           <string>/Users/YOUR_USERNAME/lute-pwa</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>WorkingDirectory</key>
       <string>/Users/YOUR_USERNAME/lute-pwa</string>
   </dict>
   </plist>
   ```
2. Replace `YOUR_USERNAME` with your actual username
3. Load the service:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.lute.pwa.plist
   ```

### Linux (using systemd)
1. Create `/etc/systemd/system/lute-pwa.service`:
   ```ini
   [Unit]
   Description=Lute PWA HTTP Server
   After=network.target

   [Service]
   Type=simple
   User=yourusername
   WorkingDirectory=/home/yourusername/lute-pwa
   ExecStart=/usr/bin/python3 -m http.server 8000
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```
2. Replace `yourusername` with your actual username
3. Enable and start:
   ```bash
   sudo systemctl enable lute-pwa
   sudo systemctl start lute-pwa
   ```

## Troubleshooting

### Cannot access PWA from mobile device
1. **Check firewall:** Make sure port 8000 is not blocked
   - Windows: Windows Defender → Allow an app through firewall
   - macOS: System Settings → Network → Firewall
   - Linux: `sudo ufw allow 8000`

2. **Verify same network:** Both devices must be on same WiFi (not guest networks)

3. **Test from computer:** Open http://localhost:8000 in your browser to verify server is running

### App shows "Connection Failed"
1. Verify your Lute server is running (default: http://192.168.1.100:5001)
2. Check the server URL in app settings matches your Lute server
3. Try accessing Lute server in browser: http://192.168.1.100:5001

### IP Address Changes
Your computer's IP may change when you restart your router or network connection. When this happens:

1. Find your new IP address (Step 3)
2. Update the URL on your mobile device: `http://NEW_IP:8000`
3. Re-add to home screen if needed

**To prevent this:**
- Set a static IP for your computer in your router settings
- Or use a domain name with local DNS

### Server won't start
- **Port 8000 already in use:** Try a different port (8001, 8002, etc.)
  ```bash
  python -m http.server 8001
  ```
- **Python not found:** Install Python from python.org

## Multiple Users on Same Network

If multiple family members want to use the PWA:

### Option 1: Each hosts their own server
- Each person runs the HTTP server on their computer
- Each uses their own IP: `http://192.168.1.XXX:8000`

### Option 2: Central server (requires static IP)
1. Set up one computer with static IP (e.g., 192.168.1.50)
2. Run the HTTP server there
3. Everyone uses: `http://192.168.1.50:8000`
4. Each person configures their own Lute server URL in app settings

## Security Notes

- This setup is designed for **trusted home networks only**
- Do not expose this to the internet (your local network firewall should block external access)
- Anyone on your WiFi can access the PWA if they know the IP
- Consider adding basic authentication if security is a concern

## Alternative: Using Different Web Server

If Python's HTTP server doesn't work for you, try:

### Using Node.js (http-server)
```bash
npm install -g http-server
cd ~/lute-pwa
http-server -p 8000
```

### Using Ruby
```bash
cd ~/lute-pwa
ruby -run -e httpd . -p 8000
```

### Using PHP
```bash
cd ~/lute-pwa
php -S localhost:8000
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Search existing issues: https://github.com/schlick7/LuteForMobile/issues
3. Create a new issue with details about your setup (OS, Python version, error messages)

---

**Enjoy using Lute on your mobile device!**
