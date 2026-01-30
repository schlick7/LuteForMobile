package com.schlick7.luteformobile

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class TermuxBridge(private val context: Context) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    fun registerMethodChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.schlick7.luteformobile/termux"
        )
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
                        val status = isLute3Installed(context)
                        withContext(Dispatchers.Main) {
                            result.success(status.name)
                        }
                    }
                }
                "isServerRunning" -> {
                    scope.launch {
                        val running = isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)
                        withContext(Dispatchers.Main) {
                            result.success(running)
                        }
                    }
                }
                "getLute3Version" -> {
                    scope.launch {
                        val version = getLute3Version(context)
                        withContext(Dispatchers.Main) {
                            result.success(version)
                        }
                    }
                }
                "getTermuxVersion" -> {
                    scope.launch {
                        val version = getTermuxVersion(context)
                        withContext(Dispatchers.Main) {
                            result.success(version)
                        }
                    }
                }
                "checkExternalAppsEnabled" -> {
                    scope.launch {
                        val enabled = checkExternalAppsEnabled(context)
                        withContext(Dispatchers.Main) {
                            result.success(enabled)
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
                    touchHeartbeat(context)
                    result.success(true)
                }
                
                // Installation
                "installLute3" -> {
                    scope.launch {
                        val installResult = installLute3ServerWithProgress(context) { step ->
                            // Could send progress updates via EventChannel if needed
                        }
                        withContext(Dispatchers.Main) {
                            result.success(installResult.name)
                        }
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
                    }
                }
                "downloadBackup" -> {
                    val filename = call.argument<String>("filename") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "filename required", null)
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
                    val remoteUrl = call.argument<String>("remoteUrl") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "remoteUrl required", null)
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
    val script = "pip show lute3 | grep Version > $versionFile"
    
    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
    
    delay(TermuxConstants.VERSION_CHECK_DELAY * 1000L)
    
    return try {
        val file = java.io.File(versionFile)
        if (file.exists()) {
            file.readText().removePrefix("Version: ").trim()
        } else null
    } catch (e: Exception) {
        null
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
    context.startService(intent)
    
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

private suspend fun checkExternalAppsEnabled(context: Context): Boolean {
    val testFile = TermuxConstants.TEST_EXTERNAL_FILE
    val script = "echo 'test' > $testFile"
    
    val intent = android.content.Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
    
    delay(TermuxConstants.EXTERNAL_APP_CHECK_DELAY * 1000L)
    
    return try {
        val file = java.io.File(testFile)
        file.exists() && file.readText().contains("test")
    } catch (e: Exception) {
        false
    }
}
