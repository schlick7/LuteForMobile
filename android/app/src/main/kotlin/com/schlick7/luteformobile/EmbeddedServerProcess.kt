package com.schlick7.luteformobile

import android.util.Log
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.ServerSocket
import java.util.concurrent.TimeUnit

/**
 * Manages the lifecycle of the on-device lute-v3 server process.
 *
 * The server is a downloaded standalone binary living at
 * <supportDir>/lute-server/<version>/lute-server. We start it with
 * `--port <picked port> --datapath <supportDir>/lute` and wait for it
 * to bind by polling GET /info on 127.0.0.1.
 *
 * On stop: SIGTERM, wait up to 5s, then SIGKILL.
 */
class EmbeddedServerProcess(
    private val installDir: File,
    private val dataDir: File,
    private val logSink: (String) -> Unit,
) {
    companion object {
        private const val TAG = "EmbeddedServerProcess"
        private const val STARTUP_TIMEOUT_SECONDS = 30L
        private const val POLL_INTERVAL_MS = 250L
        private const val SHUTDOWN_GRACE_SECONDS = 5L
    }

    @Volatile private var process: Process? = null
    @Volatile var port: Int? = null
        private set

    /**
     * Resolve a free localhost port without binding long-term: open a
     * ServerSocket on port 0, read the assigned port, close.
     */
    private fun pickFreePort(): Int {
        ServerSocket(0).use { return it.localPort }
    }

    /**
     * Start the server. Returns the bound port. Throws on failure.
     */
    fun start(): Int {
        if (process != null) {
            port?.let { return it }
            throw IllegalStateException("Process already running with unknown port")
        }

        val binary = File(installDir, "lute-server")
        if (!binary.canExecute()) {
            // Some filesystems lose the +x bit on extraction; reapply.
            if (!binary.setExecutable(true)) {
                throw IllegalStateException(
                    "Server binary not executable: ${binary.absolutePath}"
                )
            }
        }

        if (!dataDir.exists() && !dataDir.mkdirs()) {
            throw IllegalStateException(
                "Could not create data dir: ${dataDir.absolutePath}"
            )
        }

        val pickedPort = pickFreePort()
        val pb = ProcessBuilder(
            binary.absolutePath,
            "--port", pickedPort.toString(),
            "--datapath", dataDir.absolutePath,
            "--local",
        )
            .directory(installDir)
            .redirectErrorStream(true)

        val env = pb.environment()
        env["HOME"] = dataDir.parentFile?.absolutePath ?: dataDir.absolutePath
        env["LUTE_PORT"] = pickedPort.toString()
        env["LUTE_DATA_DIR"] = dataDir.absolutePath
        // The lute config.yml is auto-created on first run by the server.

        Log.d(TAG, "Starting lute-server on port $pickedPort " +
            "(binary=${binary.absolutePath}, data=${dataDir.absolutePath})")
        val started = pb.start()
        process = started

        // Drain stdout/stderr into our log sink on a background thread.
        Thread({
            try {
                BufferedReader(InputStreamReader(started.inputStream)).useLines { lines ->
                    lines.forEach { line ->
                        Log.d(TAG, "[lute-server] $line")
                        logSink(line)
                    }
                }
            } catch (e: Exception) {
                Log.d(TAG, "Log drain ended: ${e.message}")
            }
        }, "lute-server-log").apply { isDaemon = true }.start()

        // Poll for readiness.
        val deadline = System.currentTimeMillis() +
            TimeUnit.SECONDS.toMillis(STARTUP_TIMEOUT_SECONDS)
        while (System.currentTimeMillis() < deadline) {
            if (!started.isAlive) {
                process = null
                port = null
                throw IllegalStateException(
                    "lute-server exited before becoming ready (code=${started.exitValue()})"
                )
            }
            if (isReady(pickedPort)) {
                port = pickedPort
                Log.d(TAG, "lute-server ready on port $pickedPort")
                return pickedPort
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }

        // Timed out. Tear down.
        Log.e(TAG, "lute-server failed to become ready in " +
            "${STARTUP_TIMEOUT_SECONDS}s; killing")
        stop()
        throw IllegalStateException(
            "lute-server did not respond to /info within " +
                "${STARTUP_TIMEOUT_SECONDS}s"
        )
    }

    private fun isReady(port: Int): Boolean {
        return try {
            val url = java.net.URL("http://127.0.0.1:$port/info")
            val conn = url.openConnection() as java.net.HttpURLConnection
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

    /**
     * Stop the running server. Idempotent.
     */
    fun stop() {
        val p = process ?: return
        process = null
        port = null

        try {
            Log.d(TAG, "Sending SIGTERM to lute-server (pid=${p.pid()})")
            p.destroy()
        } catch (e: Exception) {
            Log.w(TAG, "destroy() failed: ${e.message}")
        }

        val deadline = System.currentTimeMillis() +
            TimeUnit.SECONDS.toMillis(SHUTDOWN_GRACE_SECONDS)
        while (p.isAlive && System.currentTimeMillis() < deadline) {
            Thread.sleep(100)
        }
        if (p.isAlive) {
            Log.w(TAG, "lute-server did not exit after " +
                "${SHUTDOWN_GRACE_SECONDS}s; SIGKILL")
            try {
                p.destroyForcibly()
            } catch (e: Exception) {
                Log.w(TAG, "destroyForcibly() failed: ${e.message}")
            }
        }
    }

    val isRunning: Boolean
        get() = process?.isAlive == true
}
