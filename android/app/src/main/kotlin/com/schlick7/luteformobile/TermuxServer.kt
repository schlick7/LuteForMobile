package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.delay
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class InstallationStep(val status: String, val maxWaitSeconds: Int) {
    COMPLETE("Installation complete!", 0),
    FAILED("Installation failed", 0)
}

suspend fun launchLute3ServerWithAutoShutdown(
    context: Context,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
    idleTimeoutMinutes: Int = TermuxConstants.IDLE_TIMEOUT_MINUTES
) {
    android.util.Log.i("TermuxServer", ">>> LUTE3 SERVER START REQUESTED <<<")

    // Check if server is already running first
    val serverRunning = isLute3ServerRunningHttp(port)
    android.util.Log.d("TermuxServer", "HTTP check: serverRunning=$serverRunning")
    if (serverRunning) {
        android.util.Log.d("TermuxServer", "Lute3 server is already running on port $port")
        return
    }

    android.util.Log.d("TermuxServer", "Lute3 server not running, starting...")

    // Ensure Termux is running and responsive before starting the server
    val termuxReady = TermuxLauncher.ensureTermuxRunning(context)
    if (!termuxReady) {
        android.util.Log.e("TermuxServer", "Termux is not ready, cannot start Lute3 server")
        return
    }

    android.util.Log.d("TermuxServer", "Termux is running and responsive, starting foreground service")

    try {
        val intent = TermuxForegroundService.createStartIntent(context, port, idleTimeoutMinutes)
        context.startForegroundService(intent)
        android.util.Log.d("TermuxServer", "Foreground service started successfully")
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to start foreground service: ${e.message}", e)
    }
}

suspend fun touchHeartbeat(context: Context): Boolean {
    // Instead of using file-based heartbeat, check if the server is responding
    return try {
        val success = isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)
        android.util.Log.d("TermuxServer", "Heartbeat test: ${if (success) "SUCCESS" else "FAILED"}")
        success
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Heartbeat test failed: ${e.message}")
        false
    }
}

fun stopLute3Server(context: Context) {
    android.util.Log.i("TermuxServer", ">>> LUTE3 SERVER STOP REQUESTED <<<")
    // Stop the foreground service which will also stop the Lute3 server
    val stopIntent = Intent(context, TermuxForegroundService::class.java)
    try {
        context.stopService(stopIntent)
        android.util.Log.d("TermuxServer", "Foreground service stopped")
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to stop foreground service: ${e.message}", e)
    }
}

suspend fun ensureLute3ServerRunning(
    context: Context,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
    idleTimeoutMinutes: Int = TermuxConstants.IDLE_TIMEOUT_MINUTES
): Boolean {
    android.util.Log.i("TermuxServer", ">>> ENSURE LUTE3 SERVER RUNNING <<<")
    // Check if server is running via HTTP request
    if (isLute3ServerRunningHttp(port)) {
        android.util.Log.d("TermuxServer", "Lute3 server is already running on port $port")
        return true
    }

    android.util.Log.d("TermuxServer", "Lute3 server not responding on port $port, checking if Termux is running...")

    // Check if Termux is running and responsive
    val isTermuxRunning = TermuxLauncher.isTermuxServiceRunning(context)
    if (!isTermuxRunning) {
        android.util.Log.d("TermuxServer", "Termux is not running, attempting to ensure it's running...")
        val termuxStarted = TermuxLauncher.ensureTermuxRunning(context)
        if (!termuxStarted) {
            android.util.Log.e("TermuxServer", "Failed to start Termux, cannot start Lute3 server")
            return false
        }
        delay(2000) // Give Termux a moment to fully initialize
    }

    android.util.Log.d("TermuxServer", "Lute3 server not responding on port $port, restarting...")

    // Stop any existing service first
    stopLute3Server(context)
    delay(2000) // Wait for the service to fully stop

    // Start the server again
    launchLute3ServerWithAutoShutdown(context, port, idleTimeoutMinutes)

    // Wait for the server to fully initialize before checking
    delay(5000)

    // Check if it's now running
    val isRunning = isLute3ServerRunningHttp(port)
    android.util.Log.d("TermuxServer", "Lute3 server restart result: ${if (isRunning) "SUCCESS" else "FAILED"}")

    return isRunning
}

enum class BackupType(val value: String) {
    MANUAL("manual"),
    AUTOMATIC("automatic")
}

sealed class BackupResult {
    data class Success(val message: String) : BackupResult()
    data class Error(val message: String) : BackupResult()
}

data class LuteBackup(
    val filename: String,
    val lastModified: Long,
    val size: String,
    val isManual: Boolean
)

sealed class DownloadResult {
    data class Success(val filePath: String) : DownloadResult()
    data class Error(val message: String) : DownloadResult()
}

sealed class RestoreResult {
    data class Success(val message: String) : RestoreResult()
    data class Error(val message: String) : RestoreResult()
}

sealed class SyncResult {
    data class Success(val message: String) : SyncResult()
    data class Error(val message: String) : SyncResult()
}

suspend fun triggerLute3Backup(
    context: Context,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
    backupType: BackupType = BackupType.MANUAL
): BackupResult = withContext(Dispatchers.IO) {
    return@withContext try {
        val client = OkHttpClient()
        val formBody = okhttp3.FormBody.Builder()
            .add("type", backupType.value)
            .build()

        val request = Request.Builder()
            .url("http://localhost:$port/backup/do_backup")
            .post(formBody)
            .build()

        val response = client.newCall(request).execute()

        if (response.isSuccessful) {
            val responseBody = response.body?.string()
            BackupResult.Success(responseBody ?: "Backup created successfully")
        } else {
            BackupResult.Error("Backup failed: ${response.code}")
        }
    } catch (e: Exception) {
        BackupResult.Error(e.message ?: "Unknown backup error")
    }
}

suspend fun listBackups(
    context: Context,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT
): List<LuteBackup>? = withContext(Dispatchers.IO) {
    return@withContext try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port/backup/index")
            .build()

        val response = client.newCall(request).execute()

        if (response.isSuccessful) {
            val html = response.body?.string() ?: return@withContext null
            parseBackupListFromHtml(html)
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }
}

private fun parseBackupListFromHtml(html: String): List<LuteBackup> {
    val backups = mutableListOf<LuteBackup>()
    val dateFormat = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())

    val filePattern = Regex("""(manual_)?lute_backup_\d{4}-\d{2}-\d{2}_\d{6}\.db(\.gz)?""")

    filePattern.findAll(html).forEach { match ->
        val filename = match.value
        val isManual = filename.startsWith("manual_")

        val timestampStr = Regex("""\d{4}-\d{2}-\d{2}_\d{6}""").find(filename)?.value ?: ""
        val lastModified = try {
            val sdf = SimpleDateFormat("yyyy-MM-dd_HHmmss", Locale.getDefault())
            sdf.parse(timestampStr)?.time ?: System.currentTimeMillis()
        } catch (e: Exception) {
            System.currentTimeMillis()
        }

        val sizeMatch = Regex("""[\d.]+\s*[KMG]B""").find(html.substringAfter(filename).substringBefore("<"))
        val size = sizeMatch?.value ?: "Unknown"

        backups.add(LuteBackup(filename, lastModified, size, isManual))
    }

    return backups.sortedByDescending { it.lastModified }
}

suspend fun downloadBackup(
    context: Context,
    filename: String,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT
): DownloadResult = withContext(Dispatchers.IO) {
    return@withContext try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port/backup/download/$filename")
            .build()

        val response = client.newCall(request).execute()

        if (response.isSuccessful) {
            val inputStream = response.body?.byteStream()

            val result = StorageHelper.saveDownloadedFile(
                context,
                filename,
                inputStream ?: return@withContext DownloadResult.Error("No response body")
            )

            result.fold(
                onSuccess = { file -> DownloadResult.Success(file.absolutePath) },
                onFailure = { e -> DownloadResult.Error("Failed to save file: ${e.message}") }
            )
        } else {
            DownloadResult.Error("Download failed: ${response.code}")
        }
    } catch (e: Exception) {
        DownloadResult.Error(e.message ?: "Unknown download error")
    }
}

suspend fun selectBackupFile(context: Context): File? = withContext(Dispatchers.IO) {
    return@withContext try {
        val backups = StorageHelper.findBackupFiles(context)
        if (backups.isNullOrEmpty()) null else backups.first()
    } catch (e: Exception) {
        null
    }
}

suspend fun restoreDatabaseFromDownloads(
    context: Context,
    backupFile: File
): RestoreResult = withContext(Dispatchers.IO) {
    val dataPath = "/data/data/com.termux/files/home/.local/share/lute3"
    val dbPath = "$dataPath/lute.db"
    val backupPath = "$dataPath/${backupFile.name}"

    return@withContext try {
        stopLute3Server(context)
        delay(2000)

        val copyScript = """
            cp '${backupFile.absolutePath}' '$backupPath'
        """.trimIndent()

        val copyIntent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", copyScript))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(copyIntent)
        delay(3000)

        if (backupFile.name.endsWith(".gz")) {
            val decompressScript = """
                cd '$dataPath'
                gunzip -f '${backupFile.name}'
                mv '${backupFile.name.removeSuffix(".gz")}' lute.db
            """.trimIndent()

            val decompressIntent = Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", decompressScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }
            context.startService(decompressIntent)
            delay(5000)
        } else {
            val renameScript = """
                cd '$dataPath'
                mv '${backupFile.name}' lute.db
            """.trimIndent()

            val renameIntent = Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", renameScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }
            context.startService(renameIntent)
            delay(3000)
        }

        launchLute3ServerWithAutoShutdown(context, TermuxConstants.LUTE3_DEFAULT_PORT)
        delay(5000)

        if (isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)) {
            RestoreResult.Success("Database restored successfully")
        } else {
            RestoreResult.Error("Server failed to start after restore")
        }
    } catch (e: Exception) {
        RestoreResult.Error(e.message ?: "Unknown restore error")
    }
}

suspend fun syncWithRemoteServer(
    context: Context,
    remoteUrl: String,
    apiKey: String? = null,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT
): SyncResult = withContext(Dispatchers.IO) {
    val backupResult = triggerLute3Backup(context, port, BackupType.MANUAL)
    if (backupResult !is BackupResult.Success) {
        return@withContext SyncResult.Error("Failed to create backup: ${(backupResult as BackupResult.Error).message}")
    }

    val backups = listBackups(context, port)
    if (backups.isNullOrEmpty()) {
        return@withContext SyncResult.Error("No backups found")
    }

    val latestBackup = backups.maxByOrNull { it.lastModified }
        ?: return@withContext SyncResult.Error("No valid backup found")

    val downloadResult = downloadBackup(context, latestBackup.filename, port)
    if (downloadResult !is DownloadResult.Success) {
        return@withContext SyncResult.Error("Failed to download backup: ${(downloadResult as DownloadResult.Error).message}")
    }

    return@withContext try {
        val client = OkHttpClient()
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart(
                "backup", latestBackup.filename,
                File(downloadResult.filePath).asRequestBody("application/gzip".toMediaType())
            )
            .build()

        val requestBuilder = Request.Builder()
            .url("$remoteUrl/backup/upload")
            .post(requestBody)

        if (apiKey != null) {
            requestBuilder.addHeader("Authorization", "Bearer $apiKey")
        }

        val response = client.newCall(requestBuilder.build()).execute()

        if (response.isSuccessful) {
            SyncResult.Success("Backup synced to remote server")
        } else {
            SyncResult.Error("Upload failed: ${response.code}")
        }
    } catch (e: Exception) {
        SyncResult.Error(e.message ?: "Sync failed")
    }
}
