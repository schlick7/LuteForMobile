package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import kotlinx.coroutines.delay

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
