package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File

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
    val downloadsDir =
        android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
    val statusFile = "$downloadsDir/${commandId}_status.txt"
    val outputFile = "$downloadsDir/${commandId}_output.txt"

    android.util.Log.d("TermuxStatus", "Downloads dir: $downloadsDir")
    android.util.Log.d("TermuxStatus", "Status file: $statusFile")
    android.util.Log.d("TermuxStatus", "Output file: $outputFile")

    val mkdirScript = "mkdir -p '$downloadsDir'"
    val mkdirIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", mkdirScript))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(mkdirIntent)
    delay(500)

    val clearIntent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra(
            "com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
                "-c", "rm -f '$statusFile' '$outputFile'"
            )
        )
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(clearIntent)
    delay(500)

    val script = """
        #!/data/data/com.termux/files/usr/bin/bash

        mkdir -p '$downloadsDir'
        $command 2>&1 | tee '$outputFile'
        EXIT_CODE=${'$'}PIPESTATUS[0]

        if [ ${'$'}EXIT_CODE -eq 0 ]; then
            echo "${TermuxConstants.COMMAND_SUCCESS}" > '$statusFile'
        else
            echo "${TermuxConstants.COMMAND_FAILED}" > '$statusFile'
            echo "Exit code: ${'$'}EXIT_CODE" >> '$statusFile'
        fi

        # Explicitly exit with the exit code
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

fun isFDroidInstalled(context: Context): Boolean {
    return try {
        context.packageManager.getApplicationInfo(TermuxConstants.FDROID_PACKAGE, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}

fun isTermuxPermissionGranted(context: Context): Boolean {
    try {
        // Check if the RUN_COMMAND permission is granted
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            "com.termux.permission.RUN_COMMAND"
        ) == PackageManager.PERMISSION_GRANTED

        if (hasPermission) {
            // Verify that Termux package is actually queryable
            try {
                val packageInfo = context.packageManager.getPackageInfo(
                    TermuxConstants.TERMUX_PACKAGE,
                    PackageManager.GET_ACTIVITIES
                )
                // If we can get package info, the permission is working
                return true
            } catch (e: Exception) {
                // Permission might be granted but package visibility is blocked
                return false
            }
        }

        return false
    } catch (e: Exception) {
        return false
    }
}

suspend fun isLute3ServerRunningHttp(port: Int = TermuxConstants.LUTE3_DEFAULT_PORT): Boolean {
    return isLute3ServerRunningHttpWithRetries(port)
}

/**
 * Quick HTTP check without retries - used during server stop polling
 */
suspend fun isLute3ServerRunningHttpQuick(port: Int = TermuxConstants.LUTE3_DEFAULT_PORT): Boolean {
    val url = "http://127.0.0.1:$port"
    return checkHttpServer(url)
}

private suspend fun checkHttpServer(url: String): Boolean = withContext(Dispatchers.IO) {
    val client = OkHttpClient.Builder()
        .connectTimeout(500, java.util.concurrent.TimeUnit.MILLISECONDS)
        .readTimeout(500, java.util.concurrent.TimeUnit.MILLISECONDS)
        .callTimeout(500, java.util.concurrent.TimeUnit.MILLISECONDS)
        .build()

    val probeUrls = listOf("$url/info", url)
    for (probeUrl in probeUrls) {
        try {
            val request = Request.Builder()
                .url(probeUrl)
                .get()
                .build()

            val startTime = System.currentTimeMillis()
            val response = client.newCall(request).execute()
            val elapsed = System.currentTimeMillis() - startTime
            val responseCode = response.code

            android.util.Log.d("TermuxStatus", "HTTP GET $probeUrl -> $responseCode in ${elapsed}ms")
            response.close()

            // Any non-5xx response indicates an HTTP server is up and responding.
            if (responseCode in 100..499) {
                return@withContext true
            }
        } catch (e: Exception) {
            android.util.Log.d("TermuxStatus", "HTTP GET $probeUrl FAILED: ${e.javaClass.simpleName}: ${e.message}")
        }
    }

    false
}

suspend fun isLute3ServerRunningHttpWithRetries(
    port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
    maxRetries: Int = 3,
    retryDelayMs: Long = 200
): Boolean {
    val url = "http://127.0.0.1:$port"

    for (attempt in 1..maxRetries) {
        android.util.Log.d("TermuxStatus", "HTTP check attempt $attempt/$maxRetries: $url")

        val result = checkHttpServer(url)
        if (result) {
            android.util.Log.d("TermuxStatus", "HTTP check PASSED on attempt $attempt")
            return true
        }

        if (attempt < maxRetries) {
            android.util.Log.d("TermuxStatus", "HTTP check failed, retrying in ${retryDelayMs}ms...")
            delay(retryDelayMs)
        }
    }

    android.util.Log.d("TermuxStatus", "HTTP check FAILED after $maxRetries attempts")
    return false
}

suspend fun isLute3InstalledFastCheck(context: Context): InstallationStatus {
    return try {
        val script = "pip show lute3 > /dev/null 2>&1 && echo 'INSTALLED' || echo 'NOT_INSTALLED'"
        val success = RunCommandHelper.executeWithRetry(context, script, timeoutMs = 500, maxRetries = 2)

        if (success) {
            InstallationStatus.INSTALLED
        } else {
            InstallationStatus.NOT_INSTALLED
        }
    } catch (e: Exception) {
        android.util.Log.e("TermuxStatus", "Fast install check failed: ${e.message}")
        InstallationStatus.UNKNOWN
    }
}
