package com.schlick7.luteformobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
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

                "isTermuxPermissionGranted" -> {
                    result.success(isTermuxPermissionGranted(context))
                }

                "isLute3Installed" -> {
                    scope.launch {
                        try {
                            val status = isLute3Installed(context)
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

                "isServerRunning" -> {
                    scope.launch {
                        try {
                            val running = isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)
                            withContext(Dispatchers.Main) {
                                result.success(running)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(false)
                            }
                        }
                    }
                }

                "getLute3Version" -> {
                    scope.launch {
                        try {
                            val version = getLute3Version(context)
                            withContext(Dispatchers.Main) {
                                result.success(version)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(null)
                            }
                        }
                    }
                }

                "getTermuxVersion" -> {
                    scope.launch {
                        try {
                            val version = getTermuxVersion(context)
                            withContext(Dispatchers.Main) {
                                result.success(version)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(null)
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

                // Server control
                "startServer" -> {
                    launchLute3ServerWithAutoShutdown(context)
                    result.success(true)
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
                "installLute3" -> {
                    android.util.Log.d("TermuxBridge", "installLute3 called, eventSink: ${eventSink != null}")
                    // Start foreground service to keep app in foreground
                    val serviceIntent = Intent(context, InstallationForegroundService::class.java)
                    context.startForegroundService(serviceIntent)
                    scope.launch {
                        val installResult = installLute3ServerWithProgress(context) { stepName, stepStatus, maxWaitSeconds ->
                            android.util.Log.d("TermuxBridge", "Progress update: $stepName - $stepStatus, sink: ${eventSink != null}")
                            try {
                                scope.launch(Dispatchers.Main.immediate) {
                                    eventSink?.success(mapOf(
                                        "step" to stepName,
                                        "status" to stepStatus,
                                        "maxWaitSeconds" to maxWaitSeconds
                                    ))
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("TermuxBridge", "Failed to send progress: ${e.message}")
                            }
                        }
                        android.util.Log.d("TermuxBridge", "Installation complete: $installResult")
                        // Stop foreground service
                        val stopIntent = Intent(context, InstallationForegroundService::class.java).apply {
                            action = InstallationForegroundService.ACTION_STOP
                        }
                        context.startService(stopIntent)
                        result.success(installResult.name)
                    }
                }

                "updateLute3" -> {
                    val script = "pip install --upgrade lute3"
                    val intent = android.content.Intent().apply {
                        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                        action = TermuxConstants.TERMUX_ACTION
                        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
                        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
                    }
                    context.startService(intent)
                    result.success(true)
                }

                "reinstallLute3" -> {
                    val script = "pip uninstall -y lute3 && pip install --upgrade lute3"
                    val intent = android.content.Intent().apply {
                        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
                        action = TermuxConstants.TERMUX_ACTION
                        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
                        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
                        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
                    }
                    context.startService(intent)
                    result.success(true)
                }

                // Backup operations
                "createBackup" -> {
                    scope.launch {
                        val backupResult = triggerLute3Backup(context, backupType = BackupType.MANUAL)
                        withContext(Dispatchers.Main) {
                            when (backupResult) {
                                is BackupResult.Success -> result.success(backupResult.message)
                                is BackupResult.Error -> result.error("BACKUP_ERROR", backupResult.message, null)
                            }
                        }
                    }
                }

                "listBackups" -> {
                    scope.launch {
                        try {
                            val backups = listBackups(context)
                            withContext(Dispatchers.Main) {
                                result.success(backups?.map { backup ->
                                    mapOf(
                                        "filename" to backup.filename,
                                        "lastModified" to backup.lastModified,
                                        "size" to backup.size,
                                        "isManual" to backup.isManual
                                    )
                                })
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(null)
                            }
                        }
                    }
                }

                "downloadBackup" -> {
                    val filename = call.argument<String>("filename")
                        ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "filename required", null)
                    scope.launch {
                        val downloadResult = downloadBackup(context, filename)
                        withContext(Dispatchers.Main) {
                            when (downloadResult) {
                                is DownloadResult.Success -> result.success(downloadResult.filePath)
                                is DownloadResult.Error -> result.error("DOWNLOAD_ERROR", downloadResult.message, null)
                            }
                        }
                    }
                }

                "restoreBackup" -> {
                    scope.launch {
                        val file = selectBackupFile(context)
                        if (file != null) {
                            val restoreResult = restoreDatabaseFromDownloads(context, file)
                            withContext(Dispatchers.Main) {
                                when (restoreResult) {
                                    is RestoreResult.Success -> result.success(restoreResult.message)
                                    is RestoreResult.Error -> result.error("RESTORE_ERROR", restoreResult.message, null)
                                }
                            }
                        } else {
                            result.error("NO_BACKUP", "No backup file found in Downloads", null)
                        }
                    }
                }

                "syncWithRemote" -> {
                    val remoteUrl = call.argument<String>("remoteUrl")
                        ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "remoteUrl required", null)
                    val apiKey = call.argument<String>("apiKey")
                    scope.launch {
                        val syncResult = syncWithRemoteServer(context, remoteUrl, apiKey)
                        withContext(Dispatchers.Main) {
                            when (syncResult) {
                                is SyncResult.Success -> result.success(syncResult.message)
                                is SyncResult.Error -> result.error("SYNC_ERROR", syncResult.message, null)
                            }
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

                "requestStoragePermissions" -> {
                    result.error("NOT_IMPLEMENTED", "Use permission_handler package in Dart instead", null)
                }

                "getAndroidVersion" -> {
                    val androidVersion = android.os.Build.VERSION.SDK_INT
                    result.success(androidVersion)
                }

                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        scope.cancel()
    }
}

// Top-level helper functions for getting version info
private suspend fun getLute3Version(context: Context): String? {
    val versionFile = TermuxConstants.VERSION_FILE
    
    // Clean up old version file
    try {
        java.io.File(versionFile).delete()
    } catch (e: Exception) {
        // Ignore
    }
    
    val script = "pip show lute3 > $versionFile"
    
    android.util.Log.d("TermuxBridge", "Checking lute3 version, writing to: $versionFile")
    
    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    
    try {
        context.startService(intent)
        android.util.Log.d("TermuxBridge", "Version check command sent")
    } catch (e: Exception) {
        android.util.Log.e("TermuxBridge", "Failed to send version check: ${e.message}")
        return null
    }
    
    delay(TermuxConstants.VERSION_CHECK_DELAY * 1000L)
    
    return try {
        val file = java.io.File(versionFile)
        android.util.Log.d("TermuxBridge", "Version file exists: ${file.exists()}")
        
        if (file.exists()) {
            val content = file.readText()
            android.util.Log.d("TermuxBridge", "Version file content: '$content'")
            
            val versionLine = content.lines().find { it.contains("Version") }
            val version = versionLine?.removePrefix("Version: ")?.trim()
            android.util.Log.d("TermuxBridge", "Extracted version: $version")
            version
        } else {
            android.util.Log.w("TermuxBridge", "Version file does not exist")
            null
        }
    } catch (e: Exception) {
        android.util.Log.e("TermuxBridge", "Version check failed: ${e.message}")
        null
    }
}

private suspend fun checkExternalAppsEnabled(context: Context): Boolean {
    val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).absolutePath
    val testFile = "$downloadsDir/termux_test_external.txt"
    
    // Clean up any previous test file
    try {
        java.io.File(testFile).delete()
        android.util.Log.d("TermuxBridge", "Cleaned up old test file: $testFile")
    } catch (e: Exception) {
        android.util.Log.w("TermuxBridge", "Cleanup failed (file may not exist): ${e.message}")
    }
    
    val script = """
        echo 'EXTERNAL_APPS_ENABLED=true' > $testFile
    """.trimIndent()
    
    android.util.Log.d("TermuxBridge", "Sending command to check external apps, writing to: $testFile")
    
    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    
    try {
        context.startService(intent)
        android.util.Log.d("TermuxBridge", "Command sent successfully")
    } catch (e: Exception) {
        android.util.Log.e("TermuxBridge", "Failed to send command: ${e.message}")
        return false
    }
    
    // Wait for command to complete (echo is instant)
    delay(300)
    
    // Check if file was created with expected content
    return try {
        val file = java.io.File(testFile)
        
        android.util.Log.d("TermuxBridge", "Checking file existence...")
        if (!file.exists()) {
            android.util.Log.e("TermuxBridge", "Test file does not exist: $testFile")
            return false
        }
        
        val content = file.readText().trim()
        android.util.Log.d("TermuxBridge", "File content: '$content'")
        
        val success = content == "EXTERNAL_APPS_ENABLED=true"
        android.util.Log.d("TermuxBridge", "Match result: $success")
        
        if (success) {
            file.delete()
        }
        
        success
    } catch (e: Exception) {
        android.util.Log.e("TermuxBridge", "File check failed: ${e.message}")
        false
    }
}

private suspend fun checkExternalAppsByFileCreation(context: Context): Boolean {
    // Use Downloads directory for the test file - both apps can access it
    val testDir = "${android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)}/termux_external_test_dir"
    val testFile = "$testDir/termux_external_test.txt"
    
    // Clean up any previous test files
    try {
        java.io.File(testFile).delete()
        java.io.File(testDir).delete()
    } catch (e: Exception) {
        // Ignore cleanup errors
    }
    
    // Enhanced script that tests multiple aspects:
    // 1. Directory creation
    // 2. File writing
    // 3. File reading
    // 4. Permission checks
    val script = """
        # Create test directory
        mkdir -p $testDir && \
        # Write test file with timestamp
        echo "External apps test: $(date)" > $testFile && \
        # Verify file exists and is readable
        if [ -f $testFile ] && [ -r $testFile ]; then
            # Read the file content to verify
            cat $testFile && \
            # Test if we can write to the app's directory
            echo "Test completed successfully" >> $testFile && \
            # Return success
            echo "EXTERNAL_APPS_ENABLED=true"
        else
            # Return failure
            echo "EXTERNAL_APPS_ENABLED=false"
            exit 1
        fi
    """.trimIndent()

    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    try {
        context.startService(intent)
    } catch (e: Exception) {
        // If we can't even send the command, external apps are definitely not enabled
        return false
    }

    // Wait for the command to complete with extended timeout for Termux 0.118.3
    delay((TermuxConstants.EXTERNAL_APP_CHECK_DELAY * 2) * 1000L)

    // Check if the file was created successfully by reading it from the app's directory
    return try {
        val file = java.io.File(testFile)
        val exists = file.exists() && file.canRead()
        
        // Read the file content to verify the test result
        val content = if (exists) file.readText().trim() else ""
        val success = content.contains("EXTERNAL_APPS_ENABLED=true")
        
        // Clean up the test files
        try {
            file.delete()
            java.io.File(testDir).delete()
        } catch (e: Exception) {
            // Ignore cleanup errors
        }
        
        success
    } catch (e: Exception) {
        false
    }
}

private suspend fun checkExternalAppsByCommandExecution(context: Context): Boolean {
    val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
    val testFile = "$downloadsDir/termux_command_test.txt"
    
    // Clean up
    try {
        java.io.File(testFile).delete()
    } catch (e: Exception) {
        // Ignore cleanup errors
    }
    
    // Simpler test: just try to run a basic command
    val script = """
        mkdir -p $downloadsDir && \
        echo "Command execution test: $(date)" > $testFile && \
        echo "COMMAND_SUCCESS=true"
    """.trimIndent()

    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    try {
        context.startService(intent)
    } catch (e: Exception) {
        return false
    }

    delay(TermuxConstants.EXTERNAL_APP_CHECK_DELAY * 1000L)

    return try {
        val file = java.io.File(testFile)
        val exists = file.exists() && file.canRead()
        
        if (exists) {
            val content = file.readText().trim()
            val success = content.contains("COMMAND_SUCCESS=true")
            file.delete()
            success
        } else {
            false
        }
    } catch (e: Exception) {
        false
    }
}

private suspend fun checkExternalAppsByConfigFile(context: Context): Boolean {
    // Check if Termux configuration file has allow-external-apps enabled
    val configFile = "${TermuxConstants.TERMUX_HOME}/.termux/termux.properties"
    val downloadsDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
    val checkResultFile = "$downloadsDir/termux_config_check.txt"
    
    // Clean up
    try {
        java.io.File(checkResultFile).delete()
    } catch (e: Exception) {
        // Ignore cleanup errors
    }
    
    val script = """
        mkdir -p $downloadsDir && \
        # Check if the configuration file exists and contains allow-external-apps=true
        if [ -f $configFile ]; then
            if grep -q "allow-external-apps=true" $configFile; then
                echo "CONFIG_EXTERNAL_APPS=true" > $checkResultFile
            else
                echo "CONFIG_EXTERNAL_APPS=false" > $checkResultFile
            fi
        else
            echo "CONFIG_EXTERNAL_APPS=false" > $checkResultFile
        fi
    """.trimIndent()

    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    try {
        context.startService(intent)
    } catch (e: Exception) {
        return false
    }

    delay(TermuxConstants.EXTERNAL_APP_CHECK_DELAY * 1000L)

    return try {
        val file = java.io.File(checkResultFile)
        if (file.exists() && file.canRead()) {
            val content = file.readText().trim()
            val success = content.contains("CONFIG_EXTERNAL_APPS=true")
            file.delete()
            success
        } else {
            false
        }
    } catch (e: Exception) {
        false
    }
}

private suspend fun getTermuxVersion(context: Context): String? {
    val versionFile = TermuxConstants.TERMUX_VERSION_FILE
    val script = "termux --version > $versionFile 2>&1"

    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }

    try {
        context.startService(intent)
    } catch (e: Exception) {
        return null
    }

    delay(TermuxConstants.VERSION_CHECK_DELAY * 1000L)

    return try {
        val file = java.io.File(versionFile)
        if (file.exists()) {
            file.readText().trim()
        } else null
    } catch (e: Exception) {
        null
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

        startForeground(NOTIFICATION_ID, notification)
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
