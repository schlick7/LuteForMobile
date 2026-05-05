# LuteForMobile PWA Setup Guide

This guide installs the LuteForMobile web app into your Lute server so your phone can open it from the same address as Lute.

The important rule is simple: serve the PWA from Lute itself. If the PWA is hosted on a different IP, hostname, or port than Lute, the browser can block API calls with CORS errors.

## Requirements

- Lute is already installed and running.
- Python is installed.
- Your phone and the Lute server are on the same network.
- You have either a downloaded `lute-pwa.zip` release or a local clone of this repository.

The setup script supports:

- Python virtualenv installs on Linux, macOS, and Windows.
- Lute source installs with a `lute/static` directory.
- Docker installs using a normal Linux Lute container.

## Automated Setup

Use this first. It is the recommended path.

### From a Release Zip

Download the latest `lute-pwa.zip` from:

```text
https://github.com/schlick7/LuteForMobile/releases
```

Extract it, open a terminal in the extracted folder, then run:

```bash
python3 setup_pwa.py
```

you instead may need:

```bash
python setup_pwa.py
```

### From the Repo

If you cloned this repository, build the web app first:

```bash
flutter build web
python setup_pwa.py
```

On Linux or macOS:

```bash
flutter build web
python3 setup_pwa.py
```

The script automatically:

- Finds the Flutter web files.
- Detects your Lute install.
- Copies the PWA to `lute/static/luteformobile`.
- Sets the Flutter base href to `/static/luteformobile/`.
- Prints the URL to open.

## Open the PWA

After setup completes, open:

```text
http://YOUR_LUTE_IP:5001/static/luteformobile/index.html
```

Examples:

```text
http://192.168.1.152:5001/static/luteformobile/index.html
http://localhost:5001/static/luteformobile/index.html
```

Use the full `/index.html` URL. Lute does not automatically serve directory indexes.

## Configure the App

In LuteForMobile, open Settings and set Server URL to the root Lute URL:

```text
http://YOUR_LUTE_IP:5001/
```

Example:

```text
http://192.168.1.152:5001/
```

Do not include `/static/luteformobile/` in the Server URL. That path is only for loading the PWA files.

## Install on Your Phone

### iPhone or iPad

1. Open the PWA URL in Safari.
2. Tap Share.
3. Tap Add to Home Screen.
4. Tap Add.

### Android

1. Open the PWA URL in Chrome.
2. Open the three-dot menu.
3. Tap Add to Home Screen or Install app.
4. Confirm the install.

## Manual Setup

Use this only if `setup_pwa.py` cannot find your Lute installation.

The manual deployment has three steps:

1. Find Lute's `static` directory.
2. Copy the Flutter web build into a `luteformobile` subdirectory.
3. Change `index.html` so the base href is `/static/luteformobile/`.

### Find the Static Directory

Common locations:

```text
Linux/macOS venv:
~/my_lute/myenv/lib/python3.X/site-packages/lute/static

Windows venv:
%USERPROFILE%\my_lute\myenv\Lib\site-packages\lute\static

Source install:
/path/to/lute/lute/static
```

For Docker, check the container:

```bash
docker ps --filter name=lute
docker exec CONTAINER_NAME test -d /lute/static
docker exec CONTAINER_NAME test -d /lute-data/web
```

Use `/lute/static` if it exists. Otherwise use `/lute-data/web` if that exists.

### Copy Files

For a local install:

```bash
mkdir -p /path/to/lute/static/luteformobile
cp -r build/web/* /path/to/lute/static/luteformobile/
```

For Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\my_lute\myenv\Lib\site-packages\lute\static\luteformobile"
Copy-Item -Recurse -Force .\build\web\* "$env:USERPROFILE\my_lute\myenv\Lib\site-packages\lute\static\luteformobile\"
```

For Docker:

```bash
docker exec CONTAINER_NAME mkdir -p /lute/static/luteformobile
docker cp build/web/. CONTAINER_NAME:/lute/static/luteformobile/
```

If your container uses `/lute-data/web`, replace `/lute/static` with `/lute-data/web`.

### Fix Base Href

In the deployed `index.html`, change the `<base>` tag to:

```html
<base href="/static/luteformobile/" />
```

For Linux/macOS local installs:

```bash
python3 - <<'PY'
from pathlib import Path
path = Path("/path/to/lute/static/luteformobile/index.html")
text = path.read_text(encoding="utf-8")
text = text.replace('<base href="/">', '<base href="/static/luteformobile/" />')
text = text.replace('<base href="$FLUTTER_BASE_HREF">', '<base href="/static/luteformobile/" />')
path.write_text(text, encoding="utf-8")
PY
```

For Docker, copy `index.html` out, edit it locally, then copy it back:

```bash
docker cp CONTAINER_NAME:/lute/static/luteformobile/index.html ./index.html
# Edit ./index.html so the base href is /static/luteformobile/
docker cp ./index.html CONTAINER_NAME:/lute/static/luteformobile/index.html
```

## Troubleshooting

### `setup_pwa.py` cannot find PWA files

If you are running from the repo, build first:

```bash
flutter build web
python setup_pwa.py
```

If you are running from a release zip, run the script from the extracted zip folder.

### `setup_pwa.py` cannot find Lute

Check that Lute is installed in one of the expected locations:

```text
~/my_lute
~/lute
~/.lute
```

For Windows, the same locations are checked under your user profile.

If your install is somewhere else, use the manual setup section.

### Multiple Docker Containers Match `lute`

The script stops instead of guessing. Either stop the extra containers or rename the target container to exactly `lute`.

You can list matches with:

```bash
docker ps --filter name=lute --format "{{.Names}}"
```

### The PWA URL Returns 404

Use the full URL:

```text
http://YOUR_LUTE_IP:5001/static/luteformobile/index.html
```

Also confirm the files were copied into:

```text
lute/static/luteformobile/index.html
```

### The App Shows Connection Failed

Check these in order:

1. Lute is running.
2. Your phone is on the same network as the Lute server.
3. The Server URL in app settings is the Lute root URL, such as `http://192.168.1.152:5001/`.
4. The Server URL does not include `/static/luteformobile/`.
5. Your firewall allows access to Lute's port, usually `5001`.

### Browser Console Shows CORS Errors

CORS errors mean the PWA and Lute API are not being loaded from the same origin.

Use:

```text
PWA URL:    http://192.168.1.152:5001/static/luteformobile/index.html
Server URL: http://192.168.1.152:5001/
```

Do not use:

```text
PWA URL:    http://localhost:8000/index.html
Server URL: http://192.168.1.152:5001/
```

The scheme, host, and port must match.

### Your Lute Server IP Changes

If the server IP changes, update the Server URL in app settings. To avoid doing that repeatedly, reserve a static IP for the Lute server in your router or use a local hostname.

## Security Notes

This setup is intended for trusted local networks.

- Do not expose your Lute server directly to the internet.
- Anyone who can access your Lute server URL can load the PWA files.
- Use your router/firewall to keep Lute private to your network.

## Support

If setup still fails, include these details when opening an issue:

- Operating system.
- Lute install type: venv, source, or Docker.
- The command you ran.
- The full error output.
- Whether `http://YOUR_LUTE_IP:5001/` opens the normal Lute web app.

Issues:

```text
https://github.com/schlick7/LuteForMobile/issues
```
