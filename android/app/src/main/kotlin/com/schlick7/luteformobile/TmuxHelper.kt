package com.schlick7.luteformobile

import android.content.Context
import kotlinx.coroutines.delay
import java.io.File

object TmuxHelper {
    const val SESSION_NAME = "lute_session"
    const val LOCK_FILE = "lute_install.lock"
    
    // Session existence and health checks
    fun sessionExists(): Boolean {
        return try {
            val process = ProcessBuilder("tmux", "has-session", "-t", SESSION_NAME)
                .redirectErrorStream(true)
                .start()
            val result = process.waitFor() == 0
            android.util.Log.d("TmuxHelper", "Session exists check: $result")
            result
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Session exists check failed: ${e.message}")
            false
        }
    }
    
    fun isSessionHealthy(): Boolean {
        return try {
            // Check if session responds to commands
            val process = ProcessBuilder(
                "tmux", "display-message", "-t", SESSION_NAME, "-p", "'#{session_name}'"
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            val output = if (success) {
                process.inputStream.bufferedReader().readText().trim().isNotEmpty()
            } else false
            
            android.util.Log.d("TmuxHelper", "Session health check: $success")
            success && output
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Session health check failed: ${e.message}")
            false
        }
    }
    
    // Ensure tmux is available
    suspend fun ensureTmuxAvailable(context: Context): TmuxResult {
        return try {
            val process = ProcessBuilder("which", "tmux")
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            if (success) {
                android.util.Log.d("TmuxHelper", "tmux is available")
                TmuxResult.Success
            } else {
                android.util.Log.w("TmuxHelper", "tmux not found")
                TmuxResult.NotInstalled
            }
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "tmux availability check failed: ${e.message}")
            TmuxResult.Error(e.message ?: "Unknown error")
        }
    }
    
    // Install tmux
    suspend fun installTmux(context: Context): TmuxResult {
        return try {
            android.util.Log.d("TmuxHelper", "Installing tmux...")
            
            val script = """
                pkg update -y && pkg install -y tmux
            """.trimIndent()
            
            val intent = android.content.Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }
            
            context.startService(intent)
            
            // Wait for installation to complete
            delay(5000)
            
            // Verify installation
            val available = ensureTmuxAvailable(context)
            if (available is TmuxResult.Success) {
                android.util.Log.d("TmuxHelper", "tmux installation successful")
                TmuxResult.Success
            } else {
                TmuxResult.InstallFailed("tmux installation verification failed")
            }
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "tmux installation failed: ${e.message}")
            TmuxResult.InstallFailed("tmux installation failed: ${e.message}")
        }
    }
    
    // Ensure persistent tmux session
    fun ensurePersistentSession(): Boolean {
        return try {
            // Set persistent socket location
            val socketDir = TermuxConstants.TMUX_SOCKET_DIR
            val socketFile = TermuxConstants.TMUX_SOCKET_FILE
            
            // Create socket directory
            ProcessBuilder("mkdir", "-p", socketDir)
                .redirectErrorStream(true)
                .start()
                .waitFor()
            
            // Check if session already exists
            if (sessionExists()) {
                android.util.Log.d("TmuxHelper", "Session already exists")
                return true
            }
            
            // Create new session with persistent socket
            val process = ProcessBuilder(
                "tmux", "-S", socketFile, "new-session", "-d", "-s", SESSION_NAME
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            if (success) {
                android.util.Log.d("TmuxHelper", "Created tmux session: $SESSION_NAME")
            } else {
                val error = process.inputStream.bufferedReader().readText()
                android.util.Log.e("TmuxHelper", "Failed to create tmux session: $error")
            }
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Failed to ensure persistent session: ${e.message}")
            false
        }
    }
    
    // Send command to tmux session
    fun sendCommand(command: String): Boolean {
        return try {
            val socketFile = TermuxConstants.TMUX_SOCKET_FILE
            val process = ProcessBuilder(
                "tmux", "-S", socketFile, "send-keys", "-t", SESSION_NAME, command, "Enter"
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            if (success) {
                android.util.Log.d("TmuxHelper", "Sent command: ${command.take(50)}...")
            } else {
                val error = process.inputStream.bufferedReader().readText()
                android.util.Log.e("TmuxHelper", "Failed to send command: $error")
            }
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Failed to send command: ${e.message}")
            false
        }
    }
    
    // Cleanup orphaned processes
    fun cleanupOrphans(): Boolean {
        return try {
            val process = ProcessBuilder(
                "pkill", "-9", "-f", "apt|dpkg|pkg"
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            android.util.Log.d("TmuxHelper", "Orphan cleanup result: $success")
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Orphan cleanup failed: ${e.message}")
            false
        }
    }
    
    // Kill tmux session
    fun killSession(): Boolean {
        return try {
            val socketFile = TermuxConstants.TMUX_SOCKET_FILE
            val process = ProcessBuilder(
                "tmux", "-S", socketFile, "kill-session", "-t", SESSION_NAME
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            android.util.Log.d("TmuxHelper", "Kill session result: $success")
            
            // Also clean up socket file
            try {
                File(socketFile).delete()
            } catch (e: Exception) {
                android.util.Log.w("TmuxHelper", "Failed to delete socket file: ${e.message}")
            }
            
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Failed to kill session: ${e.message}")
            false
        }
    }
    
    // Get attach instructions for user
    fun getAttachInstructions(): String {
        return """
            To view live installation progress:
            
            1. Open Termux app
            2. Run: tmux -S ${TermuxConstants.TMUX_SOCKET_FILE} attach -t $SESSION_NAME
            
            To detach (return to app):
            Ctrl+b, then press 'd'
        """.trimIndent()
    }
    
    // Install lock management
    fun isInstallInProgress(): Boolean {
        val lockFile = File("${StorageHelper.getDownloadsDirectory()}/$LOCK_FILE")
        return lockFile.exists()
    }
    
    fun createInstallLock(): Boolean {
        return try {
            val lockFile = File("${StorageHelper.getDownloadsDirectory()}/$LOCK_FILE")
            if (lockFile.exists()) {
                false
            } else {
                lockFile.writeText("Installation started at ${System.currentTimeMillis()}")
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Failed to create install lock: ${e.message}")
            false
        }
    }
    
    fun clearInstallLock(): Boolean {
        return try {
            val lockFile = File("${StorageHelper.getDownloadsDirectory()}/$LOCK_FILE")
            val success = lockFile.delete()
            android.util.Log.d("TmuxHelper", "Lock file cleared: $success")
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Failed to clear install lock: ${e.message}")
            false
        }
    }
    
    // Fallback session creation for socket failures
    fun createFallbackSession(): Boolean {
        return try {
            val fallbackSocket = "${StorageHelper.getDownloadsDirectory()}/tmux_socket"
            val process = ProcessBuilder(
                "tmux", "-S", fallbackSocket, "new-session", "-d", "-s", SESSION_NAME
            )
                .redirectErrorStream(true)
                .start()
            
            val success = process.waitFor() == 0
            android.util.Log.d("TmuxHelper", "Fallback session creation: $success")
            success
        } catch (e: Exception) {
            android.util.Log.e("TmuxHelper", "Fallback session failed: ${e.message}")
            false
        }
    }
    
    // Handle session failure with user-friendly error
    fun handleSessionFailure(): String {
        return """
            tmux session failed. Please try these steps:
            
            1. Open Termux app
            2. Run: pkg update && pkg install tmux
            3. Ensure Termux has storage permissions: termux-setup-storage
            4. Retry installation in the app
            
            If problems persist:
            - Clear Termux app data and reinstall
            - Contact support with device details
        """.trimIndent()
    }
}

// Result types for tmux operations
sealed class TmuxResult {
    object Success : TmuxResult()
    object NotInstalled : TmuxResult()
    data class InstallFailed(val message: String) : TmuxResult()
    data class Error(val message: String) : TmuxResult()
}