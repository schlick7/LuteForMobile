package com.schlick7.luteformobile

import android.content.Context
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import java.io.File

// Installation steps for tmux-based installation
enum class TmuxInstallationStep(val status: String, val maxWaitSeconds: Int) {
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

suspend fun installLute3WithTmux(
    context: Context,
    onStepChange: (stepName: String, stepStatus: String, maxWaitSeconds: Int) -> Unit
): TmuxInstallationStep {
    return withContext(Dispatchers.IO) {
        try {
            val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
            val statusFile = "$downloadsDir/lute_install_status.txt"
            val lutePort = TermuxConstants.LUTE3_DEFAULT_PORT

            android.util.Log.d("TmuxInstall", "Starting tmux-based installation")

            // Check if installation is already in progress
            if (TmuxHelper.isInstallInProgress()) {
                onStepChange(TmuxInstallationStep.FAILED.name, "Installation already in progress. Please wait for completion or clear locks.", 0)
                return@withContext TmuxInstallationStep.FAILED
            }

            // Create install lock
            if (!TmuxHelper.createInstallLock()) {
                onStepChange(TmuxInstallationStep.FAILED.name, "Failed to create installation lock", 0)
                return@withContext TmuxInstallationStep.FAILED
            }

            try {
                // Ensure tmux is available
                onStepChange(TmuxInstallationStep.INSTALLING_TMUX.name, "Checking tmux availability...", TmuxInstallationStep.INSTALLING_TMUX.maxWaitSeconds)
                
                when (val tmuxResult = TmuxHelper.ensureTmuxAvailable(context)) {
                    is TmuxResult.Success -> {
                        android.util.Log.d("TmuxInstall", "tmux is available")
                    }
                    is TmuxResult.NotInstalled -> {
                        onStepChange(TmuxInstallationStep.INSTALLING_TMUX.name, "Installing tmux...", TmuxInstallationStep.INSTALLING_TMUX.maxWaitSeconds)
                        when (val installResult = TmuxHelper.installTmux(context)) {
                            is TmuxResult.Success -> {
                                android.util.Log.d("TmuxInstall", "tmux installed successfully")
                            }
                            else -> {
                                val errorMsg = TmuxHelper.handleSessionFailure()
                                onStepChange(TmuxInstallationStep.FAILED.name, "tmux installation failed. See instructions.", 0)
                                return@withContext TmuxInstallationStep.FAILED
                            }
                        }
                    }
                    else -> {
                        val errorMsg = TmuxHelper.handleSessionFailure()
                        onStepChange(TmuxInstallationStep.FAILED.name, "tmux check failed. See instructions.", 0)
                        return@withContext TmuxInstallationStep.FAILED
                    }
                }

                // Configure tmux environment
                onStepChange(TmuxInstallationStep.CONFIGURING_TMUX.name, "Configuring tmux environment...", TmuxInstallationStep.CONFIGURING_TMUX.maxWaitSeconds)
                
                if (!TmuxHelper.ensurePersistentSession()) {
                    android.util.Log.e("TmuxInstall", "Failed to create persistent session")
                    onStepChange(TmuxInstallationStep.FAILED.name, "Failed to create tmux session", 0)
                    return@withContext TmuxInstallationStep.FAILED
                }

                // Cleanup orphaned processes
                TmuxHelper.cleanupOrphans()

                // Clear old log files
                clearOldLogFiles(downloadsDir)

                // Create installation script
                val installScript = createInstallationScript(statusFile, lutePort, downloadsDir)

                // Send installation script to tmux session
                android.util.Log.d("TmuxInstall", "Sending installation script to tmux session")
                
                if (!TmuxHelper.sendCommand(installScript)) {
                    android.util.Log.e("TmuxInstall", "Failed to send installation script")
                    onStepChange(TmuxInstallationStep.FAILED.name, "Failed to start installation", 0)
                    return@withContext TmuxInstallationStep.FAILED
                }

                // Poll for completion
                val result = pollInstallationStatus(statusFile, onStepChange)
                
                // Cleanup
                TmuxHelper.killSession()
                TmuxHelper.clearInstallLock()
                
                return@withContext result

            } catch (e: Exception) {
                android.util.Log.e("TmuxInstall", "Installation failed: ${e.message}")
                TmuxHelper.killSession()
                TmuxHelper.clearInstallLock()
                onStepChange(TmuxInstallationStep.FAILED.name, "Installation failed: ${e.message}", 0)
                return@withContext TmuxInstallationStep.FAILED
            }

        } catch (e: Exception) {
            android.util.Log.e("TmuxInstall", "Installation failed: ${e.message}")
            onStepChange(TmuxInstallationStep.FAILED.name, "Installation failed: ${e.message}", 0)
            TmuxInstallationStep.FAILED
        }
    }
}

private fun createInstallationScript(statusFile: String, lutePort: Int, downloadsDir: String): String {
    return """
        #!/data/data/com.termux/files/usr/bin/bash
        
        set -e  # Stop on any error
        
        # Configure tmux environment
        export TMUX_TMPDIR=${TermuxConstants.TMUX_SOCKET_DIR}
        
        # Acquire wake lock for background execution
        termux-wake-lock
        
        # Function to update status
        update_status() {
            local step="${'$'}1"
            local message="${'$'}2"
            echo "STEP:${'$'}step" > "$statusFile"
            android.util.Log.d("TmuxInstall", "Step ${'$'}step: ${'$'}message")
        }
        
        # Function to log to specific files
        log_to_file() {
            local log_file="${'$'}1"
            local message="${'$'}2"
            echo "${'$'}message" >> "${'$'}log_file"
        }
        
        # Clear old status
        update_status "CONFIGURING_MIRRORS" "Starting installation..."
        
        # Configure Termux mirrors
        log_to_file "$downloadsDir/lute_mirrors.log" "Configuring mirrors..."
        echo 'deb https://packages.termux.dev/apt/termux-main stable main' > ${'$'}PREFIX/etc/apt/sources.list
        update_status "UPDATING_PACKAGES" "Mirrors configured"
        
        # Update package lists
        log_to_file "$downloadsDir/lute_pkg_update.log" "Starting: pkg update"
        pkg update -y 2>&1 | tee -a "$downloadsDir/lute_pkg_update.log"
        log_to_file "$downloadsDir/lute_pkg_update.log" "Completed: pkg update"
        update_status "UPGRADING_PACKAGES" "Package lists updated"
        
        # Upgrade packages
        log_to_file "$downloadsDir/lute_pkg_upgrade.log" "Starting: pkg upgrade"
        pkg upgrade -y 2>&1 | tee -a "$downloadsDir/lute_pkg_upgrade.log"
        log_to_file "$downloadsDir/lute_pkg_upgrade.log" "Completed: pkg upgrade"
        update_status "INSTALLING_PYTHON3" "Packages upgraded"
        
        # Install Python3
        log_to_file "$downloadsDir/lute_python_install.log" "Starting: pkg install python3"
        pkg install python3 -y 2>&1 | tee -a "$downloadsDir/lute_python_install.log"
        log_to_file "$downloadsDir/lute_python_install.log" "Completed: pkg install python3"
        update_status "VERIFYING_PYTHON" "Python3 installed"
        
        # Verify Python installation
        log_to_file "$downloadsDir/lute_python_verify.log" "Starting: python --version"
        python --version 2>&1 | tee -a "$downloadsDir/lute_python_verify.log"
        log_to_file "$downloadsDir/lute_python_verify.log" "Completed: python verification"
        update_status "UPGRADING_PIP" "Python verified"
        
        # Upgrade pip
        log_to_file "$downloadsDir/lute_pip_upgrade.log" "Starting: pip install --upgrade pip"
        pip install --upgrade pip 2>&1 | tee -a "$downloadsDir/lute_pip_upgrade.log"
        log_to_file "$downloadsDir/lute_pip_upgrade.log" "Completed: pip upgrade"
        update_status "INSTALLING_LUTE3" "pip upgraded"
        
        # Install Lute3
        log_to_file "$downloadsDir/lute_lute3_install.log" "Starting: pip install --upgrade lute3"
        pip install --upgrade lute3 2>&1 | tee -a "$downloadsDir/lute_lute3_install.log"
        log_to_file "$downloadsDir/lute_lute3_install.log" "Completed: lute3 installation"
        update_status "VERIFYING_LUTE3" "Lute3 installed"
        
        # Verify Lute3 installation
        log_to_file "$downloadsDir/lute_lute3_verify.log" "Starting: lute3 --version"
        lute3 --version 2>&1 | tee -a "$downloadsDir/lute_lute3_verify.log"
        log_to_file "$downloadsDir/lute_lute3_verify.log" "Completed: lute3 verification"
        update_status "STARTING_SERVER" "Lute3 verified"
        
        # Start Lute3 server for verification
        log_to_file "$downloadsDir/lute_server_start.log" "Starting: python -m lute.main --port $lutePort"
        python -m lute.main --port $lutePort &
        LUTE_PID=${'$'}!
        log_to_file "$downloadsDir/lute_server_start.log" "Server started with PID: ${'$'}LUTE_PID"
        update_status "VERIFYING_SERVER" "Server starting"
        
        # Wait for server to be ready
        log_to_file "$downloadsDir/lute_server_verify.log" "Starting: server verification"
        sleep 3
        for i in {1..10}; do
            if curl -s http://localhost:$lutePort > /dev/null 2>&1; then
                log_to_file "$downloadsDir/lute_server_verify.log" "Server responding successfully"
                update_status "FINAL_CHECK" "Server verified"
                break
            fi
            if [ ${'$'}i -eq 10 ]; then
                log_to_file "$downloadsDir/lute_server_verify.log" "Server failed to respond"
                kill ${'$'}LUTE_PID 2>/dev/null || true
                update_status "FAILED" "Server verification failed"
                termux-wake-unlock
                exit 1
            fi
            sleep 1
        done
        
        # Stop verification server
        kill ${'$'}LUTE_PID 2>/dev/null || true
        log_to_file "$downloadsDir/lute_server_verify.log" "Server stopped for cleanup"
        
        # Final verification
        if command -v python3 > /dev/null && command -v pip > /dev/null && command -v lute3 > /dev/null; then
            log_to_file "$downloadsDir/lute_final_check.log" "All tools verified successfully"
            update_status "COMPLETE" "Installation completed successfully"
            termux-wake-unlock
            exit 0
        else
            log_to_file "$downloadsDir/lute_final_check.log" "Missing tools detected"
            update_status "FAILED" "Final verification failed - missing tools"
            termux-wake-unlock
            exit 1
        fi
    """.trimIndent()
}

private suspend fun pollInstallationStatus(
    statusFile: String,
    onStepChange: (stepName: String, stepStatus: String, maxWaitSeconds: Int) -> Unit
): TmuxInstallationStep {
    val startTime = System.currentTimeMillis()
    val timeoutMs = 30 * 60 * 1000L // 30 minutes
    var lastStep = ""

    while (System.currentTimeMillis() - startTime < timeoutMs) {
        delay(5000) // Poll every 5 seconds

        try {
            val file = File(statusFile)
            if (!file.exists()) continue

            val content = file.readText().trim()
            android.util.Log.d("TmuxInstall", "Status file content: $content")

            when {
                content.startsWith("STEP:") -> {
                    val stepPart = content.substringAfter("STEP:")
                    
                    // Map step content to enum
                    val currentStep = when {
                        stepPart.contains("CONFIGURING_MIRRORS") -> TmuxInstallationStep.CONFIGURING_MIRRORS
                        stepPart.contains("UPDATING_PACKAGES") -> TmuxInstallationStep.UPDATING_PACKAGES
                        stepPart.contains("UPGRADING_PACKAGES") -> TmuxInstallationStep.UPGRADING_PACKAGES
                        stepPart.contains("INSTALLING_PYTHON3") -> TmuxInstallationStep.INSTALLING_PYTHON3
                        stepPart.contains("VERIFYING_PYTHON") -> TmuxInstallationStep.VERIFYING_PYTHON
                        stepPart.contains("UPGRADING_PIP") -> TmuxInstallationStep.UPGRADING_PIP
                        stepPart.contains("INSTALLING_LUTE3") -> TmuxInstallationStep.INSTALLING_LUTE3
                        stepPart.contains("VERIFYING_LUTE3") -> TmuxInstallationStep.VERIFYING_LUTE3
                        stepPart.contains("STARTING_SERVER") -> TmuxInstallationStep.STARTING_SERVER
                        stepPart.contains("VERIFYING_SERVER") -> TmuxInstallationStep.VERIFYING_SERVER
                        stepPart.contains("FINAL_CHECK") -> TmuxInstallationStep.FINAL_CHECK
                        stepPart.contains("COMPLETE") -> TmuxInstallationStep.COMPLETE
                        stepPart.contains("FAILED") -> TmuxInstallationStep.FAILED
                        else -> null
                    }

                    currentStep?.let { step ->
                        if (step.name != lastStep) {
                            lastStep = step.name
                            android.util.Log.d("TmuxInstall", "Step change: ${step.name} - ${step.status}")
                            onStepChange(step.name, step.status, step.maxWaitSeconds)

                            when (step) {
                                TmuxInstallationStep.COMPLETE -> {
                                    file.delete()
                                    return TmuxInstallationStep.COMPLETE
                                }
                                TmuxInstallationStep.FAILED -> {
                                    file.delete()
                                    return TmuxInstallationStep.FAILED
                                }
                                else -> {
                                    // Continue polling
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.w("TmuxInstall", "Status check error: ${e.message}")
        }
    }

    // Timeout reached
    try { File(statusFile).delete() } catch (e: Exception) {}
    onStepChange(TmuxInstallationStep.FAILED.name, "Installation timed out", 0)
    return TmuxInstallationStep.FAILED
}

private fun clearOldLogFiles(downloadsDir: String) {
    try {
        val logFiles = listOf(
            "lute_mirrors.log",
            "lute_pkg_update.log", 
            "lute_pkg_upgrade.log",
            "lute_python_install.log",
            "lute_python_verify.log",
            "lute_pip_upgrade.log",
            "lute_lute3_install.log",
            "lute_lute3_verify.log",
            "lute_server_start.log",
            "lute_server_verify.log",
            "lute_final_check.log"
        )
        
        logFiles.forEach { logFile ->
            File("$downloadsDir/$logFile").delete()
        }
        
        android.util.Log.d("TmuxInstall", "Cleared old log files")
    } catch (e: Exception) {
        android.util.Log.w("TmuxInstall", "Failed to clear log files: ${e.message}")
    }
}