#!/usr/bin/env python3
"""
LuteForMobile PWA Setup Script
Automates deploying PWA files to your Lute server installation.
"""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


BASE_HREF = "/static/luteformobile/"
DEPLOY_DIR_NAME = "luteformobile"
REQUIRED_PWA_FILES = {"index.html"}
ALLOWED_ITEMS = {
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
        updated, count = re.subn(
            r"<head(\s[^>]*)?>",
            lambda match: f'{match.group(0)}\n    <base href="{base_href}" />',
            content,
            count=1,
            flags=re.IGNORECASE,
        )
        if count == 0:
            raise ValueError(f"Could not find <base> or <head> in {index_html_path}")

    with open(index_html_path, "w", encoding="utf-8") as f:
        f.write(updated)


def _validate_pwa_path(pwa_path):
    """Validate that the path looks like a Flutter web build."""
    missing = sorted(
        name for name in REQUIRED_PWA_FILES if not (pwa_path / name).exists()
    )
    if missing:
        raise FileNotFoundError(
            f"Missing required PWA files in {pwa_path}: {', '.join(missing)}"
        )

    has_entrypoint = any(
        (pwa_path / name).exists()
        for name in ("main.dart.js", "main.dart.mjs", "main.dart.wasm")
    )
    if not has_entrypoint:
        raise FileNotFoundError(
            f"Could not find a Flutter web entrypoint in {pwa_path} "
            "(expected main.dart.js, main.dart.mjs, or main.dart.wasm)"
        )


def _copy_allowed_pwa_items(pwa_path, dest_path):
    """Copy only the files/directories needed for a Flutter web deployment."""
    _validate_pwa_path(pwa_path)

    for item in pwa_path.iterdir():
        if item.name == ".last_build_id":
            continue
        if item.name not in ALLOWED_ITEMS:
            print(f"   Skipping: {item.name}")
            continue
        if item.is_dir():
            shutil.copytree(item, dest_path / item.name, dirs_exist_ok=True)
        else:
            shutil.copy2(item, dest_path / item.name)

    _validate_pwa_path(dest_path)


def _prepare_local_dest(static_path):
    dest_path = static_path / DEPLOY_DIR_NAME
    print(f"\nDeploying to: {dest_path}")

    if dest_path.exists():
        print("Cleaning existing files...")
        shutil.rmtree(dest_path)
    dest_path.mkdir(parents=True, exist_ok=True)
    return dest_path


def _find_static_in_venv(venv_path):
    """Find lute/static inside a virtualenv on Unix-like systems or Windows."""
    candidates = list((venv_path / "lib").glob("python*/site-packages/lute/static"))
    candidates.append(venv_path / "Lib" / "site-packages" / "lute" / "static")

    for candidate in candidates:
        if candidate.exists():
            return candidate

    return None


def find_lute_installation():
    """Find where Lute is installed."""
    print("Detecting Lute installation...")

    # Check for pip/venv installation
    lute_venv_paths = [
        Path.home() / "my_lute",
        Path.home() / "lute",
        Path.home() / ".lute",
    ]

    for base_path in lute_venv_paths:
        if not base_path.exists():
            continue

        for venv_name in ("myenv", ".venv", "venv", "env"):
            venv_path = base_path / venv_name
            if not venv_path.exists():
                continue

            static_path = _find_static_in_venv(venv_path)
            if static_path:
                print(f"Found Lute at: {base_path} (venv: {venv_name})")
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
            container_names = result.stdout.splitlines()
            if len(container_names) > 1:
                exact_matches = [name for name in container_names if name == "lute"]
                if len(exact_matches) == 1:
                    container_name = exact_matches[0]
                else:
                    print("Found multiple Docker containers matching 'lute':")
                    for name in container_names:
                        print(f"   {name}")
                    print("Please stop extra containers or rename one to exactly 'lute'.")
                    return None
            else:
                container_name = container_names[0]
            print(f"Found Docker container: {container_name}")
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
            print(f"Found Lute source at: {source_path}")
            return {
                "type": "source",
                "static_path": static_path,
                "lute_path": source_path,
            }

    print("Could not find Lute installation")
    return None


def deploy_to_venv(lute_info, pwa_path):
    """Deploy PWA to venv installation."""
    dest_path = _prepare_local_dest(lute_info["static_path"])

    # Copy files
    print("Copying PWA files...")
    _copy_allowed_pwa_items(pwa_path, dest_path)

    # Fix base href
    index_html = dest_path / "index.html"
    print("Fixing base href...")
    _fix_base_href(index_html, BASE_HREF)
    print(f"   Base href set to: {BASE_HREF}")

    return True


def deploy_to_docker(lute_info, pwa_path):
    """Deploy PWA to Docker container."""
    container_name = lute_info["container_name"]

    print(f"\nDeploying to Docker container: {container_name}")
    _validate_pwa_path(pwa_path)

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
            print("Could not find static directory in container")
            return False

    dest_path = f"{container_static}/{DEPLOY_DIR_NAME}"

    # Clean existing files
    print("Cleaning existing files...")
    subprocess.run(
        ["docker", "exec", container_name, "rm", "-rf", dest_path], check=True
    )

    # Create directory in container
    print(f"Creating directory: {dest_path}")
    subprocess.run(
        ["docker", "exec", container_name, "mkdir", "-p", dest_path], check=True
    )

    # Copy files (only PWA-related items)
    print("Copying PWA files...")
    for item in pwa_path.iterdir():
        if item.name == ".last_build_id":
            continue
        if item.name not in ALLOWED_ITEMS:
            print(f"   Skipping: {item.name}")
            continue
        # Copy each item to container
        container_item_path = f"{container_name}:{dest_path}/{item.name}"
        subprocess.run(["docker", "cp", str(item), container_item_path], check=True)

    # Fix base href locally to avoid relying on sed inside the container.
    print("Fixing base href...")
    with tempfile.TemporaryDirectory() as temp_dir:
        local_index = Path(temp_dir) / "index.html"
        subprocess.run(
            [
                "docker",
                "cp",
                f"{container_name}:{dest_path}/index.html",
                str(local_index),
            ],
            check=True,
        )
        _fix_base_href(local_index, BASE_HREF)
        subprocess.run(
            [
                "docker",
                "cp",
                str(local_index),
                f"{container_name}:{dest_path}/index.html",
            ],
            check=True,
        )

    print(f"   Base href set to: {BASE_HREF}")

    return True


def deploy_to_source(lute_info, pwa_path):
    """Deploy PWA to source installation."""
    dest_path = _prepare_local_dest(lute_info["static_path"])

    # Copy files
    print("Copying PWA files...")
    _copy_allowed_pwa_items(pwa_path, dest_path)

    # Fix base href
    index_html = dest_path / "index.html"
    print("Fixing base href...")
    _fix_base_href(index_html, BASE_HREF)
    print(f"   Base href set to: {BASE_HREF}")

    return True


def main():
    print("=" * 60)
    print("  LuteForMobile PWA Setup")
    print("=" * 60)
    print()

    # Get PWA path
    script_dir = Path(__file__).parent

    # Check if we're in the PWA directory
    if (script_dir / "index.html").exists() and any(
        (script_dir / name).exists()
        for name in ("main.dart.js", "main.dart.mjs", "main.dart.wasm")
    ):
        pwa_path = script_dir
        print(f"Found PWA files at: {pwa_path}")
    else:
        # Try build/web directory
        build_web = script_dir / "build" / "web"
        if build_web.exists():
            pwa_path = build_web
            print(f"Found PWA files at: {pwa_path}")
        else:
            print("Could not find PWA files")
            print("   Please run this script from the PWA directory or lute-pwa folder")
            sys.exit(1)

    try:
        _validate_pwa_path(pwa_path)
    except FileNotFoundError as error:
        print(f"Invalid PWA files: {error}")
        sys.exit(1)

    # Find Lute installation
    lute_info = find_lute_installation()

    if not lute_info:
        print("\nCould not find Lute installation")
        print("\nPlease install Lute first:")
        print("   pip install lute3")
        print("\nOr if using source, navigate to the lute directory")
        sys.exit(1)

    # Deploy based on installation type
    lute_type = lute_info["type"]

    print(f"\nDeploying PWA (installation type: {lute_type})")

    try:
        if lute_type == "venv":
            success = deploy_to_venv(lute_info, pwa_path)
        elif lute_type == "docker":
            success = deploy_to_docker(lute_info, pwa_path)
        elif lute_type == "source":
            success = deploy_to_source(lute_info, pwa_path)
        else:
            print(f"Unknown installation type: {lute_type}")
            sys.exit(1)
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"\nDeployment failed: {error}")
        sys.exit(1)

    if success:
        print("\n" + "=" * 60)
        print("  ✅ Deployment Complete!")
        print("=" * 60)
        print()
        print("Access your PWA at:")
        print("   http://YOUR_LUTE_IP:5001/static/luteformobile/index.html")
        print()
        print("⚙️  In the app, set Server URL to:")
        print("   http://YOUR_LUTE_IP:5001/")
        print()
        print("For more info, see PWA_SETUP_GUIDE.md")
        print()


if __name__ == "__main__":
    main()
