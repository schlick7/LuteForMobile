# Quick Setup

## Option 1: Automated Setup (Recommended)

This script automatically detects your Lute installation and deploys the PWA files in the correct location.

### Steps:

1. **Download or clone LuteForMobile:**

```bash
# Download zip and extract
# OR clone repo:
git clone https://github.com/schlick7/LuteForMobile.git
cd LuteForMobile
```

2. **Run the setup script:**

```bash
python3 setup_pwa.py
```

That's it! The script will:
- ✅ Auto-detect your Lute installation (pip/venv, Docker, or source)
- ✅ Find the correct static directory
- ✅ Copy all PWA files
- ✅ Fix the base href automatically
- ✅ Show you the URL to access the PWA

### Access the PWA:

After setup completes, open in your browser:

```
http://YOUR_LUTE_IP:5001/static/luteformobile/index.html
```

**Important:** You must include `/index.html` at the end!

### Configure in the App:

1. Open the PWA on your mobile device
2. Go to Settings → Server URL
3. Enter: `http://YOUR_LUTE_IP:5001/`
4. Click "Test Connection"

---

## Option 2: Manual Setup

For manual setup instructions, see [PWA_SETUP_GUIDE.md](PWA_SETUP_GUIDE.md)

---

## Troubleshooting

### Script says "Could not find Lute installation"

Make sure Lute is installed:
```bash
# For pip installation:
pip install lute3

# Or clone the source repo:
git clone https://github.com/LuteOrg/lute-v3.git
```

### PWA still shows 404

After running the script, try accessing with full URL:
```
http://YOUR_LUTE_IP:5001/static/luteformobile/index.html
```

The `/index.html` is required - Flask doesn't auto-serve it from directories.

### Multiple Lute installations?

If you have multiple Lute installations, edit the script to choose which one to deploy to.

---

## Need Help?

See the full [PWA_SETUP_GUIDE.md](PWA_SETUP_GUIDE.md) for detailed information about:
- Docker deployments
- Manual setup
- CORS proxy option
- Advanced configuration
