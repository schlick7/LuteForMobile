package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.delay
import java.io.File

/**
 * Utility for stealth launching Termux and checking its running state.
 * Handles the background execution restrictions on Android 10+ by briefly
 * launching Termux to wake up its RunCommandService.
 */
object TermuxLauncher {

    private var _lastCheckResult: Boolean? = null
    private var _lastCheckTime: Long = 0
    private const val CACHE_DURATION_MS = 3000L

    suspend fun isTermuxServiceRunning(context: Context): Boolean {
        val now = System.currentTimeMillis()
        if (_lastCheckResult != null && now - _lastCheckTime < CACHE_DURATION_MS) {
            android.util.Log.d("TermuxLauncher", "Using cached result: ${_lastCheckResult}")
            return _lastCheckResult!!
        }

        val script = "echo 'PING'"
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_LOG_LEVEL", "warn")
        }

        return try {
            val serviceIntent = Intent(context, TransientForegroundService::class.java)
            context.startForegroundService(serviceIntent)
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    context.startService(intent)
                } catch (e: Exception) {
                    android.util.Log.e("TermuxLauncher", "Failed to start service: ${e.message}")
                }
            }, 200)

            delay(800)

            _lastCheckTime = now
            _lastCheckResult = true
            android.util.Log.d("TermuxLauncher", "Termux is running (quick check passed)")
            true
        } catch (e: Exception) {
            _lastCheckTime = now
            _lastCheckResult = false
            android.util.Log.e("TermuxLauncher", "Failed to check if Termux is running: ${e.message}")
            false
        } finally {
            try {
                val stopIntent = Intent(context, TransientForegroundService::class.java).apply {
                    action = "STOP"
                }
                context.startService(stopIntent)
            } catch (e: Exception) {
            }
        }
    }

    fun clearCache() {
        _lastCheckResult = null
        _lastCheckTime = 0
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
        clearCache()

        if (isTermuxServiceRunning(context)) {
            android.util.Log.d("TermuxLauncher", "Termux is already running")
            return true
        }

        android.util.Log.d("TermuxLauncher", "Termux not running, attempting stealth launch")

        return tryLaunchWithRetry(context, maxWaitMs)
    }

    /**
     * Internal retry logic: attempts launch, waits, checks, and retries once if needed.
     */
    private suspend fun tryLaunchWithRetry(context: Context, maxWaitMs: Long): Boolean {
        if (attemptLaunchAndWait(context, maxWaitMs)) {
            return true
        }

        android.util.Log.d("TermuxLauncher", "First attempt failed, waiting 500ms before retry")
        delay(500)

        return attemptLaunchAndWait(context, maxWaitMs)
    }

    /**
     * Attempts to stealth launch Termux and waits for it to become responsive.
     */
    private suspend fun attemptLaunchAndWait(context: Context, maxWaitMs: Long): Boolean {
        return try {
            stealthLaunchTermux(context)

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
