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
    SETUP_STORAGE("Setting up storage permissions...", 10),
    CONFIGURING_MIRRORS("Configuring mirrors...", 120),
    UPDATING_PACKAGES("Updating package lists...", 120),
    UPGRADING_PACKAGES("Upgrading packages...", 300),
    INSTALLING_PYTHON("Installing Python3...", 300),
    INSTALLING_LUTE3("Installing Lute3...", 300),
    VERIFYING("Verifying installation...", 30),
    COMPLETE("Installation complete!", 0),
    FAILED("Installation failed", 0)
}

fun termuxUpdatePackages(context: Context): Boolean {
    return try {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg update -y"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(intent)
        true
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to start package update: ${e.message}")
        false
    }
}

fun termuxUpgradePackages(context: Context): Boolean {
    return try {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg upgrade -y"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(intent)
        true
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to start package upgrade: ${e.message}")
        false
    }
}

fun termuxInstallPython3(context: Context): Boolean {
    return try {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg install python3 -y"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(intent)
        true
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to start python install: ${e.message}")
        false
    }
}

fun termuxInstallLute3(context: Context): Boolean {
    return try {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pip install --upgrade lute3"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(intent)
        true
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to start lute3 install: ${e.message}")
        false
    }
}

suspend fun executeCommandWithStatusFile(
    context: Context,
    command: String,
    stepName: String,
    onProgress: (String) -> Unit,
    timeoutSeconds: Int = 60
): CommandResult {
    val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
    val statusFile = "$downloadsDir/cmd_status_${System.currentTimeMillis()}.txt"
    val outputFile = "$downloadsDir/cmd_output_${System.currentTimeMillis()}.txt"

    val script = """
        $command > "$outputFile" 2>&1
        exitCode=${'$'}?
        if [ ${'$'}exitCode -eq 0 ]; then
            echo "SUCCESS" > "$statusFile"
        else
            echo "FAILED" > "$statusFile"
        fi
    """.trimIndent()

    android.util.Log.d("TermuxServer", "Starting: $stepName")
    onProgress("$stepName: Starting...")

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    val sendResult = try {
        context.startService(intent)
        android.util.Log.d("TermuxServer", "Command sent: $command")
        true
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Failed to send command: ${e.message}")
        return CommandResult.Failed("Could not send command to Termux: ${e.message}")
    }

    val startTime = System.currentTimeMillis()
    val timeoutMs = timeoutSeconds * 1000L

    while (System.currentTimeMillis() - startTime < timeoutMs) {
        delay(2000)

        val elapsedSeconds = ((System.currentTimeMillis() - startTime) / 1000).toInt()

        val statusFileObj = File(statusFile)
        if (statusFileObj.exists()) {
            val content = statusFileObj.readText().trim()
            android.util.Log.d("TermuxServer", "$stepName completed: $content")
            statusFileObj.delete()

            return when (content) {
                "SUCCESS" -> {
                    val cmdOutput = try {
                        File(outputFile).readText().trim()
                    } catch (e: Exception) {
                        ""
                    }
                    File(outputFile).delete()
                    onProgress("$stepName: Complete")
                    CommandResult.Success(cmdOutput.ifEmpty { "$stepName completed successfully" })
                }
                "FAILED" -> {
                    val errorOutput = try {
                        File(outputFile).readText().trim().take(500)
                    } catch (e: Exception) {
                        "Unable to read error output"
                    }
                    File(outputFile).delete()
                    onProgress("$stepName: Failed")
                    CommandResult.Failed("$stepName failed: $errorOutput")
                }
                else -> {
                    val errorOutput = try {
                        File(outputFile).readText().trim().take(500)
                    } catch (e: Exception) {
                        "Unable to read error output"
                    }
                    File(outputFile).delete()
                    onProgress("$stepName: Unknown status")
                    CommandResult.Failed("Unknown status: $content - $errorOutput")
                }
            }
        }

        val elapsedMinutes = elapsedSeconds / 60
        val elapsedRemSecs = elapsedSeconds % 60
        val timeStr = if (elapsedMinutes > 0) "${elapsedMinutes}m ${elapsedRemSecs}s" else "${elapsedRemSecs}s"

        onProgress("$stepName: Running... ($timeStr elapsed)")
    }

    android.util.Log.w("TermuxServer", "$stepName timed out after $timeoutSeconds seconds")
    File(statusFile).delete()
    File(outputFile).delete()
    onProgress("$stepName: Timed out")
    return CommandResult.Timeout("$stepName timed out after $timeoutSeconds seconds")
}

suspend fun installLute3ServerWithProgress(
    context: Context,
    onStepChange: (stepName: String, stepStatus: String, maxWaitSeconds: Int) -> Unit
): InstallationStep {
    return try {
        onStepChange(InstallationStep.SETUP_STORAGE.name, "Storage access configured", InstallationStep.SETUP_STORAGE.maxWaitSeconds)

        onStepChange(InstallationStep.CONFIGURING_MIRRORS.name, "Configuring mirrors...", InstallationStep.CONFIGURING_MIRRORS.maxWaitSeconds)
        when (val result = executeCommandWithStatusFile(
            context,
            "sed -i 's|^# deb |deb |g' \$PREFIX/etc/apt/sources.list \$PREFIX/etc/apt/sources.list.d/*.list 2>/dev/null; sed -i 's|^# deb-src |deb-src |g' \$PREFIX/etc/apt/sources.list \$PREFIX/etc/apt/sources.list.d/*.list 2>/dev/null; echo 'SUCCESS'",
            "Mirror configuration",
            { msg -> onStepChange(InstallationStep.CONFIGURING_MIRRORS.name, msg, InstallationStep.CONFIGURING_MIRRORS.maxWaitSeconds) },
            InstallationStep.CONFIGURING_MIRRORS.maxWaitSeconds
        )) {
            is CommandResult.Success -> android.util.Log.d("TermuxServer", "Mirror configuration complete")
            is CommandResult.Failed -> {
                android.util.Log.e("TermuxServer", "Mirror configuration failed: ${result.error}")
            }
            is CommandResult.Timeout -> {
                android.util.Log.e("TermuxServer", "Mirror configuration timed out, continuing anyway")
            }
        }

        onStepChange(InstallationStep.UPDATING_PACKAGES.name, "Updating package lists...", InstallationStep.UPDATING_PACKAGES.maxWaitSeconds)
        when (val result = executeCommandWithStatusFile(
            context,
            "pkg update -y",
            "Package update",
            { msg -> onStepChange(InstallationStep.UPDATING_PACKAGES.name, msg, InstallationStep.UPDATING_PACKAGES.maxWaitSeconds) },
            InstallationStep.UPDATING_PACKAGES.maxWaitSeconds
        )) {
            is CommandResult.Success -> {
                android.util.Log.d("TermuxServer", "Package update complete")
            }
            is CommandResult.Failed -> {
                android.util.Log.e("TermuxServer", "Package update failed: ${result.error}")
                onStepChange(InstallationStep.FAILED.name, "Failed to update packages", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
            is CommandResult.Timeout -> {
                android.util.Log.e("TermuxServer", "Package update timed out: ${result.message}")
                onStepChange(InstallationStep.FAILED.name, "Package update timed out", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
        }

        val packagesToUpgrade = try {
            val countResult = executeCommandWithStatusFile(
                context,
                "apt list --upgradable 2>/dev/null | wc -l",
                "Count packages",
                { },
                30
            )
            when (countResult) {
                is CommandResult.Success -> {
                    val countOutput = countResult.output.filter { it.isDigit() }.take(5).toList().joinToString("")
                    val parsedCount = countOutput.toIntOrNull() ?: 0
                    android.util.Log.d("TermuxServer", "Packages to upgrade: $parsedCount")
                    parsedCount
                }
                else -> 0
            }
        } catch (e: Exception) {
            android.util.Log.e("TermuxServer", "Failed to count packages: ${e.message}")
            0
        }

        val upgradeStepName = if (packagesToUpgrade > 0) "Upgrading $packagesToUpgrade packages" else "Upgrading packages"

        onStepChange(upgradeStepName, "Starting...", InstallationStep.UPGRADING_PACKAGES.maxWaitSeconds)

        when (val result = executeCommandWithStatusFile(
            context,
            "pkg upgrade -y",
            "Package upgrade",
            { msg -> onStepChange(upgradeStepName, msg, InstallationStep.UPGRADING_PACKAGES.maxWaitSeconds) },
            InstallationStep.UPGRADING_PACKAGES.maxWaitSeconds
        )) {
            is CommandResult.Success -> android.util.Log.d("TermuxServer", "Package upgrade complete")
            is CommandResult.Failed -> {
                android.util.Log.e("TermuxServer", "Package upgrade failed: ${result.error}")
                onStepChange(InstallationStep.FAILED.name, "Failed to upgrade packages", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
            is CommandResult.Timeout -> {
                android.util.Log.e("TermuxServer", "Package upgrade timed out: ${result.message}")
                onStepChange(InstallationStep.FAILED.name, "Package upgrade timed out", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
        }

        onStepChange(InstallationStep.INSTALLING_PYTHON.name, "Installing Python3...", InstallationStep.INSTALLING_PYTHON.maxWaitSeconds)
        when (val result = executeCommandWithStatusFile(
            context,
            "pkg install python3 -y",
            "Python installation",
            { msg -> onStepChange(InstallationStep.INSTALLING_PYTHON.name, msg, InstallationStep.INSTALLING_PYTHON.maxWaitSeconds) },
            InstallationStep.INSTALLING_PYTHON.maxWaitSeconds
        )) {
            is CommandResult.Success -> android.util.Log.d("TermuxServer", "Python installation complete")
            is CommandResult.Failed -> {
                android.util.Log.e("TermuxServer", "Python install failed: ${result.error}")
                onStepChange(InstallationStep.FAILED.name, "Failed to install Python", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
            is CommandResult.Timeout -> {
                android.util.Log.e("TermuxServer", "Python installation timed out: ${result.message}")
                onStepChange(InstallationStep.FAILED.name, "Python installation timed out", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
        }

        onStepChange(InstallationStep.INSTALLING_LUTE3.name, "Installing Lute3...", InstallationStep.INSTALLING_LUTE3.maxWaitSeconds)
        when (val result = executeCommandWithStatusFile(
            context,
            "pip install --upgrade lute3",
            "Lute3 installation",
            { msg -> onStepChange(InstallationStep.INSTALLING_LUTE3.name, msg, InstallationStep.INSTALLING_LUTE3.maxWaitSeconds) },
            InstallationStep.INSTALLING_LUTE3.maxWaitSeconds
        )) {
            is CommandResult.Success -> android.util.Log.d("TermuxServer", "Lute3 installation complete")
            is CommandResult.Failed -> {
                android.util.Log.e("TermuxServer", "Lute3 install failed: ${result.error}")
                onStepChange(InstallationStep.FAILED.name, "Failed to install Lute3", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
            is CommandResult.Timeout -> {
                android.util.Log.e("TermuxServer", "Lute3 installation timed out: ${result.message}")
                onStepChange(InstallationStep.FAILED.name, "Lute3 installation timed out", InstallationStep.FAILED.maxWaitSeconds)
                return InstallationStep.FAILED
            }
        }

        onStepChange(InstallationStep.VERIFYING.name, "Verifying installation...", InstallationStep.VERIFYING.maxWaitSeconds)
        delay(5000)

        if (isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)) {
            onStepChange(InstallationStep.COMPLETE.name, "Installation complete!", InstallationStep.COMPLETE.maxWaitSeconds)
            InstallationStep.COMPLETE
        } else {
            onStepChange(InstallationStep.FAILED.name, "Server failed to start", InstallationStep.FAILED.maxWaitSeconds)
            InstallationStep.FAILED
        }
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Installation failed with exception: ${e.message}")
        onStepChange(InstallationStep.FAILED.name, "Installation failed: ${e.message}", InstallationStep.FAILED.maxWaitSeconds)
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
        mkdir -p "\$(dirname "${'$'}HEARTBEAT_FILE")"
        touch "${'$'}HEARTBEAT_FILE"

        python -m lute.main --port $port &
        SERVER_PID=${'$'}!

        echo "Lute3 server started with PID ${'$'}SERVER_PID on port $port"

        MAX_IDLE_MINUTES=$idleTimeoutMinutes
        CHECK_INTERVAL_SECONDS=${TermuxConstants.HEARTBEAT_CHECK_INTERVAL}
        MAX_CHECKS=${'$'}((MAX_IDLE_MINUTES * 60 / CHECK_INTERVAL_SECONDS))
        IDLE_CHECKS=0

        while true; do
            sleep ${'$'}CHECK_INTERVAL_SECONDS

            if ! ps -p ${'$'}SERVER_PID > /dev/null 2>&1; then
                echo "Server stopped, exiting monitor"
                exit 0
            fi

            CURRENT_TIME=${'$'}$(date +%s)
            HEARTBEAT_TIME=${'$'}$(stat -c %Y "${'$'}HEARTBEAT_FILE" 2>/dev/null || echo "0")
            TIME_DIFF=${'$'}(( (CURRENT_TIME - HEARTBEAT_TIME) / 60 ))

            if [ ${'$'}TIME_DIFF -lt 2 ]; then
                IDLE_CHECKS=0
                echo "Heartbeat detected (${'$'}TIME_DIFF min ago), idle counter reset"
            else
                IDLE_CHECKS=${'$'}((IDLE_CHECKS + 1))
                IDLE_MINUTES=${'$'}((IDLE_CHECKS * 2))
                echo "No heartbeat for ${'$'}IDLE_MINUTES minutes (check ${'$'}IDLE_CHECKS/${'$'}MAX_CHECKS)"

                if [ ${'$'}IDLE_CHECKS -ge ${'$'}MAX_CHECKS ]; then
                    echo "Idle timeout reached (${'$'}MAX_IDLE_MINUTES min), stopping server..."
                    kill ${'$'}SERVER_PID 2>/dev/null
                    rm -f "${'$'}HEARTBEAT_FILE"
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

suspend fun touchHeartbeat(context: Context): Boolean {
    val heartbeatFile = File(TermuxConstants.HEARTBEAT_FILE)
    val lastModifiedBefore = if (heartbeatFile.exists()) heartbeatFile.lastModified() else 0L

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "touch ${TermuxConstants.HEARTBEAT_FILE}"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    return try {
        context.startService(intent)
        delay(500)

        val lastModifiedAfter = if (heartbeatFile.exists()) heartbeatFile.lastModified() else 0L
        val success = lastModifiedAfter > lastModifiedBefore
        android.util.Log.d("TermuxServer", "Heartbeat test: ${if (success) "SUCCESS" else "FAILED"}")
        success
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Heartbeat test failed: ${e.message}")
        false
    }
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
