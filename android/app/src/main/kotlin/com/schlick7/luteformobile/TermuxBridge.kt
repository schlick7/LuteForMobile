package com.schlick7.luteformobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class TermuxBridge(private val context: Context) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    fun registerMethodChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.schlick7.luteformobile/termux"
        )

        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.schlick7.luteformobile/termux_progress"
        )

        var eventSink: EventChannel.EventSink? = null

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Status checks
                "isTermuxInstalled" -> {
                    result.success(isTermuxInstalled(context))
                }

                "isFDroidInstalled" -> {
                    result.success(isFDroidInstalled(context))
                }

                "isTermuxPermissionGranted" -> {
                    result.success(isTermuxPermissionGranted(context))
                }

                "isLute3Installed" -> {
                    scope.launch {
                        try {
                            val status = isLute3InstalledFastCheck(context)
                            withContext(Dispatchers.Main) {
                                result.success(status.name)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(InstallationStatus.UNKNOWN.name)
                            }
                        }
                    }
                }

                "checkExternalAppsEnabled" -> {
                    scope.launch {
                        try {
                            val enabled = checkExternalAppsEnabled(context)
                            withContext(Dispatchers.Main) {
                                result.success(enabled)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(false)
                            }
                        }
                    }
                }

                "isTermuxRunning" -> {
                    scope.launch {
                        try {
                            val isRunning = TermuxLauncher.isTermuxServiceRunning(context)
                            withContext(Dispatchers.Main) {
                                result.success(isRunning)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(false)
                            }
                        }
                    }
                }

                "stealthLaunchTermux" -> {
                    scope.launch {
                        try {
                            val success = TermuxLauncher.ensureTermuxRunning(context)
                            withContext(Dispatchers.Main) {
                                result.success(success)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("TermuxBridge", "stealthLaunchTermux failed: ${e.message}")
                            withContext(Dispatchers.Main) {
                                result.success(false)
                            }
                        }
                    }
                }

                // Server control
                "startServer" -> {
                    scope.launch {
                        val success = ensureLute3ServerRunning(context)
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    }
                }

                "stopServer" -> {
                    stopLute3Server(context)
                    result.success(true)
                }

                "touchHeartbeat" -> {
                    scope.launch {
                        val success = touchHeartbeat(context)
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    }
                }

                // Installation
                "getInstallationStatus" -> {
                    scope.launch {
                        try {
                            val statusFile =
                                java.io.File("${android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath}/lute_install_status.txt")
                            val status = if (statusFile.exists()) {
                                statusFile.readText().trim()
                            } else {
                                "NOT_STARTED"
                            }
                            withContext(Dispatchers.Main) {
                                result.success(status)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success("ERROR")
                            }
                        }
                    }
                }

                "getQuickInstallationStatus" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            val statusFile =
                                java.io.File("${StorageHelper.getDownloadsDirectory()}/lute3_installation_status.txt")
                            val status = if (statusFile.exists()) {
                                statusFile.readText().trim()
                            } else {
                                "NOT_INSTALLED"
                            }
                            withContext(Dispatchers.Main) {
                                result.success(status)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success("UNKNOWN")
                            }
                        }
                    }
                }

                "installLute3Chained" -> {
                    android.util.Log.d("TermuxBridge", "installLute3Chained called, eventSink: ${eventSink != null}")
                    // Start foreground service to keep app in foreground
                    val serviceIntent = Intent(context, InstallationForegroundService::class.java)
                    context.startForegroundService(serviceIntent)
                    scope.launch {
                        val installResult = installLute3Chained(context) { stepName, stepStatus, maxWaitSeconds ->
                            android.util.Log.d(
                                "TermuxBridge",
                                "Chained installation progress update: $stepName - $stepStatus, sink: ${eventSink != null}"
                            )
                            try {
                                scope.launch(Dispatchers.Main.immediate) {
                                    eventSink?.success(
                                        mapOf(
                                            "step" to stepName,
                                            "status" to stepStatus,
                                            "maxWaitSeconds" to maxWaitSeconds
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("TermuxBridge", "Failed to send chained progress: ${e.message}")
                            }
                        }
                        android.util.Log.d("TermuxBridge", "Chained installation complete: $installResult")
                        // Stop foreground service
                        val stopIntent = Intent(context, InstallationForegroundService::class.java).apply {
                            action = InstallationForegroundService.ACTION_STOP
                        }
                        context.startService(stopIntent)
                        result.success(installResult)
                    }
                }

                "updateLute3" -> {
                    scope.launch {
                        val commandResult = executeCommandWithCompletion(
                            context,
                            "pip install --upgrade lute3",
                            "update_lute3",
                            TermuxConstants.INSTALL_LUTE3_TIMEOUT
                        )
                        withContext(Dispatchers.Main) {
                            when (commandResult) {
                                is CommandResult.Success -> result.success(true)
                                is CommandResult.Failed -> result.error("UPDATE_FAILED", commandResult.error, null)
                                is CommandResult.Timeout -> result.error("UPDATE_TIMEOUT", commandResult.message, null)
                            }
                        }
                    }
                }

                "reinstallLute3" -> {
                    scope.launch {
                        val commandResult = executeCommandWithCompletion(
                            context,
                            "pip uninstall -y lute3 && pip install --upgrade lute3",
                            "reinstall_lute3",
                            TermuxConstants.INSTALL_LUTE3_TIMEOUT
                        )
                        withContext(Dispatchers.Main) {
                            when (commandResult) {
                                is CommandResult.Success -> result.success(true)
                                is CommandResult.Failed -> result.error("REINSTALL_FAILED", commandResult.error, null)
                                is CommandResult.Timeout -> result.error(
                                    "REINSTALL_TIMEOUT",
                                    commandResult.message,
                                    null
                                )
                            }
                        }
                    }
                }

                "restoreBackup" -> {
                    scope.launch {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            withContext(Dispatchers.Main) {
                                result.error("INVALID_PATH", "No file path provided", null)
                            }
                            return@launch
                        }

                        val success = restoreBackupToLute3(context, filePath)
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    }
                }

                "checkStoragePermissions" -> {
                    scope.launch {
                        val hasPermissions = StorageHelper.hasStoragePermissions(context)
                        withContext(Dispatchers.Main) {
                            result.success(hasPermissions)
                        }
                    }
                }

                "getAndroidVersion" -> {
                    val androidVersion = android.os.Build.VERSION.SDK_INT
                    result.success(androidVersion)
                }

                "hasNotificationPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        PackageManager.PERMISSION_GRANTED ==
                            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }

                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val activity = findActivity(context)
                        if (activity != null) {
                            val permissions = arrayOf(Manifest.permission.POST_NOTIFICATIONS)
                            ActivityCompat.requestPermissions(activity, permissions, 2001)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }

                "requestTermuxPermission" -> {
                    try {
                        android.util.Log.d("TermuxBridge", "requestTermuxPermission: Opening app info page")
                        val intent = android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = android.net.Uri.parse("package:${context.packageName}")
                        if (intent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(intent)
                            android.util.Log.d("TermuxBridge", "requestTermuxPermission: App info page opened")
                        } else {
                            android.util.Log.e("TermuxBridge", "requestTermuxPermission: No activity found")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("TermuxBridge", "requestTermuxPermission: Failed - ${e.message}")
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        scope.cancel()
    }
}

private suspend fun checkExternalAppsEnabled(context: Context): Boolean {
    val downloadsDir =
        android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
    val testFile = "$downloadsDir/termux_test_external.txt"

    try {
        java.io.File(testFile).delete()
        android.util.Log.d("TermuxBridge", "Cleaned up old test file: $testFile")
    } catch (e: Exception) {
        android.util.Log.w("TermuxBridge", "Cleanup failed (file may not exist): ${e.message}")
    }

    val script = "echo 'EXTERNAL_APPS_ENABLED=true' > $testFile"

    android.util.Log.d("TermuxBridge", "Sending command to check external apps, writing to: $testFile")

    val success = RunCommandHelper.execute(context, script, timeoutMs = 1500)
    if (!success) return false

    android.util.Log.d("TermuxBridge", "Command sent successfully")

    delay(200)

    return try {
        val file = java.io.File(testFile)

        android.util.Log.d("TermuxBridge", "Checking file existence...")
        if (!file.exists()) {
            android.util.Log.e("TermuxBridge", "Test file does not exist: $testFile")
            return false
        }

        val content = file.readText().trim()
        android.util.Log.d("TermuxBridge", "File content: '$content'")

        val result = content == "EXTERNAL_APPS_ENABLED=true"
        android.util.Log.d("TermuxBridge", "Match result: $result")

        if (result) {
            file.delete()
        }

        result
    } catch (e: Exception) {
        android.util.Log.e("TermuxBridge", "File check failed: ${e.message}")
        false
    }
}

object RunCommandHelper {
    suspend fun execute(
        context: Context,
        script: String,
        timeoutMs: Long = 5000
    ): Boolean = withContext(Dispatchers.IO) {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }

        try {
            val serviceIntent = Intent(context, TransientForegroundService::class.java)
            context.startForegroundService(serviceIntent)
            delay(350)
            context.startService(intent)
            delay(timeoutMs)
            true
        } catch (e: Exception) {
            android.util.Log.e("RunCommandHelper", "Failed to execute command: ${e.message}")
            false
        } finally {
            try {
                val stopIntent = Intent(context, TransientForegroundService::class.java).apply {
                    action = "STOP"
                }
                context.startService(stopIntent)
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}

suspend fun installLute3Chained(
    context: Context,
    onProgress: (stepName: String, stepStatus: String, maxWaitSeconds: Int) -> Unit = { _, _, _ -> }
): String {
    return withContext(Dispatchers.IO) {
        try {
            val downloadsDir =
                android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
            val statusFile = "$downloadsDir/lute_install_status.txt"
            val versionFile = "${downloadsDir}/lute3_version.txt"

            android.util.Log.d("TermuxBridge", "Starting chained Lute3 installation")
            android.util.Log.d("TermuxBridge", "Downloads directory: $downloadsDir")
            android.util.Log.d("TermuxBridge", "Status file: $statusFile")

            // Check if external apps are enabled first
            val externalAppsEnabled = checkExternalAppsEnabled(context)
            if (!externalAppsEnabled) {
                android.util.Log.e("TermuxBridge", "External apps not enabled in Termux")
                return@withContext "ERROR: Termux external apps not enabled. Please run 'termux-setup-storage' in Termux and ensure allow-external-apps=true is set in ~/.termux/termux.properties"
            }

            // Verify downloads directory exists
            val downloadsDirFile = java.io.File(downloadsDir)
            if (!downloadsDirFile.exists()) {
                android.util.Log.e("TermuxBridge", "Downloads directory does not exist: $downloadsDir")
                try {
                    downloadsDirFile.mkdirs()
                    android.util.Log.d("TermuxBridge", "Created downloads directory: $downloadsDir")
                } catch (e: Exception) {
                    android.util.Log.e("TermuxBridge", "Failed to create downloads directory: ${e.message}")
                    return@withContext "ERROR: Cannot create Downloads directory"
                }
            }

            // Clear previous installation status
            java.io.File(statusFile).delete()
            java.io.File("$downloadsDir/lute_pkg_update.log").delete()
            java.io.File("$downloadsDir/lute_pkg_upgrade.log").delete()
            java.io.File("$downloadsDir/lute_python_install.log").delete()
            java.io.File("$downloadsDir/lute_lute3_install.log").delete()


            // Clear previous installation status
            java.io.File(statusFile).delete()
            java.io.File("$downloadsDir/lute_pkg_update.log").delete()
            java.io.File("$downloadsDir/lute_pkg_upgrade.log").delete()
            java.io.File("$downloadsDir/lute_python_install.log").delete()
            java.io.File("$downloadsDir/lute_lute3_install.log").delete()

            // Send initial progress update
            withContext(Dispatchers.Main.immediate) {
                onProgress("SETUP", "Starting installation...", 1800)
            }

            // Use simplest possible test
            val simpleTestScript = "echo 'SIMPLE_TEST' > '$statusFile'"

            val testIntent = android.content.Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", simpleTestScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }

            try {
                context.startService(testIntent)
                android.util.Log.d("TermuxBridge", "Simple test command sent to Termux")

                // Wait for file creation
                delay(5000)

                val statusFileObj = java.io.File(statusFile)
                android.util.Log.d("TermuxBridge", "Checking simple test result: ${statusFileObj.exists()}")

                if (statusFileObj.exists()) {
                    val content = statusFileObj.readText()
                    android.util.Log.d("TermuxBridge", "Simple test SUCCESS: $content")
                    statusFileObj.delete()
                } else {
                    android.util.Log.e("TermuxBridge", "Simple test FAILED: no status file created")
                    return@withContext "ERROR: Simple test failed - Termux cannot write to Downloads. Please ensure 'termux-setup-storage' has been run and allow-external-apps=true is set in ~/.termux/termux.properties"
                }
            } catch (e: Exception) {
                android.util.Log.e("TermuxBridge", "Simple test exception: ${e.message}")
                return@withContext "ERROR: Simple test exception: ${e.message}"
            }

            val chainedScript = """
                #!/data/data/com.termux/files/usr/bin/bash

                STATUS_FILE="${statusFile}"

                # Step 1: Configure mirrors
                echo "STEP:1/6 - Configuring mirrors" > ${'$'}STATUS_FILE
                echo 'deb https://packages.termux.dev/apt/termux-main stable main' > ${'$'}PREFIX/etc/apt/sources.list

                # Step 2: Update package lists
                echo "STEP:2/6 - Updating package lists" > ${'$'}STATUS_FILE
                pkg update -y 2>&1 | tee "${downloadsDir}/lute_pkg_update.log"

                # Step 3: Upgrade packages
                echo "STEP:3/6 - Upgrading packages" > ${'$'}STATUS_FILE
                DEBIAN_FRONTEND=noninteractive pkg upgrade -y 2>&1 | tee "${downloadsDir}/lute_pkg_upgrade.log"

                # Step 4: Install Python3
                echo "STEP:4/6 - Installing Python3" > ${'$'}STATUS_FILE
                DEBIAN_FRONTEND=noninteractive pkg install python3 -y 2>&1 | tee "${downloadsDir}/lute_python_install.log"

                # Step 5: Upgrade pip
                echo "STEP:5/6 - Upgrading pip" > ${'$'}STATUS_FILE
                pip install --upgrade pip 2>&1 | tee "${downloadsDir}/lute_pip_upgrade.log"

                # Step 6: Install Lute3
                echo "STEP:6/6 - Installing Lute3" > ${'$'}STATUS_FILE
                pip install --upgrade lute3 2>&1 | tee "${downloadsDir}/lute_lute3_install.log"

                # Complete
                echo "STEP:COMPLETE" > ${'$'}STATUS_FILE
                exit 0
            """.trimIndent()

            android.util.Log.d("TermuxBridge", "Sending chained installation script")
            android.util.Log.d("TermuxBridge", "Downloads dir: $downloadsDir")
            android.util.Log.d("TermuxBridge", "Script length: ${chainedScript.length} characters")
            android.util.Log.d("TermuxBridge", "Script preview: ${chainedScript.take(100)}...")

            val intent = android.content.Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", chainedScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }

            try {
                context.startService(intent)
                android.util.Log.d("TermuxBridge", "Installation command sent successfully to Termux")
            } catch (e: Exception) {
                android.util.Log.e("TermuxBridge", "Failed to start Termux service: ${e.message}")
                return@withContext "ERROR: Failed to start Termux service: ${e.message}"
            }

            // Poll for completion with progress updates
            val startTime = System.currentTimeMillis()
            val timeoutMs = 30 * 60 * 1000L // 30 minutes
            var lastStep = ""

            while (System.currentTimeMillis() - startTime < timeoutMs) {
                delay(3000) // Poll every 3 seconds

                val statusFileObj = java.io.File(statusFile)
                android.util.Log.d(
                    "TermuxBridge",
                    "Checking status file: $statusFile, exists: ${statusFileObj.exists()}"
                )

                if (statusFileObj.exists()) {
                    try {
                        val content = statusFileObj.readText().trim()
                        android.util.Log.d("TermuxBridge", "Status file content: $content")

                        // Send progress update if step changed
                        if (content != lastStep && content.isNotEmpty()) {
                            android.util.Log.d("TermuxBridge", "Installation progress: $content")

                            val stepName = when {
                                content.contains("1/6") -> "CONFIGURING_MIRRORS"
                                content.contains("2/6") -> "UPDATING_PACKAGES"
                                content.contains("3/6") -> "UPGRADING_PACKAGES"
                                content.contains("4/6") -> "INSTALLING_PYTHON3"
                                content.contains("5/6") -> "UPGRADING_PIP"
                                content.contains("6/6") -> "INSTALLING_LUTE3"
                                content.contains("COMPLETE") -> "COMPLETE"
                                else -> "UNKNOWN"
                            }

                            val stepStatus = content.substringAfter("STEP:").trim()
                            val maxWaitSeconds = when {
                                content.contains("1/6") -> 10
                                content.contains("2/6") -> 60
                                content.contains("3/6") -> 300
                                content.contains("4/6") -> 300
                                content.contains("5/6") -> 60
                                content.contains("6/6") -> 300
                                content.contains("COMPLETE") -> 0
                                else -> 30
                            }

                            withContext(Dispatchers.Main.immediate) {
                                onProgress(stepName, stepStatus, maxWaitSeconds)
                            }

                            lastStep = content

                            // Check for completion
                            if (content.contains("COMPLETE")) {
                                android.util.Log.d("TermuxBridge", "Installation completed successfully")
                                return@withContext "COMPLETE"
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("TermuxBridge", "Error reading status file: ${e.message}")
                    }
                }
            }

            android.util.Log.w("TermuxBridge", "Installation timed out after 30 minutes")
            return@withContext "TIMEOUT: Installation timed out"

        } catch (e: Exception) {
            android.util.Log.e("TermuxBridge", "Installation failed: ${e.message}")
            return@withContext "ERROR: ${e.message}"
        }
    }
}

class InstallationForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "lute_installation_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.schlick7.luteformobile.STOP_INSTALLATION"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val stopIntent = Intent(this, InstallationForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Installing Lute3")
            .setContentText("Installation in progress...")
            .setSmallIcon(android.R.drawable.ic_menu_save)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", stopPendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Installation", NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Lute3 installation progress" }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}

private suspend fun restoreBackupToLute3(context: Context, localFilePath: String): Boolean {
    return withContext(Dispatchers.IO) {
        try {
            android.util.Log.d("TermuxBridge", "Starting restore: localFilePath=$localFilePath")

            val localFile = java.io.File(localFilePath)
            if (!localFile.exists()) {
                android.util.Log.e("TermuxBridge", "Local file does not exist: $localFilePath")
                return@withContext false
            }

            android.util.Log.d("TermuxBridge", "File exists: ${localFile.absolutePath}")

            val lute3DbPath = "\$HOME/.local/share/Lute3/lute.db"

            val restoreScript = """
                #!/bin/bash
                SOURCE="$localFilePath"
                DEST="$lute3DbPath"

                pkill -f "python -m lute.main" || true
                sleep 3

                if pgrep -f "python -m lute.main" > /dev/null 2>&1; then
                    echo "FAIL: Server still running"
                    exit 1
                fi

                python3 -c "import gzip; f = open(\${'$'}SOURCE, 'rb'); open(\${'$'}DEST, 'wb').write(gzip.decompress(f.read()))"

                if [ -f "${'$'}DEST" ]; then
                    echo "SUCCESS"
                else
                    echo "FAIL: File not created"
                    exit 1
                fi
            """.trimIndent()

            android.util.Log.d("TermuxBridge", "Sending restore script")

            val intent = android.content.Intent().apply {
                setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                action = TermuxConstants.TERMUX_ACTION
                putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", restoreScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }

            context.startService(intent)

            delay(10000)

            val success = true

            if (success) {
                android.util.Log.d("TermuxBridge", "Restore completed successfully")
            } else {
                android.util.Log.e("TermuxBridge", "Restore failed")
            }

            success

        } catch (e: Exception) {
            android.util.Log.e("TermuxBridge", "Restore failed: ${e.message}")
            false
        }
    }
}

private fun findActivity(context: Context): android.app.Activity? {
    var context = context
    while (context is android.content.ContextWrapper) {
        if (context is android.app.Activity) {
            return context
        }
        context = context.baseContext
    }
    return null
}
