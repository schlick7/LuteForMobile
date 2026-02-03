package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import kotlinx.coroutines.delay
import java.io.File

/**
 * Utility for stealth launching Termux and checking its running state.
 * Handles the background execution restrictions on Android 10+ by briefly
 * launching Termux to wake up its RunCommandService.
 */
object TermuxLauncher {

    /**
     * Checks if the Termux RunCommandService is responsive by attempting
     * to execute a simple echo command.
     * @return true if Termux responds within the timeout, false otherwise
     */
    suspend fun isTermuxServiceRunning(context: Context): Boolean {
        val downloadsDir = StorageHelper.getDownloadsDirectory().absolutePath
        val testFile = "$downloadsDir/termux_running_check_${System.currentTimeMillis()}.txt"

        // Clean up any old test files
        try {
            File(testFile).delete()
        } catch (e: Exception) {
            // Ignore cleanup errors
        }

        val script = "echo 'RUNNING' > $testFile"

        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }

        return try {
            context.startService(intent)

            // Wait for command to execute (give Termux more time to respond)
            delay(1000)

            // Check if file was created
            val file = File(testFile)
            android.util.Log.d(
                "TermuxLauncher",
                "Checking if test file exists: ${file.absolutePath}, exists: ${file.exists()}"
            )

            val result = if (file.exists()) {
                val content = file.readText().trim()
                android.util.Log.d("TermuxLauncher", "Test file content: '$content'")
                val isRunning = content == "RUNNING"
                android.util.Log.d("TermuxLauncher", "Termux running status: $isRunning")

                // DELETE THE FILE AFTER CONFIRMING IT'S RUNNING - forces fresh check next time
                try {
                    file.delete()
                } catch (e: Exception) {
                    android.util.Log.e("TermuxLauncher", "Failed to delete test file: ${e.message}")
                }

                isRunning
            } else {
                android.util.Log.d("TermuxLauncher", "Test file does not exist, Termux not running")
                false
            }

            result
        } catch (e: Exception) {
            android.util.Log.e("TermuxLauncher", "Failed to check if Termux is running: ${e.message}")
            false
        }
    }

    /**
     * Launches Termux main activity with flags that minimize user visibility:
     * - NO_ANIMATION: No transition animation
     * - EXCLUDE_FROM_RECENTS: Won't appear in recent apps
     * - NO_HISTORY: Won't stay in back stack
     * - NEW_TASK | CLEAR_TOP: Clean start without creating multiple instances
     */
    fun stealthLaunchTermux(context: Context) {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_MAIN_ACTIVITY)
            action = "android.intent.action.MAIN"
            addCategory("android.intent.category.LAUNCHER")
            flags = Intent.FLAG_ACTIVITY_NO_ANIMATION or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                    Intent.FLAG_ACTIVITY_NO_HISTORY or
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION
        }

        try {
            context.startActivity(intent)
            android.util.Log.d("TermuxLauncher", "Stealth launched Termux")
        } catch (e: Exception) {
            android.util.Log.e("TermuxLauncher", "Failed to stealth launch Termux: ${e.message}")
            throw e
        }
    }

    /**
     * Ensures Termux is running by checking its state and stealth launching if needed.
     * Implements retry logic: tries once, waits 500ms, then retries once more if needed.
     *
     * @param context Android context
     * @param maxWaitMs Maximum time to wait for Termux to respond after launch
     * @return true if Termux is confirmed running, false otherwise
     */
    suspend fun ensureTermuxRunning(
        context: Context,
        maxWaitMs: Long = TermuxConstants.TERMUX_STEALTH_LAUNCH_TIMEOUT
    ): Boolean {
        // First check if already running
        if (isTermuxServiceRunning(context)) {
            android.util.Log.d("TermuxLauncher", "Termux is already running")
            return true
        }

        android.util.Log.d("TermuxLauncher", "Termux not running, attempting stealth launch")

        // Try launch with retry logic
        return tryLaunchWithRetry(context, maxWaitMs)
    }

    /**
     * Internal retry logic: attempts launch, waits, checks, and retries once if needed.
     */
    private suspend fun tryLaunchWithRetry(context: Context, maxWaitMs: Long): Boolean {
        // First attempt
        if (attemptLaunchAndWait(context, maxWaitMs)) {
            return true
        }

        android.util.Log.d("TermuxLauncher", "First attempt failed, waiting 500ms before retry")
        delay(500)

        // Second attempt (retry once as specified)
        return attemptLaunchAndWait(context, maxWaitMs)
    }

    /**
     * Attempts to stealth launch Termux and waits for it to become responsive.
     */
    private suspend fun attemptLaunchAndWait(context: Context, maxWaitMs: Long): Boolean {
        return try {
            stealthLaunchTermux(context)

            // Wait for Termux to initialize
            val startTime = System.currentTimeMillis()
            val checkInterval = 200L

            while (System.currentTimeMillis() - startTime < maxWaitMs) {
                delay(checkInterval)

                if (isTermuxServiceRunning(context)) {
                    android.util.Log.d("TermuxLauncher", "Termux is now running after launch")
                    return true
                }
            }

            android.util.Log.w("TermuxLauncher", "Termux did not become responsive within ${maxWaitMs}ms")
            false
        } catch (e: Exception) {
            android.util.Log.e("TermuxLauncher", "Launch attempt failed: ${e.message}")
            false
        }
    }
}
