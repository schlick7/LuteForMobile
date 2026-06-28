"""
Bridge between Python (Chaquopy) and the Kotlin host process.

The Chaquopy Python runtime runs in a different SELinux context
than the main app process. Some filesystem operations (like
creating files inside subdirs of <dataDir>/backups/) fail with
EACCES from Python even though they would succeed from Kotlin.

This module provides Python-callable helpers that delegate the
restricted operations to the Kotlin side, which has full fs
access. The Kotlin side is reached via the same Python module
the launcher uses to spawn the server.
"""

import os
import sys

_BRIDGE = None


def _get_bridge():
    global _BRIDGE
    if _BRIDGE is None:
        from com.chaquo.python import Python
        py = Python.getInstance()
        _BRIDGE = py.getModule("bridge")
    return _BRIDGE


def mirror_images_from_kotlin(src_dir, dst_dir):
    """Mirror src_dir into dst_dir using the Kotlin host process.

    Returns True on success, False on failure. The Kotlin side
    (EmbeddedServerBridgeKt or similar) must expose a callable
    Python entry point that takes the two directory paths and
    does a recursive copy.
    """
    try:
        bridge = _get_bridge()
        # The Kotlin launcher module has a callMirrorImages(src, dst)
        # entry point. See launcher.py.
        fn = getattr(bridge, "callMirrorImages", None)
        if fn is None:
            return False
        ok = fn(src_dir, dst_dir)
        return bool(ok)
    except Exception as e:
        print(f"bridge.mirror_images_from_kotlin failed: {e}", file=sys.stderr)
        return False
