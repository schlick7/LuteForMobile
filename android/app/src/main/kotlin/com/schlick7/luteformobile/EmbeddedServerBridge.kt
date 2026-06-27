package com.schlick7.luteformobile

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream

/**
 * MethodChannel bridge for the on-device lute-v3 server.
 *
 * Channel: com.schlick7.luteformobile/embedded_server
 * EventChannel (progress): com.schlick7.luteformobile/embedded_server_progress
 *
 * Methods:
 *  - getState(): { state, installedVersion, port }
 *  - getTarballInfo(): { url, sha256Url, pinnedVersion }  (so the UI can show them)
 *  - download(): kicks off background download
 *  - cancelDownload()
 *  - start(): starts the installed server, returns the URL
 *  - stop(): stops the server
 *  - remove(): removes the installed artifact
 *  - checkForUpdate(): queries GitHub for a newer lute-server release tag
 *
 * Events (EventChannel):
 *  - { type: "download_progress", bytesDone, bytesTotal }
 *  - { type: "download_complete", installDir }
 *  - { type: "download_error", message }
 *  - { type: "started", port }
 *  - { type: "stopped", exitCode }
 *  - { type: "log", line }
 *  - { type: "error", message }
 */
class EmbeddedServerBridge(
    private val context: Context,
) {
    companion object {
        private const val TAG = "EmbeddedServerBridge"
        const val METHOD_CHANNEL = "com.schlick7.luteformobile/embedded_server"
        const val EVENT_CHANNEL = "com.schlick7.luteformobile/embedded_server_progress"
        private const val PINNED_LUTE_VERSION = "3.10.1"
        private const val GITHUB_RELEASES_API =
            "https://api.github.com/repos/schlick7/LuteForMobile/releases"
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var downloadJob: Job? = null
    private var process: EmbeddedServerProcess? = null
    private var eventSink: EventChannel.EventSink? = null
    private var appSupportDir: File? = null

    fun register(
        methodChannel: MethodChannel,
        eventChannel: EventChannel,
    ) {
        // Prefer the app's external files dir (visible to the user as
        // /Android/data/<pkg>/files) so the data is recoverable if the
        // app is uninstalled but the dir isn't cleaned. Fall back to the
        // internal files dir on devices without external storage.
        val external = context.getExternalFilesDir(null)
        appSupportDir = external ?: context.filesDir
        Log.d(TAG, "App support dir: ${appSupportDir?.absolutePath}")

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
        scope.cancel()
        process?.stop()
    }

    // --- State ---

    private fun currentState(): Map<String, Any?> {
        val support = appSupportDir ?: return mapOf("state" to "notInstalled")
        val versionDir = File(support, "lute-server/$PINNED_LUTE_VERSION")
        val installed = versionDir.exists() && File(versionDir, "lute-server").exists()
        val state = when {
            !installed -> "notInstalled"
            downloadJob?.isActive == true -> "downloading"
            process?.isRunning == true -> "running"
            else -> "ready"
        }
        return mapOf(
            "state" to state,
            "installedVersion" to if (installed) PINNED_LUTE_VERSION else null,
            "pinnedVersion" to PINNED_LUTE_VERSION,
            "port" to process?.port,
        )
    }

    // --- Method dispatch ---

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getState" -> result.success(currentState())
            "getTarballInfo" -> result.success(
                mapOf(
                    "pinnedVersion" to PINNED_LUTE_VERSION,
                    "tarballUrl" to tarballUrl(),
                    "sha256Url" to sha256Url(),
                )
            )
            "download" -> {
                if (downloadJob?.isActive == true) {
                    result.error("ALREADY_DOWNLOADING", "Download already in progress", null)
                    return
                }
                downloadJob = scope.launch { runDownload() }
                result.success(null)
            }
            "cancelDownload" -> {
                downloadJob?.cancel()
                downloadJob = null
                result.success(null)
            }
            "start" -> {
                scope.launch {
                    try {
                        val port = ensureProcess().start()
                        emit("started", mapOf("port" to port))
                        withContext(Dispatchers.Main) { result.success(port) }
                    } catch (e: Exception) {
                        Log.e(TAG, "start failed", e)
                        emit("error", mapOf("message" to (e.message ?: e.toString())))
                        withContext(Dispatchers.Main) {
                            result.error("START_FAILED", e.message, null)
                        }
                    }
                }
            }
            "stop" -> {
                try {
                    process?.stop()
                    emit("stopped", mapOf("exitCode" to 0))
                    result.success(null)
                } catch (e: Exception) {
                    result.error("STOP_FAILED", e.message, null)
                }
            }
            "remove" -> {
                scope.launch {
                    val ok = withContext(Dispatchers.IO) { removeInstalled() }
                    withContext(Dispatchers.Main) { result.success(ok) }
                }
            }
            "checkForUpdate" -> {
                scope.launch {
                    val res = withContext(Dispatchers.IO) { checkForUpdate() }
                    withContext(Dispatchers.Main) { result.success(res) }
                }
            }
            else -> result.notImplemented()
        }
    }

    // --- Process ---

    private fun ensureProcess(): EmbeddedServerProcess {
        val existing = process
        if (existing != null) return existing
        val support = appSupportDir
            ?: throw IllegalStateException("App support dir not initialized")
        val installDir = File(support, "lute-server/$PINNED_LUTE_VERSION")
        val dataDir = File(support, "lute")
        val p = EmbeddedServerProcess(installDir, dataDir) { line ->
            emit("log", mapOf("line" to line))
        }
        process = p
        return p
    }

    // --- Download ---

    private fun tarballUrl() =
        "https://github.com/schlick7/LuteForMobile/releases/download/" +
            "lute-server-v$PINNED_LUTE_VERSION/" +
            "lute-server-android-arm64-v$PINNED_LUTE_VERSION.tar.gz"

    private fun sha256Url() = "${tarballUrl()}.sha256"

    private suspend fun runDownload() {
        val support = appSupportDir
            ?: run {
                emit("download_error", mapOf("message" to "App support dir unavailable"))
                return
            }
        val cacheDir = File(support, "lute-server/.cache").apply { mkdirs() }
        val tarball = File(cacheDir, "lute-server.tar.gz")
        val shaFile = File(cacheDir, "lute-server.tar.gz.sha256")

        try {
            // 1. Fetch the SHA256 first (small file, fails fast).
            val shaUrl = sha256Url()
            Log.d(TAG, "Fetching sha256 from $shaUrl")
            val expectedSha = fetchToFile(URL(shaUrl), shaFile).trim().lowercase()
            val expectedHash = expectedSha.split(" ").first()
            Log.d(TAG, "Expected sha256: $expectedHash")

            // 2. Download the tarball with progress.
            val tarUrl = tarballUrl()
            Log.d(TAG, "Downloading $tarUrl")
            val conn = URL(tarUrl).openConnection() as HttpURLConnection
            conn.connectTimeout = 15000
            conn.readTimeout = 60000
            conn.requestMethod = "GET"
            conn.connect()
            val total = conn.contentLengthLong.takeIf { it > 0 } ?: -1L
            var done = 0L
            conn.inputStream.use { input ->
                FileOutputStream(tarball).use { output ->
                    val buf = ByteArray(64 * 1024)
                    while (true) {
                        val n = input.read(buf)
                        if (n <= 0) break
                        output.write(buf, 0, n)
                        done += n
                        if (total > 0) {
                            emit("download_progress", mapOf(
                                "bytesDone" to done,
                                "bytesTotal" to total,
                            ))
                        }
                    }
                }
            }

            // 3. Verify.
            val actualHash = sha256Of(tarball)
            if (actualHash.lowercase() != expectedHash) {
                tarball.delete()
                shaFile.delete()
                emit("download_error", mapOf(
                    "message" to "SHA256 mismatch: expected $expectedHash, got $actualHash"
                ))
                return
            }

            // 4. Remove old install (if any), then extract.
            val versionDir = File(support, "lute-server/$PINNED_LUTE_VERSION")
            if (versionDir.exists()) versionDir.deleteRecursively()
            versionDir.mkdirs()
            extractTarGz(tarball, versionDir)
            // Ensure the binary is executable after extraction.
            val binary = File(versionDir, "lute-server")
            if (binary.exists()) binary.setExecutable(true)

            // 5. Clean up.
            tarball.delete()
            shaFile.delete()

            emit("download_complete", mapOf("installDir" to versionDir.absolutePath))
        } catch (e: kotlinx.coroutines.CancellationException) {
            Log.d(TAG, "Download cancelled")
            tarball.delete()
            shaFile.delete()
            emit("download_error", mapOf("message" to "Cancelled"))
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Download failed", e)
            tarball.delete()
            shaFile.delete()
            emit("download_error", mapOf("message" to (e.message ?: e.toString())))
        } finally {
            downloadJob = null
        }
    }

    private fun fetchToFile(url: URL, dest: File): String {
        val text = StringBuilder()
        url.openStream().use { input ->
            BufferedInputStream(input).use { bis ->
                FileOutputStream(dest).use { out ->
                    val buf = ByteArray(8 * 1024)
                    while (true) {
                        val n = bis.read(buf)
                        if (n <= 0) break
                        out.write(buf, 0, n)
                        text.append(String(buf, 0, n))
                    }
                }
            }
        }
        return text.toString()
    }

    private fun sha256Of(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).use { input ->
            val buf = ByteArray(64 * 1024)
            while (true) {
                val n = input.read(buf)
                if (n <= 0) break
                md.update(buf, 0, n)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }

    private fun extractTarGz(tarGz: File, destDir: File) {
        FileInputStream(tarGz).use { fis ->
            GzipCompressorInputStream(fis).use { gzis ->
                TarArchiveInputStream(gzis).use { tais ->
                    var entry = tais.nextEntry
                    while (entry != null) {
                        val outFile = File(destDir, entry.name)
                        if (entry.isDirectory) {
                            outFile.mkdirs()
                        } else {
                            outFile.parentFile?.mkdirs()
                            FileOutputStream(outFile).use { fos ->
                                tais.copyTo(fos)
                            }
                            // Preserve executable bit if set in the tar.
                        }
                        entry = tais.nextEntry
                    }
                }
            }
        }
    }

    private fun removeInstalled(): Boolean {
        val support = appSupportDir ?: return false
        val versionDir = File(support, "lute-server/$PINNED_LUTE_VERSION")
        return if (versionDir.exists()) {
            process?.stop()
            process = null
            versionDir.deleteRecursively()
        } else true
    }

    // --- Update check ---

    private fun checkForUpdate(): Map<String, Any?> {
        // Returns { latestTag: String?, updateAvailable: bool, error: String? }
        return try {
            val conn = URL(GITHUB_RELEASES_API).openConnection() as HttpURLConnection
            conn.connectTimeout = 5000
            conn.readTimeout = 10000
            conn.requestMethod = "GET"
            conn.setRequestProperty("Accept", "application/vnd.github+json")
            conn.connect()
            if (conn.responseCode !in 200..299) {
                return mapOf(
                    "latestTag" to null,
                    "updateAvailable" to false,
                    "error" to "GitHub returned ${conn.responseCode}",
                )
            }
            val text = conn.inputStream.bufferedReader().use { it.readText() }
            // Naive scan: find any tag matching lute-server-v<ver> pattern.
            val regex = Regex("\"tag_name\"\\s*:\\s*\"(lute-server-v[^\"]+)\"")
            val matches = regex.findAll(text).map { it.groupValues[1] }.toList()
            val latest = matches.firstOrNull()
            mapOf(
                "latestTag" to latest,
                "updateAvailable" to (latest != null && latest != "lute-server-v$PINNED_LUTE_VERSION"),
                "error" to null,
            )
        } catch (e: Exception) {
            mapOf(
                "latestTag" to null,
                "updateAvailable" to false,
                "error" to (e.message ?: e.toString()),
            )
        }
    }

    // --- Event sink ---

    private fun emit(type: String, data: Map<String, Any?>) {
        val sink = eventSink ?: return
        val payload = HashMap<String, Any?>(data.size + 1)
        payload["type"] = type
        payload.putAll(data)
        sink.success(payload)
    }
}
