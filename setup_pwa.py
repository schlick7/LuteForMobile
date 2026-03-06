#!/usr/bin/env python3
"""
LuteForMobile PWA Setup Script
Automates deploying PWA files to your Lute server installation.
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


def _fix_base_href(index_html_path, base_href="/static/luteformobile/"):
    """Rewrite <base href="..."> to match deployed static subpath."""
    with open(index_html_path, "r", encoding="utf-8") as f:
        content = f.read()

    updated, count = re.subn(
        r'<base\s+href="[^"]*"\s*/?>',
        f'<base href="{base_href}" />',
        content,
        count=1,
        flags=re.IGNORECASE,
    )

    # Fallback for unexpected templates where the <base> tag may be missing.
    if count == 0:
        updated = content.replace(
            "<head>", f'<head>\n    <base href="{base_href}" />', 1
        )

    with open(index_html_path, "w", encoding="utf-8") as f:
        f.write(updated)


def find_lute_installation():
    """Find where Lute is installed."""
    print("🔍 Detecting Lute installation...")

    # Check for pip/venv installation
    lute_venv_paths = [
        Path.home() / "my_lute",
        Path.home() / "lute",
        Path.home() / ".lute",
    ]

    for base_path in lute_venv_paths:
        if not base_path.exists():
            continue

        # Check for venv
        venv_path = base_path / "myenv"
        if venv_path.exists():
            print(f"✅ Found Lute at: {base_path} (with venv)")
            # Find static in the venv
            py_version = find_python_version_in_venv(venv_path)
            if py_version:
                static_path = (
                    venv_path
                    / "lib"
                    / f"python{py_version}"
                    / "site-packages"
                    / "lute"
                    / "static"
                )
                if static_path.exists():
                    return {
                        "type": "venv",
                        "static_path": static_path,
                        "lute_path": base_path,
                    }

    # Check for Docker
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=lute", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0 and result.stdout.strip():
            container_name = result.stdout.strip()
            print(f"✅ Found Docker container: {container_name}")
            return {"type": "docker", "container_name": container_name}
    except FileNotFoundError:
        pass

    # Check for source installation
    source_paths = [
        Path.home() / "lute",
        Path.home() / "Lute",
        Path.cwd().parent,
    ]

    for source_path in source_paths:
        static_path = source_path / "lute" / "static"
        if static_path.exists():
            print(f"✅ Found Lute source at: {source_path}")
            return {
                "type": "source",
                "static_path": static_path,
                "lute_path": source_path,
            }

    print("❌ Could not find Lute installation")
    return None


def find_python_version_in_venv(venv_path):
    """Find Python version in virtual environment."""
    lib_path = venv_path / "lib"
    if not lib_path.exists():
        return None

    for item in lib_path.iterdir():
        if item.is_dir() and item.name.startswith("python3."):
            version = item.name.replace("python", "")
            print(f"   Python version: {version}")
            return version
    return None


def deploy_to_venv(lute_info, pwa_path):
    """Deploy PWA to venv installation."""
    static_path = lute_info["static_path"]
    dest_path = static_path / "luteformobile"

    print(f"\n📂 Deploying to: {dest_path}")

    # Clean existing files
    if dest_path.exists():
        print("🗑️  Cleaning existing files...")
        shutil.rmtree(dest_path)
        dest_path.mkdir(parents=True, exist_ok=True)
    else:
        dest_path.mkdir(parents=True, exist_ok=True)

    # Copy files
    print("📋 Copying PWA files...")
    # Only copy PWA-related files/directories
    allowed_items = {
        "assets",
        "canvaskit",
        "icons",
        "index.html",
        "main.dart.js",
        "main.dart.mjs",
        "main.dart.wasm",
        "main.dart.wasm.map",
        "favicon.png",
        "flutter.js",
        "flutter_bootstrap.js",
        "flutter_service_worker.js",
        "manifest.json",
        "version.json",
    }

    for item in pwa_path.iterdir():
        if item.name == ".last_build_id":
            continue
        # Skip items that aren't part of PWA
        if item.name not in allowed_items:
            print(f"   ⏭️  Skipping: {item.name}")
            continue
        if item.is_dir():
            shutil.copytree(item, dest_path / item.name, dirs_exist_ok=True)
        else:
            shutil.copy2(item, dest_path / item.name)

    # Fix base href
    index_html = dest_path / "index.html"
    if index_html.exists():
        print("🔧 Fixing base href...")
        _fix_base_href(index_html)
        print("   ✅ Base href set to: /static/luteformobile/")

    return True


def deploy_to_docker(lute_info, pwa_path):
    """Deploy PWA to Docker container."""
    container_name = lute_info["container_name"]

    print(f"\n🐳 Deploying to Docker container: {container_name}")

    # Check if static exists in container
    result = subprocess.run(
        ["docker", "exec", container_name, "test", "-d", "/lute/static"],
        capture_output=True,
    )

    if result.returncode == 0:
        # Use /lute/static
        container_static = "/lute/static"
    else:
        # Try /lute-data/web
        result = subprocess.run(
            ["docker", "exec", container_name, "test", "-d", "/lute-data/web"],
            capture_output=True,
        )
        if result.returncode == 0:
            container_static = "/lute-data/web"
        else:
            print("❌ Could not find static directory in container")
            return False

    dest_path = f"{container_static}/luteformobile"

    # Clean existing files
    print("🗑️  Cleaning existing files...")
    subprocess.run(
        ["docker", "exec", container_name, "rm", "-rf", dest_path], check=True
    )

    # Create directory in container
    print(f"📂 Creating directory: {dest_path}")
    subprocess.run(
        ["docker", "exec", container_name, "mkdir", "-p", dest_path], check=True
    )

    # Copy files (only PWA-related items)
    print("📋 Copying PWA files...")
    allowed_items = {
        "assets",
        "canvaskit",
        "icons",
        "index.html",
        "main.dart.js",
        "main.dart.mjs",
        "main.dart.wasm",
        "main.dart.wasm.map",
        "favicon.png",
        "flutter.js",
        "flutter_bootstrap.js",
        "flutter_service_worker.js",
        "manifest.json",
        "version.json",
    }

    for item in pwa_path.iterdir():
        if item.name == ".last_build_id":
            continue
        if item.name not in allowed_items:
            print(f"   ⏭️  Skipping: {item.name}")
            continue
        # Copy each item to container
        container_item_path = f"{container_name}:{dest_path}/{item.name}"
        subprocess.run(["docker", "cp", str(item), container_item_path], check=True)

    # Fix base href
    print("🔧 Fixing base href...")
    subprocess.run(
        [
            "docker",
            "exec",
            container_name,
            "sed",
            "-E",
            "-i",
            r's|<base[[:space:]]+href="[^"]*"[[:space:]]*/?>|<base href="/static/luteformobile/" />|',
            f"{dest_path}/index.html",
        ],
        check=True,
    )

    print("   ✅ Base href set to: /static/luteformobile/")

    return True


def deploy_to_source(lute_info, pwa_path):
    """Deploy PWA to source installation."""
    static_path = lute_info["static_path"]
    dest_path = static_path / "luteformobile"

    print(f"\n📂 Deploying to: {dest_path}")

    # Clean existing files
    if dest_path.exists():
        print("🗑️  Cleaning existing files...")
        shutil.rmtree(dest_path)
        dest_path.mkdir(parents=True, exist_ok=True)
    else:
        dest_path.mkdir(parents=True, exist_ok=True)

    # Copy files
    print("📋 Copying PWA files...")
    # Only copy PWA-related files/directories
    allowed_items = {
        "assets",
        "canvaskit",
        "icons",
        "index.html",
        "main.dart.js",
        "main.dart.mjs",
        "main.dart.wasm",
        "main.dart.wasm.map",
        "favicon.png",
        "flutter.js",
        "flutter_bootstrap.js",
        "flutter_service_worker.js",
        "manifest.json",
        "version.json",
    }

    for item in pwa_path.iterdir():
        if item.name == ".last_build_id":
            continue
        # Skip items that aren't part of PWA
        if item.name not in allowed_items:
            print(f"   ⏭️  Skipping: {item.name}")
            continue
        if item.is_dir():
            shutil.copytree(item, dest_path / item.name, dirs_exist_ok=True)
        else:
            shutil.copy2(item, dest_path / item.name)

    # Fix base href
    index_html = dest_path / "index.html"
    if index_html.exists():
        print("🔧 Fixing base href...")
        _fix_base_href(index_html)
        print("   ✅ Base href set to: /static/luteformobile/")

    return True


def main():
    print("=" * 60)
    print("  LuteForMobile PWA Setup")
    print("=" * 60)
    print()

    # Get PWA path
    script_dir = Path(__file__).parent

    # Check if we're in the PWA directory
    if (script_dir / "index.html").exists() and (script_dir / "main.dart.js").exists():
        pwa_path = script_dir
        print(f"✅ Found PWA files at: {pwa_path}")
    else:
        # Try build/web directory
        build_web = script_dir / "build" / "web"
        if build_web.exists():
            pwa_path = build_web
            print(f"✅ Found PWA files at: {pwa_path}")
        else:
            print("❌ Could not find PWA files")
            print("   Please run this script from the PWA directory or lute-pwa folder")
            sys.exit(1)

    # Find Lute installation
    lute_info = find_lute_installation()

    if not lute_info:
        print("\n❌ Could not find Lute installation")
        print("\nPlease install Lute first:")
        print("   pip install lute3")
        print("\nOr if using source, navigate to the lute directory")
        sys.exit(1)

    # Deploy based on installation type
    lute_type = lute_info["type"]

    print(f"\n🚀 Deploying PWA (installation type: {lute_type})")

    if lute_type == "venv":
        success = deploy_to_venv(lute_info, pwa_path)
    elif lute_type == "docker":
        success = deploy_to_docker(lute_info, pwa_path)
    elif lute_type == "source":
        success = deploy_to_source(lute_info, pwa_path)
    else:
        print(f"❌ Unknown installation type: {lute_type}")
        sys.exit(1)

    if success:
        print("\n" + "=" * 60)
        print("  ✅ Deployment Complete!")
        print("=" * 60)
        print()
        print("📱 Access your PWA at:")
        print("   http://YOUR_LUTE_IP:5001/static/luteformobile/index.html")
        print()
        print("⚙️  In the app, set Server URL to:")
        print("   http://YOUR_LUTE_IP:5001/")
        print()
        print("📖 For more info, see PWA_SETUP_GUIDE.md")
        print()


if __name__ == "__main__":
    main()
