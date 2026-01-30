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

enum class InstallationStep(val status: String, val estimatedTimeSeconds: Int) {
    SETUP_STORAGE("Setting up storage permissions...", 3),
    UPDATING_PACKAGES("Updating package lists...", 15),
    UPGRADING_PACKAGES("Upgrading packages...", 30),
    INSTALLING_PYTHON("Installing Python3...", 45),
    INSTALLING_LUTE3("Installing Lute3...", 60),
    VERIFYING("Verifying installation...", 5),
    COMPLETE("Installation complete!", 0),
    FAILED("Installation failed", 0)
}

fun termuxSetupStorage(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "termux-setup-storage"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun termuxUpdatePackages(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg update -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun termuxUpgradePackages(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg upgrade -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun termuxInstallPython3(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg install python3 -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun termuxInstallLute3(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pip install --upgrade lute3"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

suspend fun installLute3ServerWithProgress(
    context: Context,
    onStepChange: (InstallationStep) -> Unit
): InstallationStep {
    return try {
        onStepChange(InstallationStep.SETUP_STORAGE)
        termuxSetupStorage(context)
        delay(TermuxConstants.SETUP_STORAGE_TIMEOUT * 1000L)

        onStepChange(InstallationStep.UPDATING_PACKAGES)
        termuxUpdatePackages(context)
        delay(TermuxConstants.UPDATE_PACKAGES_TIMEOUT * 1000L)

        onStepChange(InstallationStep.UPGRADING_PACKAGES)
        termuxUpgradePackages(context)
        delay(TermuxConstants.UPGRADE_PACKAGES_TIMEOUT * 1000L)

        onStepChange(InstallationStep.INSTALLING_PYTHON)
        termuxInstallPython3(context)
        delay(TermuxConstants.INSTALL_PYTHON_TIMEOUT * 1000L)

        onStepChange(InstallationStep.INSTALLING_LUTE3)
        termuxInstallLute3(context)
        delay(TermuxConstants.INSTALL_LUTE3_TIMEOUT * 1000L)

        onStepChange(InstallationStep.VERIFYING)
        delay(5000)

        if (isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)) {
            InstallationStep.COMPLETE
        } else {
            InstallationStep.FAILED
        }
    } catch (e: Exception) {
        InstallationStep.FAILED
    }
}

fun launchLute3ServerWithAutoShutdown(
    context: Context,
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
    idleTimeoutMinutes: Int = TermuxConstants.IDLE_TIMEOUT_MINUTES
) {
    val script = """
        #!/data/data/com.termux/files/usr/bin/bash

        HEARTBEAT_FILE="${TermuxConstants.HEARTBEAT_FILE}"
        mkdir -p "$(dirname "$HEARTBEAT_FILE")"
        touch "$HEARTBEAT_FILE"

        python -m lute.main --port $port &
        SERVER_PID=$!

        echo "Lute3 server started with PID $SERVER_PID on port $port"

        MAX_IDLE_MINUTES=$idleTimeoutMinutes
        CHECK_INTERVAL_SECONDS=${TermuxConstants.HEARTBEAT_CHECK_INTERVAL}
        MAX_CHECKS=$((MAX_IDLE_MINUTES * 60 / CHECK_INTERVAL_SECONDS))
        IDLE_CHECKS=0

        while true; do
            sleep $CHECK_INTERVAL_SECONDS

            if ! ps -p $SERVER_PID > /dev/null 2>&1; then
                echo "Server stopped, exiting monitor"
                exit 0
            fi

            CURRENT_TIME=$(date +%s)
            HEARTBEAT_TIME=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo "0")
            TIME_DIFF=$(( (CURRENT_TIME - HEARTBEAT_TIME) / 60 ))

            if [ $TIME_DIFF -lt 2 ]; then
                IDLE_CHECKS=0
                echo "Heartbeat detected (${'$'}TIME_DIFF min ago), idle counter reset"
            else
                IDLE_CHECKS=$((IDLE_CHECKS + 1))
                IDLE_MINUTES=$((IDLE_CHECKS * 2))
                echo "No heartbeat for ${'$'}IDLE_MINUTES minutes (check ${'$'}IDLE_CHECKS/${'$'}MAX_CHECKS)"

                if [ $IDLE_CHECKS -ge $MAX_CHECKS ]; then
                    echo "Idle timeout reached (${'$'}MAX_IDLE_MINUTES min), stopping server..."
                    kill $SERVER_PID 2>/dev/null
                    rm -f "$HEARTBEAT_FILE"
                    exit 0
                fi
            fi
        done
    """.trimIndent()

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        putExtra("com.termux.RUN_COMMAND_WORKDIR", TermuxConstants.TERMUX_HOME)
    }
    context.startService(intent)
}

fun touchHeartbeat(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "touch ${TermuxConstants.HEARTBEAT_FILE}"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun stopLute3Server(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkill -f \"python -m lute.main\" || true"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)

    val cleanupIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "rm -f ${TermuxConstants.HEARTBEAT_FILE}"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(cleanupIntent)
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
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val outputFile = File(downloadsDir, filename)

            inputStream?.use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }

            DownloadResult.Success(outputFile.absolutePath)
        } else {
            DownloadResult.Error("Download failed: ${response.code}")
        }
    } catch (e: Exception) {
        DownloadResult.Error(e.message ?: "Unknown download error")
    }
}

suspend fun selectBackupFile(context: Context): File? = withContext(Dispatchers.IO) {
    return@withContext try {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val backups = downloadsDir.listFiles { file ->
            file.name.matches(Regex("(manual_)?lute_backup_.*\\.db(\\.gz)?"))
        }?.sortedByDescending { it.lastModified() }

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
        return@withContext SyncResult.Error("Failed to create backup: ${backupResult.message}")
    }

    val backups = listBackups(context, port)
    if (backups.isNullOrEmpty()) {
        return@withContext SyncResult.Error("No backups found")
    }

    val latestBackup = backups.maxByOrNull { it.lastModified }
        ?: return@withContext SyncResult.Error("No valid backup found")

    val downloadResult = downloadBackup(context, latestBackup.filename, port)
    if (downloadResult !is DownloadResult.Success) {
        return@withContext SyncResult.Error("Failed to download backup: ${downloadResult.message}")
    }

    return@withContext try {
        val client = OkHttpClient()
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("backup", latestBackup.filename,
                File(downloadResult.filePath).asRequestBody("application/gzip".toMediaType()))
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
