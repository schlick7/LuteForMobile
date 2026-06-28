"""
Launcher for the on-device lute-v3 server.

Called by the Android Kotlin bridge via Chaquopy. We:
  1. Capture stdout/stderr into a thread-safe ring buffer so the
     Kotlin bridge can show the last N log lines for debugging.
  2. Spawn a background daemon thread that runs `lute.main.start(...)`.
  3. Return a handle object the Kotlin side can poll, stop, and read
     logs from.

Chaquopy redirects the original sys.stdout/sys.stderr to logcat
(tags `python.stdout` / `python.stderr`), so the lines we tee to
the original stream also appear in `adb logcat`.
"""

import os
import sys
import threading
import time
import traceback
from collections import deque


# Number of log lines kept in the ring buffer.
LOG_BUFFER_SIZE = 200


class _LogCapture:
    """Thread-safe ring buffer + tee to original stream.

    The original stream is whatever Chaquopy has wired sys.stdout to;
    writing to it preserves the logcat redirect, so we don't lose
    output to `adb logcat`.
    """

    def __init__(self, original):
        self._original = original
        self._lock = threading.Lock()
        self._buf = deque(maxlen=LOG_BUFFER_SIZE)

    def write(self, msg):
        if not msg:
            return
        # Tee to the original stream (preserves logcat redirection).
        try:
            self._original.write(msg)
        except Exception:
            pass
        # Split multi-line messages and append each line.
        for line in (msg.splitlines() or [msg]):
            with self._lock:
                self._buf.append(line)

    def flush(self):
        try:
            self._original.flush()
        except Exception:
            pass

    def lines(self):
        with self._lock:
            return list(self._buf)


class _ServerHandle:
    """Thread-safe handle returned to the Kotlin caller."""

    def __init__(self, port, thread, stop_event, log_capture):
        self._port = port
        self._thread = thread
        self._stop_event = stop_event
        self._log = log_capture
        self._error = None
        self._ready_event = threading.Event()

    def is_alive(self):
        if self._stop_event.is_set():
            return False
        return self._thread.is_alive()

    def port(self):
        return self._port

    def stop(self):
        self._stop_event.set()
        self._thread.join(timeout=5.0)

    def last_error(self):
        return self._error

    def log_lines(self):
        return self._log.lines()

    def mark_ready(self):
        self._ready_event.set()

    def is_ready(self):
        return self._ready_event.is_set()


def _run_lute(port, datapath, config_path, stop_event, log_capture, handle):
    """Body of the server thread. Installs log capture, runs lute."""

    # Replace sys.stdout/sys.stderr with a tee that captures into our
    # ring buffer while still forwarding to the original (which goes
    # to logcat).
    sys.stdout = _LogCapture(sys.stdout)  # type: ignore[assignment]
    sys.stderr = _LogCapture(sys.stderr)  # type: ignore[assignment]

    try:
        # chdir to the data dir so any relative paths (e.g. "config.yml"
        # in lute.main) resolve there. lute reads --config and overrides
        # the default configdir, but cwd still matters for anything
        # that looks at the current directory.
        os.makedirs(datapath, exist_ok=True)
        os.chdir(datapath)
        print(f"[launcher] data dir: {datapath}")
        print(f"[launcher] config:   {config_path}")
        print(f"[launcher] port:     {port}")

        # Stub the natto (MeCab) module before importing lute. lute's
        # JapaneseParser does `from natto import MeCab` at module
        # scope, but natto is a C extension we don't ship. Installing
        # a stub lets the import succeed; lute's own is_supported()
        # check still returns False because instantiating MeCab()
        # throws, and that's caught.
        import types

        class _StubMecab:
            """Stub that mimics the natto MeCab interface enough to
            make `from natto import MeCab` succeed, but always
            raises on instantiation so lute's is_supported() check
            returns False. Supports being used as a context manager
            in case the test path doesn't go through __init__."""

            def __init__(self, *args, **kwargs):
                raise RuntimeError(
                    "MeCab is not bundled in the on-device build"
                )

            def __enter__(self):
                raise RuntimeError(
                    "MeCab is not bundled in the on-device build"
                )

            def __exit__(self, exc_type, exc, tb):
                return False

        natto_stub = types.ModuleType("natto")
        natto_stub.MeCab = _StubMecab
        sys.modules["natto"] = natto_stub
        print("[launcher] natto stub installed")

        # Skip the demo-data loader. The upstream lute-v3 v3.10.1
        # release has an empty db/language_defs/ directory, so the
        # demo data load fails with "Missing language def name Arabic".
        # The fix: install a sys.modules hook that monkey-patches
        # DemoService.should_load_demo_data to return False the moment
        # the lute.db.demo module is loaded. The first time it's called
        # is by data_initialization, by which point the hook is in
        # place.
        _demo_patched = {"value": False}

        def _patch_demo_module():
            if _demo_patched["value"]:
                return
            import lute.db.demo as _demo_mod  # noqa: PLC0415
            # In lute.db.demo, the class is named `Service`. The alias
            # `DemoService` only exists in lute.app_factory, which is
            # already loaded by now. Patching the class on the
            # source module affects all references including the alias.
            _demo_mod.Service.should_load_demo_data = lambda self: False
            _demo_patched["value"] = True
            print("[launcher] demo-data loader disabled")

        # Install a post-import hook: wrap any MetaPathFinder's loader
        # for "lute.db.demo" so our patch runs after the module loads.
        class _DemoPatcherFinder:
            def find_spec(self, name, path, target=None):
                if name != "lute.db.demo" or _demo_patched["value"]:
                    return None
                for finder in sys.meta_path:
                    if finder is self:
                        continue
                    if not hasattr(finder, "find_spec"):
                        continue
                    spec = finder.find_spec(name, path, target)
                    if spec is None or spec.loader is None:
                        continue

                    original_loader = spec.loader

                    class _WrappedLoader:
                        def create_module(self, spec):
                            return None

                        def exec_module(self, module):
                            original_loader.exec_module(module)
                            _patch_demo_module()

                    spec.loader = _WrappedLoader()
                    return spec
                return None

        sys.meta_path.insert(0, _DemoPatcherFinder())

        # Build the argv lute expects.
        sys.argv = [
            "lute",
            "--local",  # bind to 127.0.0.1, not 0.0.0.0
            "--port", str(port),
            "--config", config_path,
        ]

        # Importing lute.main starts the parse machinery; do it now
        # so any import-time errors surface here rather than in the
        # background thread. lute's Japanese parser (MeCab/natto) is
        # not in our Chaquopy build, but lute handles that gracefully
        # by returning is_supported()=False and filtering Japanese
        # out of supported_parsers() at startup.
        print("[launcher] importing lute.main…")
        from lute.main import start as _lute_start
        print("[launcher] lute.main imported OK")

        # Install a wakeup hook on the stop_event so waitress exits
        # promptly when stop() is called.
        _wakeup_thread = threading.Thread(
            target=_wakeup_loop, args=(port, stop_event), daemon=True
        )
        _wakeup_thread.start()

        # Mark the handle as ready so Kotlin knows the server is up
        # *before* it polls /info. Belt-and-suspenders; the /info poll
        # is the real signal.
        handle.mark_ready()
        print("[launcher] starting waitress…")

        # Run lute. This blocks until the waitress server exits.
        _lute_start()
        print("[launcher] waitress exited cleanly")

    except SystemExit:
        # waitress calls sys.exit(0) on clean shutdown.
        pass
    except Exception as e:
        traceback.print_exc()
        handle._error = "{}: {}".format(type(e).__name__, e)
        print("[launcher] FATAL: " + handle._error, file=sys.stderr)


def _wakeup_loop(port, stop_event):
    """
    While the server is running, periodically connect to localhost:<port>
    to nudge waitress's accept() loop. When stop_event fires, do a
    final connect to trigger an exit.
    """
    import socket
    while not stop_event.is_set():
        time.sleep(0.5)
    try:
        s = socket.socket()
        s.settimeout(1.0)
        s.connect(("127.0.0.1", port))
        s.close()
    except Exception:
        pass


_ServerHandle._current = None


def start(port, datapath, config_path):
    """
    Spawn lute.main in a background thread and return a handle.
    """
    stop_event = threading.Event()
    log_capture = _LogCapture(sys.stdout)
    handle = _ServerHandle(port, None, stop_event, log_capture)
    thread = threading.Thread(
        target=_run_lute,
        args=(port, datapath, config_path, stop_event, log_capture, handle),
        name="lute-server",
        daemon=True,
    )
    handle._thread = thread
    _ServerHandle._current = handle
    thread.start()
    return handle


def callMirrorImages(src_dir, dst_dir):
    """
    Mirror src_dir into dst_dir by running `cp` as a subprocess.
    Chaquopy's Python can't create files in the backup subdir
    (SELinux denial) but a subprocess of `cp` runs in a context
    that has write permission. Returns True on success.
    """
    import os
    import subprocess
    if not os.path.isdir(src_dir):
        return False
    os.makedirs(dst_dir, exist_ok=True)
    try:
        # `cp -a` preserves perms and recursive; trailing /. copies
        # contents (not the dir itself) into the destination.
        result = subprocess.run(
            ["cp", "-a", src_dir + "/.", dst_dir + "/"],
            check=False,
            capture_output=True,
        )
        if result.returncode != 0:
            print(
                f"callMirrorImages: cp failed: {result.stderr.decode(errors='replace')}",
                file=__import__("sys").stderr,
            )
            return False
        return True
    except Exception as e:
        print(f"callMirrorImages: {e}", file=__import__("sys").stderr)
        return False
