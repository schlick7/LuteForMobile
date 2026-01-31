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
    // tmux-based installation steps
    INSTALLING_TMUX("Installing tmux...", 180),
    CONFIGURING_TMUX("Configuring tmux...", 30),
    SETUP_STORAGE("Setting up storage permissions...", 10),
    CONFIGURING_MIRRORS("Configuring mirrors...", 10),
    UPDATING_PACKAGES("Updating package lists...", 120),
    UPGRADING_PACKAGES("Upgrading packages...", 300),
    INSTALLING_PYTHON3("Installing Python3...", 300),
    VERIFYING_PYTHON("Verifying Python installation...", 15),
    UPGRADING_PIP("Upgrading pip...", 60),
    INSTALLING_LUTE3("Installing Lute3...", 300),
    VERIFYING_LUTE3("Verifying Lute3 installation...", 30),
    STARTING_SERVER("Starting Lute3 server...", 30),
    VERIFYING_SERVER("Verifying server is responding...", 20),
    FINAL_CHECK("Performing final verification...", 10),
    COMPLETE("Installation complete!", 0),
    FAILED("Installation failed", 0)
}

suspend fun termuxUpdatePackages(context: Context): CommandResult {
    return executeCommandWithStatusFile(
        context,
        "pkg update -y",
        "Updating packages",
        { progress -> android.util.Log.d("TermuxServer", progress) },
        TermuxConstants.UPDATE_PACKAGES_TIMEOUT
    )
}

suspend fun termuxUpgradePackages(context: Context): CommandResult {
    return executeCommandWithStatusFile(
        context,
        "pkg upgrade -y",
        "Upgrading packages",
        { progress -> android.util.Log.d("TermuxServer", progress) },
        TermuxConstants.UPGRADE_PACKAGES_TIMEOUT
    )
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
    android.util.Log.d("TermuxServer", "=== executeCommandWithStatusFile: $stepName ===")
    android.util.Log.d("TermuxServer", "Command: $command")
    val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
    val statusFile = "$downloadsDir/${stepName.replace(" ", "_")}_status.txt"
    val outputFile = "$downloadsDir/${stepName.replace(" ", "_")}_output.txt"

    val clearIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "rm -f $statusFile $outputFile"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(clearIntent)
    delay(500)

    val script = """
        $command > "$outputFile" 2>&1
        EXIT_CODE=${'$'}?
        if [ ${'$'}EXIT_CODE -eq 0 ]; then
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
    val pollIntervalMs = TermuxConstants.COMMAND_POLL_INTERVAL * 1000L

    android.util.Log.d("TermuxServer", "Polling for status file: $statusFile")

    while (System.currentTimeMillis() - startTime < timeoutMs) {
        delay(pollIntervalMs)

        val statusFileObj = File(statusFile)
        android.util.Log.d("TermuxServer", "Checking status file exists: ${statusFileObj.exists()}")
        
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
    }

    android.util.Log.w("TermuxServer", "$stepName timed out after ${timeoutSeconds}s")

    val timedOutOutput = try {
        File(outputFile).readText()
    } catch (e: Exception) {
        ""
    }

    if (timedOutOutput.isNotEmpty()) {
        File(outputFile).delete()
        File(statusFile).delete()
        return CommandResult.Timeout("$stepName timed out after ${timeoutSeconds}s, output: ${timedOutOutput.takeLast(300)}")
    }

    File(outputFile).delete()
    File(statusFile).delete()
    return CommandResult.Timeout("$stepName timed out after ${timeoutSeconds}s, no output received")
}

suspend fun installLute3ServerWithProgress(
    context: Context,
    onStepChange: (stepName: String, stepStatus: String, maxWaitSeconds: Int) -> Unit
): InstallationStep {
    return try {
        val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
        val statusFile = "$downloadsDir/lute3_install_status.txt"
        val lutePort = TermuxConstants.LUTE3_DEFAULT_PORT

        val installScript = """
            #!/data/data/com.termux/files/usr/bin/bash

            # Kill any existing installation processes to avoid conflicts
            pkill -9 -f 'pkg.*update|pkg.*upgrade|apt|dpkg' 2>/dev/null || true

            # Function to log detailed status
            log_status() {
                local step_name="${'$'}1"
                local message="${'$'}2"
                local max_wait="${'$'}3"
                local detail="${'$'}4"
                echo "STATUS|${'$'}step_name|${'$'}message|${'$'}max_wait|${'$'}detail" > "${'$'}statusFile"
            }

            # Clear any stale locks first
            log_status "SETUP_STORAGE" "Cleaning up stale locks..." "10" "Clearing locks"
            pkill -9 -f 'apt|dpkg|pkg' 2>/dev/null || true
            rm -f ${'$'}PREFIX/var/lib/dpkg/lock-frontend ${'$'}PREFIX/var/lib/dpkg/lock ${'$'}PREFIX/var/cache/apt/archives/lock 2>/dev/null || true
            dpkg --configure -a 2>/dev/null || true
            log_status "SETUP_STORAGE" "Ready" "10" "Locks cleared"

            # Configure Termux mirrors
            log_status "CONFIGURING_MIRRORS" "Configuring mirrors..." "10" "Setting up repo"
            echo 'deb https://packages.termux.dev/apt/termux-main stable main' > ${'$'}PREFIX/etc/apt/sources.list
            log_status "CONFIGURING_MIRRORS" "Done" "10" "Mirrors configured"

            # Update package lists
            log_status "UPDATING_PACKAGES" "Updating package lists..." "60" "Running pkg update"
            pkg update -y || (log_status "FAILED" "pkg update failed" "0" "Command failed" && exit 1)
            log_status "UPDATING_PACKAGES" "Done" "60" "Packages updated"

            # Upgrade packages
            log_status "UPGRADING_PACKAGES" "Upgrading packages..." "300" "Running pkg upgrade"
            pkg upgrade -y || (log_status "FAILED" "pkg upgrade failed" "0" "Command failed" && exit 1)
            log_status "UPGRADING_PACKAGES" "Done" "300" "Packages upgraded"

            # Install Python3
            log_status "INSTALLING_PYTHON3" "Installing Python3..." "300" "Running pkg install python3"
            pkg install python3 -y || (log_status "FAILED" "Python3 install failed" "0" "Command failed" && exit 1)
            log_status "INSTALLING_PYTHON3" "Done" "300" "Python3 installed"

            # Verify Python installation
            log_status "VERIFYING_PYTHON" "Verifying Python..." "15" "Running python --version"
            python --version || (log_status "FAILED" "Python not found" "0" "Verification failed" && exit 1)
            log_status "VERIFYING_PYTHON" "Done" "15" "Python verified"

            # Upgrade pip
            log_status "UPGRADING_PIP" "Upgrading pip..." "60" "Running pip install --upgrade pip"
            pip install --upgrade pip || (log_status "FAILED" "pip upgrade failed" "0" "Command failed" && exit 1)
            log_status "UPGRADING_PIP" "Done" "60" "pip upgraded"

            # Install Lute3
            log_status "INSTALLING_LUTE3" "Installing Lute3..." "300" "Running pip install --upgrade lute3"
            pip install --upgrade lute3 || (log_status "FAILED" "lute3 install failed" "0" "Command failed" && exit 1)
            log_status "INSTALLING_LUTE3" "Done" "300" "Lute3 installed"

            # Verify Lute3 installation
            log_status "VERIFYING_LUTE3" "Verifying Lute3..." "30" "Running lute3 --version"
            lute3 --version || (log_status "FAILED" "lute3 not found" "0" "Verification failed" && exit 1)
            log_status "VERIFYING_LUTE3" "Done" "30" "Lute3 verified"

            # Start Lute3 server for verification
            log_status "STARTING_SERVER" "Starting server..." "30" "Launching on port $lutePort"
            python -m lute.main --port $lutePort &
            LUTE_PID=${'$'}!
            log_status "STARTING_SERVER" "Started (PID: ${'$'}LUTE_PID)" "30" "Server running"

            # Wait for server to be ready
            log_status "VERIFYING_SERVER" "Verifying server..." "20" "Checking HTTP"
            sleep 3
            for i in {1..10}; do
                if curl -s http://localhost:$lutePort > /dev/null 2>&1; then
                    log_status "VERIFYING_SERVER" "Responding" "20" "Server ready"
                    break
                fi
                if [ ${'$'}i -eq 10 ]; then
                    log_status "FAILED" "Server not responding" "0" "Server failed" && kill ${'$'}LUTE_PID 2>/dev/null && exit 1
                fi
                sleep 1
            done

            # Stop verification server
            kill ${'$'}LUTE_PID 2>/dev/null || true
            log_status "VERIFYING_SERVER" "Done" "20" "Verification complete"

            # Final verification
            log_status "FINAL_CHECK" "Final check..." "10" "Checking components"
            command -v python3 > /dev/null && command -v pip > /dev/null && command -v lute3 > /dev/null || (log_status "FAILED" "Missing tools" "0" "Not all tools found" && exit 1)
            log_status "COMPLETE" "Complete!" "0" "All verified"
        """.trimIndent()

        android.util.Log.d("TermuxServer", "Starting combined installation script")

        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", installScript))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_RESULT_DIRECTORY", downloadsDir)
        }

        context.startService(intent)

        val maxWaitMs = 15 * 60 * 1000L
        val startTime = System.currentTimeMillis()
        var lastStep = ""

        while (System.currentTimeMillis() - startTime < maxWaitMs) {
            delay(2000)

            try {
                val file = java.io.File(statusFile)
                if (file.exists()) {
                    val content = file.readText().trim()
                    android.util.Log.d("TermuxServer", "Status file content: $content")
                    
                    if (content.startsWith("STATUS|")) {
                        val parts = content.split("|")
                        if (parts.size >= 4) {
                            val step = parts[1]
                            val status = parts[2]
                            val maxWait = parts[3].toIntOrNull() ?: 60
                            val detail = if (parts.size >= 5) parts[4] else ""

                            android.util.Log.d("TermuxServer", "Step: $step, Status: $status, Detail: $detail")

                            if (step != lastStep) {
                                lastStep = step
                                val combinedStatus = if (detail.isNotEmpty()) {
                                    "$status - $detail"
                                } else {
                                    status
                                }
                                onStepChange(step, combinedStatus, maxWait)
                            }

                            when (step) {
                                "COMPLETE" -> {
                                    file.delete()
                                    return InstallationStep.COMPLETE
                                }
                                "FAILED" -> {
                                    file.delete()
                                    val combinedStatus = if (detail.isNotEmpty()) {
                                        "$status - $detail"
                                    } else {
                                        status
                                    }
                                    onStepChange(InstallationStep.FAILED.name, combinedStatus, 0)
                                    return InstallationStep.FAILED
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("TermuxServer", "Status check error: ${e.message}")
            }
        }

        try { java.io.File(statusFile).delete() } catch (e: Exception) {}
        onStepChange(InstallationStep.FAILED.name, "Installation timed out", 0)
        InstallationStep.FAILED
    } catch (e: Exception) {
        android.util.Log.e("TermuxServer", "Installation failed: ${e.message}")
        onStepChange(InstallationStep.FAILED.name, "Installation failed: ${e.message}", 0)
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
