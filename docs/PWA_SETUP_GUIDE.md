# LuteForMobile PWA - Local Setup Instructions

## IMPORTANT: CORS Security Issue

**Browser security (Same-Origin Policy) blocks requests between different origins (different domains/IPs/ports).**

- **Problem:** If PWA is at `http://192.168.1.100:5002` and Lute is at `http://192.168.1.152:5001`, the browser blocks the connection
- **Solution:** Use one of the two methods below

## Overview

This PWA allows you to use Lute on your mobile device. The PWA must be served from the **same origin** as your Lute server to avoid browser CORS restrictions.

**Two ways to set up:**

**Option 1: Serve PWA from Lute server (RECOMMENDED - no CORS issues)**
- Deploy PWA files to your Lute server's web directory
- Access everything at one URL (e.g., http://192.168.1.152:5001/)

**Option 2: Use CORS proxy**
- PWA and Lute on different machines/ports
- Requires CORS proxy server (included in web/cors_proxy_server.py)

**Requirements:**
- Lute server running
- Mobile device connected to same WiFi network
- Python installed (comes pre-installed on most systems)

## Step 1: Download PWA Files

Download the PWA files from GitHub Releases:
1. Go to: https://github.com/schlick7/LuteForMobile/releases
2. Download the latest `lute-pwa.zip` file
3. Extract the zip file to a folder:

```bash
# Extract the zip file
unzip lute-pwa.zip -d lute-pwa/
cd lute-pwa

# OR using the automated setup script (recommended):
python3 setup_pwa.py
```

The `setup_pwa.py` script will:
- ✅ Auto-detect your Lute installation (pip/venv, Docker, or source)
- ✅ Find the correct static directory
- ✅ Copy all PWA files
- ✅ Fix the base href automatically
- ✅ Show you the URL to access the PWA

**Alternative: Clone the repo:**
```bash
git clone https://github.com/schlick7/LuteForMobile.git
cd LuteForMobile
python3 setup_pwa.py
```

## Step 2: Choose Setup Method

### OPTION 1: Deploy to Lute Server (RECOMMENDED - No CORS issues)

**How this works:** 

This puts the PWA files on your Lute server so everything runs from the same URL. Since the PWA and Lute API are served from the same origin (same IP:port), the browser doesn't block requests with CORS.

**CORS checks (all must match):**
- ✓ **Scheme:** Both use `http` (or both use `https`)
- ✓ **Host:** Both use same IP (e.g., `192.168.1.152`)
- ✓ **Port:** Both use same port (e.g., `5001`)

**Example file structure:**
```
Before (CORS blocked):
  Lute Server (192.168.1.152:5001) → API endpoints
  PWA (localhost:5002) → Different origin → Browser blocks requests

After (Option 1 - No CORS):
  Lute Server (192.168.1.152:5001)
  ├── Lute web app
  ├── LuteForMobile PWA
  └── API endpoints (/api/*)
          ↑
  Same origin - no blocking!
```

---

#### Step A: Find Lute's web directory

**If using Docker Lute:**
```bash
# Find your Lute container
docker ps | grep lute

# Check where Lute stores web files (typically /lute-data/web or /app/web)
docker exec <lute_container_name> ls -la /lute-data/  # or /app/
```

**If running Lute from source (Python/Flask):**
```bash
# Navigate to Lute installation directory
cd /path/to/lute

# Look for a 'web', 'static', or 'templates' folder
ls -la
```

**If using pip with virtual environment:**
```bash
# Navigate to your Lute directory
cd ~/my_lute  # or wherever you installed Lute

# The static files are in the virtualenv:
# ~/my_lute/myenv/lib/python3.X/site-packages/lute/static/
# (replace 3.X with your Python version)
```

---

#### Step B: Deploy PWA files

**Option B1: Copy to Lute root (simpler access)**

```bash
# Copy PWA files to Lute's static directory
cp -r /path/to/LuteForMobile/build/web/* /path/to/lute/static/
```

**Option B2: Create luteformobile subdirectory (cleaner organization)**

```bash
# Create luteformobile directory in Lute static folder
mkdir -p /path/to/lute/static/luteformobile

# Copy PWA files there
cp -r /path/to/LuteForMobile/build/web/* /path/to/lute/static/luteformobile/
```

**For pip/venv installations:**

```bash
# Create luteformobile directory in Lute virtualenv
mkdir -p ~/my_lute/myenv/lib/python3.X/site-packages/lute/static/luteformobile

# Copy PWA files there (replace 3.X with your Python version)
cp -r /path/to/LuteForMobile/build/web/* ~/my_lute/myenv/lib/python3.X/site-packages/lute/static/luteformobile/

# Fix base href (important!)
sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' ~/my_lute/myenv/lib/python3.X/site-packages/lute/static/luteformobile/index.html
```

**For Docker deployments:**

**Method 1: Copy to running container**
```bash
# Find your Lute container name
docker ps | grep lute

# Create luteformobile directory in container
docker exec <lute_container_name> mkdir -p /lute/static/luteformobile

# Copy PWA files to container
docker cp /path/to/LuteForMobile/build/web/. <lute_container_name>:/lute/static/luteformobile/

# Fix base href in container
docker exec <lute_container_name> sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' /lute/static/luteformobile/index.html

# Restart container to pick up changes
docker restart <lute_container_name>
```

**Method 2: Docker volume (recommended for persistence)**

1. Extract PWA files locally:
```bash
unzip lute-pwa.zip -d ~/luteformobile/
```

2. Fix base href locally:
```bash
sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' ~/luteformobile/index.html
```

3. Update docker-compose.yml to mount PWA directory:
```yaml
services:
  lute:
    # ... existing config ...
    volumes:
      - lute-data:/lute/data
      - ~/luteformobile:/lute/static/luteformobile  # Add this line
```

4. Restart Docker:
```bash
docker-compose down && docker-compose up -d
```

**Alternative Docker: Check if your Lute uses `/lute-data/web/`**
```bash
# Check web directory structure
docker exec <lute_container_name> ls -la /lute-data/  # or /app/

# If web directory exists, use:
docker cp /path/to/LuteForMobile/build/web/. <lute_container_name>:/lute-data/web/luteformobile/
docker exec <lute_container_name> sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' /lute-data/web/luteformobile/index.html
```

---

#### Step C: Fix base href (if using subdirectory)

If you deployed to a subdirectory like `/luteformobile/`, you need to update the base href:

1. Edit `build/web/index.html`:
```html
<!-- Change this -->
<base href="$FLUTTER_BASE_HREF">

<!-- To this -->
<base href="/static/luteformobile/">
```

2. Or edit directly on Lute server after deploying

Or use sed to automate:

**For pip/venv installations:**
```bash
sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' ~/my_lute/myenv/lib/python3.X/site-packages/lute/static/luteformobile/index.html
```

**For Docker or source installations:**
```bash
sed -i 's|<base href=".*">|<base href="/static/luteformobile/">|' /path/to/lute/static/luteformobile/index.html
```

---

#### Step D: Access the PWA

**If deployed to root:**
- PWA URL: `http://YOUR_LUTE_IP:5001/`
- Server URL in App Settings: `http://YOUR_LUTE_IP:5001/`
- Example: `http://192.168.1.152:5001/`

**If deployed to /luteformobile/ subdirectory:**
- PWA URL: `http://YOUR_LUTE_IP:5001/luteformobile/`
- Server URL in App Settings: `http://YOUR_LUTE_IP:5001/`
- Example: `http://192.168.1.152:5001/luteformobile/`

---

#### Step E: Verify no CORS errors

After deploying, open browser DevTools (F12) and check:

1. **Network tab:** You should see:
   - `Document: http://192.168.1.152:5001/` (PWA page)
   - `Fetch/XHR: http://192.168.1.152:5001/api/book/datatables/active` (API call)

2. **Console tab:** No CORS errors (should not see "Cross-Origin Request Blocked")

If you see CORS errors, double-check that both PWA and API use the exact same IP and port.

---

#### Summary for Option 1

| Setting | Value |
|---------|-------|
| PWA location | On Lute server (same machine) |
| PWA URL | `http://LUTE_IP:5001/` or `http://LUTE_IP:5001/luteformobile/` |
| Server URL in app | `http://LUTE_IP:5001/` |
| CORS needed? | **No** (same origin) |
| Proxy needed? | **No** |

#### Directory Structure After Deployment
```
lute/static/
├── css/
├── js/
├── img/
├── icn/
├── vendor/
└── luteformobile/          # ← PWA files here
    ├── index.html
    ├── main.dart.js
    ├── assets/
    ├── icons/
    └── manifest.json
```

---

---

### OPTION 2: Use CORS Proxy (If you can't deploy to Lute server)

**Step 2a: Configure the proxy**

Edit `web/cors_proxy_server.py` and update line 14 with your Lute server URL:
```python
LUTE_SERVER_URL = "http://192.168.1.152:5001"  # Change to your Lute server
```

**Step 2b: Start the CORS proxy server**

```bash
cd ~/lute-pwa/web
python3 cors_proxy_server.py
```

You should see:
```
Starting CORS Proxy Server for LuteForMobile
PWA serving on: http://localhost:5002
Proxying API requests to: http://192.168.1.152:5001
Use API URL in app settings: http://localhost:5002/api/
```

**Keep this terminal open!**

**Step 2c: Find your computer's IP address**

**Windows:**
```cmd
ipconfig
# Look for "IPv4 Address" under Wireless LAN adapter
```

**macOS:**
```bash
ipconfig getifaddr en0
```

**Linux:**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
```

## Step 3: Access PWA on Mobile Device

1. Make sure mobile device is on the same WiFi
2. Open Safari (iOS) or Chrome (Android)
3. Navigate to:
   - **Option 1:** `http://YOUR_LUTE_IP:5001/`
   - **Option 2:** `http://YOUR_PWA_HOST_IP:5002/`

## Step 4: Configure Server URL in App

**Option 1 users:**
- Go to Settings → Server URL
- Enter: `http://YOUR_LUTE_IP:5001/`
- Example: `http://192.168.1.152:5001/`
- **Note:** If deployed to subdirectory, still use root URL (without /luteformobile/)

**Option 2 users:**
- Go to Settings → Server URL
- Enter: `http://YOUR_PWA_HOST_IP:5002/api/`
- Example: `http://192.168.1.100:5002/api/`
- **Important:** Must include `/api/` at the end

**Test Connection:**
1. Click "Test Connection" button in Settings
2. Check for green success message
3. If failed, see Troubleshooting section below

Save settings and load books.

## Step 5: Install as PWA (Add to Home Screen)

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

## Step 6: Using the PWA Offline

Once installed and used at least once:
- The PWA caches all assets locally
- You can launch it from your home screen even without internet
- **Option 1:** No extra server needed - Lute server serves both app and API
- **Option 2:** CORS proxy must be running on your computer to access the app
- Books and content sync with your Lute server when available

## Step 7: Stop the Server

To stop the server when you're done:
1. Go to the terminal window where the server is running
2. Press `Ctrl + C`

To start it again later, repeat Step 2.

## Step 8: Comparison Card

| Feature | Option 1 (Deploy to Lute) | Option 2 (CORS Proxy) |
|---------|---------------------------|------------------------|
| **CORS issues** | ✅ None (same origin) | ✅ None (proxy handles it) |
| **Complexity** | ✅ Simple (copy files) | ⚠️ Moderate (run proxy) |
| **Requires extra server** | ❌ No | ✅ Yes (Python script) |
| **Best for** | Docker users, server access | Can't access server files |
| **PWA URL** | `http://LUTE_IP:5001/` | `http://PWA_HOST_IP:5002/` |
| **Server URL** | `http://LUTE_IP:5001/` | `http://PWA_HOST_IP:5002/api/` |

---

## Advanced: Running Server in Background

### Windows (using Task Scheduler)
1. Create a batch file `start_lute_pwa.bat`:
   ```bat
   cd C:\path\to\lute-pwa\web
   python cors_proxy_server.py
   ```
2. Edit `C:\path\to\lute-pwa\web\cors_proxy_server.py` line 14 to set your Lute server URL
3. Open Task Scheduler
4. Create Basic Task → "Start Lute PWA Server"
5. Trigger: "When I log on" or "At system startup"
6. Action: Start a program → select your batch file

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
           <string>/Users/YOUR_USERNAME/lute-pwa/web/cors_proxy_server.py</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>WorkingDirectory</key>
       <string>/Users/YOUR_USERNAME/lute-pwa/web</string>
   </dict>
   </plist>
   ```
2. Replace `YOUR_USERNAME` with your actual username
3. Edit `/Users/YOUR_USERNAME/lute-pwa/web/cors_proxy_server.py` line 14 to set your Lute server URL
4. Load the service:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.lute.pwa.plist
   ```

### Linux (using systemd)
1. Create `/etc/systemd/system/lute-pwa.service`:
   ```ini
   [Unit]
   Description=Lute PWA CORS Proxy Server
   After=network.target

   [Service]
   Type=simple
   User=yourusername
   WorkingDirectory=/home/yourusername/lute-pwa/web
   ExecStart=/usr/bin/python3 /home/yourusername/lute-pwa/web/cors_proxy_server.py
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```
2. Replace `yourusername` with your actual username
3. Edit `/home/yourusername/lute-pwa/web/cors_proxy_server.py` line 14 to set your Lute server URL
4. Enable and start:
   ```bash
   sudo systemctl enable lute-pwa
   sudo systemctl start lute-pwa
   ```

## Troubleshooting

### CORS Error: "Cross-Origin Request Blocked"

**Symptoms:** Browser console shows CORS errors, app can't connect

**Solutions:**
1. **Use Option 1:** Deploy PWA files to Lute server web directory (recommended)
2. **Use Option 2:** Ensure you're using the CORS proxy with `/api/` suffix in settings
3. **Test:** Open browser DevTools (F12) → Console tab to see exact CORS errors

### Cannot access PWA from mobile device
1. **Check firewall:** Make sure port (5001 or 5002) is not blocked
   - Windows: Windows Defender → Allow an app through firewall
   - macOS: System Settings → Network → Firewall
   - Linux: `sudo ufw allow 5002`

2. **Verify same network:** Both devices must be on same WiFi (not guest networks)

3. **Test from computer:** Open the PWA URL in your browser first

### App shows "Connection Failed"
1. Verify your Lute server is running
2. Check the server URL in app settings:
   - Option 1: `http://LUTE_IP:5001/`
   - Option 2: `http://PWA_HOST_IP:5002/api/` (must include /api/)
3. Try accessing Lute server in browser: http://LUTE_IP:5001
4. Check browser console (F12) for CORS errors

### IP Address Changes

**If using Option 1:**
- Only Lute server IP matters
- If Lute server IP changes, update app Settings → Server URL
- Use static IP for Lute server or local DNS

**If using Option 2:**
- Both CORS proxy host and Lute server IPs matter
- If either changes, update app Settings → Server URL
- Set static IPs or use local DNS

**To prevent issues:**
- Set static IPs in your router settings
- Or use local domain names (e.g., `lute.local`)

### Server won't start
- **Port 5002 already in use:** Try a different port (edit cors_proxy_server.py line 15)
  ```python
  PORT = 8001  # Change from 5002
  ```
- **Python not found:** Install Python from python.org
- **CORS proxy errors:** Check that LUTE_SERVER_URL in cors_proxy_server.py is correct

## Multiple Users on Same Network

**If using Option 1 (Deploy to Lute):**
- Everyone accesses the same Lute server URL
- Each person configures their own Lute server URL in app settings (if using different Lute instances)
- No additional setup needed

**If using Option 2 (CORS Proxy):**

### Approach A: Each hosts their own CORS proxy
- Each person runs CORS proxy on their computer
- Each edits cors_proxy_server.py to point to their Lute server
- Each uses their own IP: `http://192.168.1.XXX:5002/api/`

### Approach B: Central CORS proxy (requires static IP)
1. Set up one computer with static IP (e.g., 192.168.1.50)
2. Run CORS proxy there
3. Everyone uses: `http://192.168.1.50:5002/api/`
4. Each person configures their own Lute server URL in cors_proxy_server.py

## Security Notes

- This setup is designed for **trusted home networks only**
- Do not expose this to the internet (your local network firewall should block external access)
- Anyone on your WiFi can access the PWA if they know the IP
- Consider adding basic authentication if security is a concern

## Alternative: Using Different Web Server

**Important:** Regular web servers won't handle CORS. Use the included CORS proxy (`cors_proxy_server.py`) if you can't deploy to Lute server.

### Using Node.js (http-server) - ONLY IF DEPLOYED TO LUTE SERVER
```bash
npm install -g http-server
cd ~/lute-pwa
http-server -p 5002
```

### Using Ruby - ONLY IF DEPLOYED TO LUTE SERVER
```bash
cd ~/lute-pwa
ruby -run -e httpd . -p 5002
```

### Using PHP - ONLY IF DEPLOYED TO LUTE SERVER
```bash
cd ~/lute-pwa
php -S localhost:5002
```

**CORS Proxy (Required for separate origins):**
```bash
cd ~/lute-pwa/web
python3 cors_proxy_server.py
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Search existing issues: https://github.com/schlick7/LuteForMobile/issues
3. Create a new issue with details about your setup (OS, Python version, error messages)

---

**Enjoy using Lute on your mobile device!**
