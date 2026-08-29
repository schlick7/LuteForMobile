package com.schlick7.luteformobile

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

/**
 * MethodChannel bridge for the on-device lute-v3 server.
 *
 * The server is bundled into the APK via the Chaquopy Gradle plugin
 * (see android/app/build.gradle.kts). On start, we hand a port and
 * the user's data dir to the Python `launcher` module, which spawns
 * waitress in a background thread. The Dart side polls GET /info on
 * 127.0.0.1:<port> until ready, then uses that URL as the API base.
 *
 * Channel:  com.schlick7.luteformobile/embedded_server
 * Events:   com.schlick7.luteformobile/embedded_server_progress
 *
 * Methods:
 *  - getState()       -> { state, port, installedVersion }
 *  - start()          -> port (server URL is http://127.0.0.1:<port>/)
 *  - stop()           -> null
 *  - dataDir()        -> absolute path of the lute data dir
 */
class EmbeddedServerBridge(
    private val context: Context,
) {
    companion object {
        private const val TAG = "EmbeddedServerBridge"
        const val METHOD_CHANNEL = "com.schlick7.luteformobile/embedded_server"
        const val EVENT_CHANNEL = "com.schlick7.luteformobile/embedded_server_progress"
        private const val STARTUP_TIMEOUT_MS = 30_000L
        private const val POLL_INTERVAL_MS = 250L
        private const val SHUTDOWN_GRACE_MS = 5_000L
        private const val LAUNCHER_MODULE = "launcher"
        private const val SERVER_STATE_KEY = "lute_server_running"

        // Bundled lute-v3 version, must match lute/__init__.py
        // __version__ and Settings.luteServerPinnedVersion on the
        // Dart side. Returned in getState so the Dart side knows
        // the server artifact is present and can auto-start on
        // app launch when on-device mode is selected.
        private const val INSTALLED_VERSION = "3.10.3"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var serverProcess: PyObject? = null
    private var port: Int? = null
    private val isStarting = AtomicBoolean(false)

    /** Underlying lute data dir. Lives in app-private filesDir. */
    private val luteDataDir: File by lazy {
        File(context.filesDir, "lute")
    }

    /** Auto-generated config.yml. Created on first start. */
    private val luteConfigFile: File by lazy {
        File(luteDataDir, "config.yml")
    }

    fun register(
        methodChannel: MethodChannel,
        eventChannel: EventChannel,
    ) {
        ensurePythonStarted()

        methodChannel.setMethodCallHandler { call, result -> onMethodCall(call, result) }
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    fun dispose() {
        try {
            stop()
        } catch (_: Exception) {
        }
    }

    /**
     * Start polling the Python log buffer every second and forwarding
     * new lines through the EventChannel as `log` events. Stops when
     * the EventChannel is cancelled (e.g. UI page closes) or the
     * server exits.
     */
    private fun startLogPoller() {
        // Track the last index we've emitted so we don't repeat lines.
        var lastEmittedIndex = 0
        val pollRunnable = object : Runnable {
            override fun run() {
                val lines = readLogLines()
                // Emit only lines we haven't sent yet.
                if (lastEmittedIndex < lines.size) {
                    for (i in lastEmittedIndex until lines.size) {
                        emit("log", mapOf("line" to lines[i]))
                    }
                    lastEmittedIndex = lines.size
                }
                // Continue polling as long as the sink is active and
                // we have something to do.
                if (eventSink != null && isServerAlive()) {
                    mainHandler.postDelayed(this, 1000L)
                }
            }
        }
        mainHandler.postDelayed(pollRunnable, 500L)
    }

    // --- Python startup ---

    private fun ensurePythonStarted() {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(context))
            Log.d(TAG, "Chaquopy Python runtime started")
        }
    }

    // --- State ---

    private fun currentState(): Map<String, Any?> {
        val state = when {
            isStarting.get() -> "starting"
            serverProcess != null && isServerAlive() -> "running"
            else -> "ready"
        }
        return mapOf(
            "state" to state,
            "port" to port,
            "installedVersion" to INSTALLED_VERSION,
        )
    }

    /// Read the last N log lines captured from the Python server's
    /// stdout/stderr. Used by the UI to surface "why did it fail".
    private fun readLogLines(): List<String> {
        val proc = serverProcess ?: return emptyList()
        return try {
            @Suppress("UNCHECKED_CAST")
            proc.callAttr("log_lines").asList() as List<String>
        } catch (e: Exception) {
            Log.w(TAG, "readLogLines failed: ${e.message}")
            emptyList()
        }
    }

    private fun isServerAlive(): Boolean {
        val proc = serverProcess ?: return false
        return try {
            // Call launcher.is_alive(); returns True until stop() is called.
            proc.callAttr("is_alive").toBoolean()
        } catch (e: Exception) {
            Log.w(TAG, "is_alive check failed: ${e.message}")
            false
        }
    }

    // --- Method dispatch ---

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getState" -> result.success(currentState())
            "getLogs" -> result.success(readLogLines())
            "dataDir" -> {
                luteDataDir.mkdirs()
                result.success(luteDataDir.absolutePath)
            }
            "restoreBackup" -> {
                val gzPath = call.argument<String>("path")
                if (gzPath == null) {
                    result.error("BAD_ARGS", "Missing 'path'", null)
                    return
                }
                Thread({
                    val ok = doRestoreBackup(gzPath)
                    mainHandler.post { result.success(ok) }
                }, "lute-restore").start()
            }
            "start" -> {
                if (isStarting.getAndSet(true)) {
                    result.error("ALREADY_STARTING", "Server is already starting", null)
                    return
                }
                Thread({
                    try {
                        val p = doStart()
                        port = p
                        emit("started", mapOf("port" to p))
                        mainHandler.post { result.success(p) }
                    } catch (e: Exception) {
                        Log.e(TAG, "start failed", e)
                        emit("error", mapOf("message" to (e.message ?: e.toString())))
                        mainHandler.post { result.error("START_FAILED", e.message, null) }
                    } finally {
                        isStarting.set(false)
                    }
                }, "lute-server-start").start()
            }
            "stop" -> {
                try {
                    stop()
                    emit("stopped", mapOf("exitCode" to 0))
                    result.success(null)
                } catch (e: Exception) {
                    result.error("STOP_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    // --- Start / stop ---

    private fun doStart(): Int {
        // Pre-create the data dir and config if missing.
        if (!luteDataDir.exists() && !luteDataDir.mkdirs()) {
            throw IllegalStateException("Could not create ${luteDataDir.absolutePath}")
        }
        ensureConfig()

        // Pick a free port.
        val pickedPort = pickFreePort()

        // Hand off to the Python launcher. We pass `this` so Python can call
        // back into the main app process (e.g. mirror images into the
        // backup dir, which Chaquopy's Python cannot write to).
        val py = Python.getInstance()
        val launcher = py.getModule(LAUNCHER_MODULE)
        val handle = launcher.callAttr(
            "start",
            pickedPort,
            luteDataDir.absolutePath,
            luteConfigFile.absolutePath,
            this,
        )
        serverProcess = handle
        startLogPoller()

        // Poll /info on 127.0.0.1:<pickedPort> until 200.
        val deadline = System.currentTimeMillis() + STARTUP_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline) {
            if (!isServerAlive()) {
                throw IllegalStateException("lute-server exited before becoming ready")
            }
            if (isReady(pickedPort)) {
                Log.d(TAG, "lute-server ready on port $pickedPort")
                return pickedPort
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
        // Timed out. Tear down.
        stop()
        throw IllegalStateException(
            "lute-server did not respond to /info within ${STARTUP_TIMEOUT_MS}ms"
        )
    }

    private fun stop() {
        val proc = serverProcess ?: return
        serverProcess = null
        port = null
        try {
            proc.callAttr("stop")
        } catch (e: Exception) {
            Log.w(TAG, "Python stop() raised: ${e.message}")
        }
    }

    private fun isReady(port: Int): Boolean {
        return try {
            val conn = URL("http://127.0.0.1:$port/info").openConnection()
                    as HttpURLConnection
            conn.connectTimeout = 1000
            conn.readTimeout = 1000
            conn.requestMethod = "GET"
            val code = conn.responseCode
            conn.disconnect()
            code in 200..299
        } catch (e: Exception) {
            false
        }
    }

    /** Pick a free localhost port via ServerSocket(0). */
    private fun pickFreePort(): Int {
        java.net.ServerSocket(0).use { return it.localPort }
    }

    /**
     * Restore a lute.db from a gzipped sqlite dump.
     *
     * The gz file is decompressed and validated:
     *  - must start with the gzip magic (0x1f 0x8b)
     *  - decompressed contents must start with "SQLite format 3"
     *
     * On success, atomically replaces `<dataDir>/lute.db` and
     * returns true. On any failure (bad file, IO error, validation
     * failure) returns false and leaves the existing lute.db in
     * place. The caller is expected to have already stopped the
     * embedded server before calling this.
     */
    private fun doRestoreBackup(gzPath: String): Boolean {
        return try {
            val gzFile = File(gzPath)
            if (!gzFile.exists() || !gzFile.canRead()) {
                Log.w(TAG, "restoreBackup: cannot read $gzPath")
                return false
            }

            // Decompress in a streaming way to keep memory low.
            val sqliteBytes = java.io.ByteArrayOutputStream()
            java.util.zip.GZIPInputStream(gzFile.inputStream().buffered()).use { gz ->
                gz.copyTo(sqliteBytes)
            }
            val bytes = sqliteBytes.toByteArray()
            if (bytes.size < 16) {
                Log.w(TAG, "restoreBackup: decompressed too small")
                return false
            }

            // Validate: must be a sqlite file.
            val magic = "SQLite format 3".toByteArray(Charsets.US_ASCII)
            for (i in magic.indices) {
                if (bytes[i] != magic[i]) {
                    Log.w(TAG, "restoreBackup: not a sqlite db (magic mismatch at $i)")
                    return false
                }
            }

            // Atomically replace lute.db. writeBytes + force(true) +
            // rename gives us crash-safe replacement: even if the
            // process dies after writeBytes but before rename, the
            // existing lute.db is intact and the .tmp is partial.
            val target = File(luteDataDir, "lute.db")
            val tmp = File(luteDataDir, "lute.db.restore.tmp")
            val fos = java.io.FileOutputStream(tmp)
            try {
                fos.write(bytes)
                fos.fd.sync()
            } finally {
                fos.close()
            }
            if (target.exists()) target.delete()
            if (!tmp.renameTo(target)) {
                Log.w(TAG, "restoreBackup: rename failed")
                tmp.delete()
                return false
            }
            Log.d(TAG, "restoreBackup: replaced lute.db (${bytes.size} bytes)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "restoreBackup failed", e)
            false
        }
    }

    /**
     * Write a config.yml for lute, pointing DATAPATH at the data dir.
     * This is auto-generated on first run; users don't edit it.
     */
    private fun ensureConfig() {
        if (luteConfigFile.exists()) return

        val template = """
            ENV: prod
            IS_DOCKER: false
            DBNAME: lute.db
            DATAPATH: ${luteDataDir.absolutePath}
            BACKUP_PATH: ${luteDataDir.absolutePath}/backups
            """.trimIndent() + "\n"

        luteConfigFile.writeText(template)
        Log.d(TAG, "Wrote config to ${luteConfigFile.absolutePath}")
    }

    /**
     * Copy a directory tree from the main app process.
     *
     * Called from the on-device Python backup flow via the bridge
     * object passed into `launcher.start(...)`. Chaquopy's Python
     * process cannot create files inside
     * `<dataDir>/backups/userimages_backup/` (EACCES) even though it
     * shares the app UID/process, but the main process can — so the
     * image mirror is done here.
     */
    fun mirrorImages(srcDir: String, dstDir: String): Boolean {
        return try {
            val src = File(srcDir)
            if (!src.isDirectory) {
                Log.d(TAG, "mirrorImages: src not a dir ($srcDir); nothing to do")
                return true
            }
            val dst = File(dstDir)
            copyDirRecursive(src, dst)
            Log.d(TAG, "mirrorImages: $srcDir -> $dstDir OK")
            true
        } catch (e: Exception) {
            Log.e(TAG, "mirrorImages failed: ${e.message}", e)
            false
        }
    }

    private fun copyDirRecursive(src: File, dst: File) {
        if (!dst.exists()) dst.mkdirs()
        src.listFiles()?.forEach { child ->
            val target = File(dst, child.name)
            if (child.isDirectory) {
                copyDirRecursive(child, target)
            } else {
                child.inputStream().use { input ->
                    target.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }
    }

    // --- Event sink ---

    private fun emit(type: String, data: Map<String, Any?>) {
        val sink = eventSink ?: return
        val payload = HashMap<String, Any?>(data.size + 1)
        payload["type"] = type
        payload.putAll(data)
        mainHandler.post { sink.success(payload) }
    }
}
