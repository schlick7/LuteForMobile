package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.app.ActivityManager
import androidx.core.content.ContextCompat
import kotlinx.coroutines.delay
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.IOException

sealed class CommandResult {
    data class Success(val output: String) : CommandResult()
    data class Failed(val error: String) : CommandResult()
    data class Timeout(val message: String) : CommandResult()
}

enum class InstallationStatus {
    INSTALLED,
    NOT_INSTALLED,
    UNKNOWN,
    ERROR
}

suspend fun executeCommandWithCompletion(
    context: Context,
    command: String,
    commandId: String,
    timeoutSeconds: Int
): CommandResult {
    val statusFile = "${TermuxConstants.COMMAND_STATUS_DIR}/${commandId}_status.txt"
    val outputFile = "${TermuxConstants.COMMAND_STATUS_DIR}/${commandId}_output.txt"

    val mkdirIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "-c", "mkdir -p ${TermuxConstants.COMMAND_STATUS_DIR}"
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(mkdirIntent)

    val clearIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "-c", "rm -f $statusFile $outputFile"
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(clearIntent)
    delay(500)

    val script = """
        #!/data/data/com.termux/files/usr/bin/bash

        $command 2>&1 | tee $outputFile
        EXIT_CODE=${'$'}PIPESTATUS[0]

        if [ ${'$'}EXIT_CODE -eq 0 ]; then
            echo "${TermuxConstants.COMMAND_SUCCESS}" > $statusFile
        else
            echo "${TermuxConstants.COMMAND_FAILED}" > $statusFile
            echo "Exit code: ${'$'}EXIT_CODE" >> $statusFile
        fi

        exit ${'$'}EXIT_CODE
    """.trimIndent()

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)

    val startTime = System.currentTimeMillis()
    val maxWaitTime = timeoutSeconds * 1000L

    while (System.currentTimeMillis() - startTime < maxWaitTime) {
        delay(TermuxConstants.COMMAND_POLL_INTERVAL * 1000L)

        val statusFileObj = File(statusFile)
        if (statusFileObj.exists()) {
            val status = statusFileObj.readText().trim()

            val output = try {
                File(outputFile).readText().takeLast(500)
            } catch (e: Exception) {
                ""
            }

            return when {
                status.contains(TermuxConstants.COMMAND_SUCCESS) -> {
                    CommandResult.Success(output)
                }
                status.contains(TermuxConstants.COMMAND_FAILED) -> {
                    CommandResult.Failed(status + "\n" + output)
                }
                else -> {
                    CommandResult.Failed("Unknown status: $status")
                }
            }
        }
    }

    val output = try {
        File(outputFile).readText()
    } catch (e: Exception) {
        ""
    }

    return if (output.isNotEmpty()) {
        CommandResult.Timeout("Command still running, output: ${output.takeLast(300)}")
    } else {
        CommandResult.Timeout("Command timed out after ${timeoutSeconds}s, no output received")
    }
}

fun isTermuxInstalled(context: Context): Boolean {
    return try {
        context.packageManager.getApplicationInfo(TermuxConstants.TERMUX_PACKAGE, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}

fun isTermuxPermissionGranted(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(
        context,
        "com.termux.permission.RUN_COMMAND"
    ) == PackageManager.PERMISSION_GRANTED
}

fun isLute3ServerRunning(context: Context): Boolean {
    return try {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningProcesses = activityManager.runningAppProcesses
        
        runningProcesses?.any { process ->
            process.processName.contains("com.termux") && 
            process.processName.contains("python")
        } ?: false
    } catch (e: Exception) {
        false
    }
}

suspend fun isLute3ServerRunningHttp(port: Int = TermuxConstants.LUTE3_DEFAULT_PORT): Boolean {
    return try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port")
            .head()
            .build()
        val response = client.newCall(request).execute()
        response.isSuccessful
    } catch (e: Exception) {
        false
    }
}

suspend fun isLute3Installed(context: Context): InstallationStatus {
    val checkFile = TermuxConstants.INSTALLATION_STATUS_FILE

    return try {
        val script = """
            if pip show lute3 > /dev/null 2>&1; then
                echo "INSTALLED" > $checkFile
                pip show lute3 >> $checkFile
            else
                echo "NOT_INSTALLED" > $checkFile
            fi
        """.trimIndent()

        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }

        try {
            context.startService(intent)
        } catch (e: Exception) {
            return InstallationStatus.UNKNOWN
        }

        delay(TermuxConstants.INSTALLATION_CHECK_DELAY * 1000L)

        val file = File(checkFile)
        if (!file.exists()) {
            return InstallationStatus.UNKNOWN
        }

        val content = file.readText()
        when {
            content.contains("INSTALLED") -> InstallationStatus.INSTALLED
            content.contains("NOT_INSTALLED") -> InstallationStatus.NOT_INSTALLED
            else -> InstallationStatus.UNKNOWN
        }
    } catch (e: Exception) {
        InstallationStatus.UNKNOWN
    }
}
