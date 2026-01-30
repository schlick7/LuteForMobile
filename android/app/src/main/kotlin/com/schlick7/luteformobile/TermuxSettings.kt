package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class TermuxConnectionStatus(
    val termuxInstalled: Boolean,
    val termuxPermissionGranted: Boolean,
    val externalAppsEnabled: Boolean,
    val lute3Status: InstallationStatus,
    val lute3Version: String?,
    val termuxVersion: String?,
    val serverRunning: Boolean
)

suspend fun getTermuxConnectionStatus(context: Context): TermuxConnectionStatus {
    val termuxInstalled = isTermuxInstalled(context)
    val permissionGranted = isTermuxPermissionGranted(context)
    val lute3Status = isLute3Installed(context)
    val serverRunning = isLute3ServerRunningHttp(TermuxConstants.LUTE3_DEFAULT_PORT)

    val lute3Version = if (lute3Status == InstallationStatus.INSTALLED) {
        getLute3Version(context)
    } else null

    val termuxVersion = if (termuxInstalled) {
        getTermuxVersion(context)
    } else null

    val externalAppsEnabled = if (termuxInstalled && permissionGranted) {
        checkExternalAppsEnabled(context)
    } else false

    return TermuxConnectionStatus(
        termuxInstalled = termuxInstalled,
        termuxPermissionGranted = permissionGranted,
        externalAppsEnabled = externalAppsEnabled,
        lute3Status = lute3Status,
        lute3Version = lute3Version,
        termuxVersion = termuxVersion,
        serverRunning = serverRunning
    )
}

suspend fun getLute3Version(context: Context): String? {
    val versionFile = TermuxConstants.VERSION_FILE
    val script = "pip show lute3 | grep Version > $versionFile"

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)

    delay(TermuxConstants.VERSION_CHECK_DELAY * 1000L)

    return try {
        val file = File(versionFile)
        if (file.exists()) {
            file.readText().removePrefix("Version: ").trim()
        } else null
    } catch (e: Exception) {
        null
    }
}

suspend fun getTermuxVersion(context: Context): String? {
    val versionFile = TermuxConstants.TERMUX_VERSION_FILE
    val script = "termux --version > $versionFile 2>&1"

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)

    delay(TermuxConstants.VERSION_CHECK_DELAY * 1000L)

    return try {
        val file = File(versionFile)
        if (file.exists()) {
            file.readText().trim()
        } else null
    } catch (e: Exception) {
        null
    }
}

suspend fun checkExternalAppsEnabled(context: Context): Boolean {
    val testFile = TermuxConstants.TEST_EXTERNAL_FILE
    val script = "echo 'test' > $testFile"

    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)

    delay(TermuxConstants.EXTERNAL_APP_CHECK_DELAY * 1000L)

    return try {
        val file = File(testFile)
        file.exists() && file.readText().contains("test")
    } catch (e: Exception) {
        false
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermuxSettingsScreen() {
    var status by remember { mutableStateOf<TermuxConnectionStatus?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    fun refreshStatus() {
        isLoading = true
        coroutineScope.launch {
            status = getTermuxConnectionStatus(context)
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        refreshStatus()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Termux Connection") },
                actions = {
                    IconButton(onClick = { refreshStatus() }) {
                        Text("Refresh")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                isLoading || status == null -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                !status!!.termuxInstalled -> {
                    TermuxNotInstalledContent()
                }
                !status!!.termuxPermissionGranted -> {
                    PermissionNotGrantedContent()
                }
                !status!!.externalAppsEnabled -> {
                    ExternalAppsNotEnabledContent()
                }
                status!!.lute3Status != InstallationStatus.INSTALLED -> {
                    Lute3NotInstalledContent(
                        onInstallClick = { refreshStatus() }
                    )
                }
                else -> {
                    TermuxInstalledContent(
                        status = status!!,
                        onRefresh = { refreshStatus() }
                    )
                }
            }
        }
    }
}

@Composable
fun TermuxNotInstalledContent() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Termux is not installed",
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Termux is required to run the Lute3 server locally on your device.",
            style = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("https://f-droid.org/packages/com.termux/")
                }
            }
        ) {
            Text("Install Termux from F-Droid")
        }
    }
}

@Composable
fun PermissionNotGrantedContent() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Permission not granted",
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "LuteForMobile needs permission to run commands in Termux.",
            style = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = {
                val intent = android.content.Intent().apply {
                    action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    data = Uri.parse("package:com.schlick7.luteformobile")
                }
            }
        ) {
            Text("Grant Permission")
        }
    }
}

@Composable
fun ExternalAppsNotEnabledContent() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "External apps not enabled in Termux",
            style = MaterialTheme.typography.headlineSmall
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Termux needs to be configured to accept commands from other apps.",
            style = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.height(16.dp))
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text("Run this command in Termux:")
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = """echo "allow-external-apps=true" >> ~/.termux/termux.properties""",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "1. Open Termux app\n2. Run the command above\n3. Close Termux completely (swipe from recent apps)\n4. Reopen Termux",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = {
                val clipboard = android.content.ClipboardManager
                    .getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                val clip = android.content.ClipData.newPlainText(
                    "command",
                    """echo "allow-external-apps=true" >> ~/.termux/termux.properties"""
                )
                clipboard.setPrimaryClip(clip)
            }
        ) {
            Text("Copy Command")
        }
    }
}

@Composable
fun Lute3NotInstalledContent(
    onInstallClick: () -> Unit
) {
    var isInstalling by remember { mutableStateOf(false) }
    var installResult by remember { mutableStateOf<InstallationStep?>(null) }

    if (isInstalling) {
        InstallationProgressScreen { result ->
            installResult = result
            isInstalling = false
            onInstallClick()
        }
    } else {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (installResult == InstallationStep.FAILED) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Installation Failed",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "The Lute3 server could not be installed. Please try again or install manually in Termux.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            Text(
                text = "Lute3 is not installed",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Install Lute3 server to use local database connections.",
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = { isInstalling = true },
                enabled = !isInstalling
            ) {
                Text("Install Lute3")
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Installation may take 1-3 minutes",
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermuxInstalledContent(
    status: TermuxConnectionStatus,
    onRefresh: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Termux")
                    if (status.termuxVersion != null) {
                        Text(
                            text = status.termuxVersion,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Lute3")
                    if (status.lute3Version != null) {
                        Text(
                            text = status.lute3Version,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Server")
                    if (status.serverRunning) {
                        Text(
                            text = "Running",
                            color = Color.Green,
                            fontWeight = FontWeight.Bold
                        )
                    } else {
                        Text(
                            text = "Stopped",
                            color = Color.Red,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (status.serverRunning) {
                    Button(
                        onClick = {
                            stopLute3Server(context)
                            onRefresh()
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Stop Server")
                    }
                } else {
                    Button(
                        onClick = {
                            launchLute3ServerWithAutoShutdown(context)
                            onRefresh()
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Start Server")
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedButton(
                onClick = {
                    updateLute3(context)
                },
                modifier = Modifier.weight(1f)
            ) {
                Text("Update Lute3")
            }
            OutlinedButton(
                onClick = {
                    reinstallLute3(context)
                },
                modifier = Modifier.weight(1f)
            ) {
                Text("Reinstall")
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedButton(
            onClick = {
                coroutineScope.launch {
                    touchHeartbeat(context)
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Test Heartbeat")
        }
    }
}

fun updateLute3(context: Context) {
    val script = "pip install --upgrade lute3"
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun reinstallLute3(context: Context) {
    val script = "pip uninstall -y lute3 && pip install --upgrade lute3"
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

fun touchHeartbeat(context: Context) {
    val intent = Intent().apply {
        setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
        action = TermuxConstants.TERMUX_ACTION
        putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "-c", "touch ${TermuxConstants.HEARTBEAT_FILE}"
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

@Composable
fun InstallationProgressScreen(
    onComplete: (InstallationStep) -> Unit
) {
    var currentStep by remember { mutableStateOf(InstallationStep.SETUP_STORAGE) }
    var progress by remember { mutableFloatStateOf(0f) }
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    val totalEstimatedTime = TermuxConstants.SETUP_STORAGE_TIMEOUT +
            TermuxConstants.UPDATE_PACKAGES_TIMEOUT +
            TermuxConstants.UPGRADE_PACKAGES_TIMEOUT +
            TermuxConstants.INSTALL_PYTHON_TIMEOUT +
            TermuxConstants.INSTALL_LUTE3_TIMEOUT +
            5

    LaunchedEffect(Unit) {
        val result = installLute3ServerWithProgress(context) { step ->
            currentStep = step
            val elapsedTime = when (step) {
                InstallationStep.SETUP_STORAGE -> 0f
                InstallationStep.UPDATING_PACKAGES -> TermuxConstants.SETUP_STORAGE_TIMEOUT.toFloat()
                InstallationStep.UPGRADING_PACKAGES -> (TermuxConstants.SETUP_STORAGE_TIMEOUT + TermuxConstants.UPDATE_PACKAGES_TIMEOUT).toFloat()
                InstallationStep.INSTALLING_PYTHON -> (TermuxConstants.SETUP_STORAGE_TIMEOUT + TermuxConstants.UPDATE_PACKAGES_TIMEOUT + TermuxConstants.UPGRADE_PACKAGES_TIMEOUT).toFloat()
                InstallationStep.INSTALLING_LUTE3 -> (TermuxConstants.SETUP_STORAGE_TIMEOUT + TermuxConstants.UPDATE_PACKAGES_TIMEOUT + TermuxConstants.UPGRADE_PACKAGES_TIMEOUT + TermuxConstants.INSTALL_PYTHON_TIMEOUT).toFloat()
                InstallationStep.VERIFYING -> (TermuxConstants.SETUP_STORAGE_TIMEOUT + TermuxConstants.UPDATE_PACKAGES_TIMEOUT + TermuxConstants.UPGRADE_PACKAGES_TIMEOUT + TermuxConstants.INSTALL_PYTHON_TIMEOUT + TermuxConstants.INSTALL_LUTE3_TIMEOUT).toFloat()
                InstallationStep.COMPLETE -> totalEstimatedTime.toFloat()
                InstallationStep.FAILED -> totalEstimatedTime.toFloat()
            }
            progress = elapsedTime / totalEstimatedTime
        }
        onComplete(result)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Installing Lute3 Server",
            style = MaterialTheme.typography.headlineMedium
        )

        Spacer(modifier = Modifier.height(24.dp))

        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = currentStep.status,
            style = MaterialTheme.typography.titleMedium,
            color = if (currentStep == InstallationStep.FAILED) {
                MaterialTheme.colorScheme.error
            } else {
                MaterialTheme.colorScheme.primary
            }
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = when (currentStep) {
                InstallationStep.SETUP_STORAGE -> "Setting up storage permissions..."
                InstallationStep.UPDATING_PACKAGES -> "Updating package lists..."
                InstallationStep.UPGRADING_PACKAGES -> "Upgrading packages..."
                InstallationStep.INSTALLING_PYTHON -> "Installing Python3..."
                InstallationStep.INSTALLING_LUTE3 -> "Installing Lute3..."
                InstallationStep.VERIFYING -> "Verifying installation..."
                InstallationStep.COMPLETE -> "Installation complete!"
                InstallationStep.FAILED -> "Installation failed. Please try again or install manually."
            },
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Estimated time remaining: ~${totalEstimatedTime - (progress * totalEstimatedTime).toInt()} seconds",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermuxBackupSettingsScreen() {
    var backups by remember { mutableStateOf<List<LuteBackup>?>(null) }
    var isBackingUp by remember { mutableStateOf(false) }
    var backupMessage by remember { mutableStateOf<String?>(null) }
    var remoteUrl by remember { mutableStateOf("") }
    var apiKey by remember { mutableStateOf("") }

    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        backups = listBackups(context)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Database Backup & Sync") }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            Text(
                text = "Create Backup",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                onClick = {
                    isBackingUp = true
                    coroutineScope.launch {
                        val result = triggerLute3Backup(context, BackupType.MANUAL)
                        isBackingUp = false
                        backupMessage = when (result) {
                            is BackupResult.Success -> result.message
                            is BackupResult.Error -> "Error: ${result.message}"
                        }
                        backups = listBackups(context)
                    }
                },
                enabled = !isBackingUp,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (isBackingUp) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text("Create Backup")
            }

            if (backupMessage != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = backupMessage!!,
                    color = if (backupMessage!!.contains("Error")) Color.Red else Color.Green,
                    style = MaterialTheme.typography.bodySmall
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            if (backups != null) {
                Text(
                    text = "Available Backups",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))

                backups?.forEach { backup ->
                    BackupItem(
                        backup = backup,
                        onDownload = {
                            coroutineScope.launch {
                                val result = downloadBackup(context, backup.filename)
                                backupMessage = when (result) {
                                    is DownloadResult.Success -> "Downloaded: ${result.filePath}"
                                    is DownloadResult.Error -> "Error: ${result.message}"
                                }
                            }
                        },
                        onRestore = {
                            coroutineScope.launch {
                                val file = selectBackupFile(context)
                                if (file != null) {
                                    val result = restoreDatabaseFromDownloads(context, file)
                                    backupMessage = when (result) {
                                        is RestoreResult.Success -> result.message
                                        is RestoreResult.Error -> "Error: ${result.message}"
                                    }
                                } else {
                                    backupMessage = "No backup file found in Downloads"
                                }
                            }
                        }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Sync with Remote Server",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = remoteUrl,
                onValueChange = { remoteUrl = it },
                label = { Text("Remote Server URL") },
                placeholder = { Text("https://your-lute-server.com") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = apiKey,
                onValueChange = { apiKey = it },
                label = { Text("API Key (optional)") },
                placeholder = { Text("Your API key") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = {
                    coroutineScope.launch {
                        val result = syncWithRemoteServer(context, remoteUrl, apiKey.takeIf { it.isNotBlank() })
                        backupMessage = when (result) {
                            is SyncResult.Success -> result.message
                            is SyncResult.Error -> "Error: ${result.message}"
                        }
                    }
                },
                enabled = remoteUrl.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Upload Backup to Remote")
            }
        }
    }
}

@Composable
fun BackupItem(
    backup: LuteBackup,
    onDownload: () -> Unit,
    onRestore: () -> Unit
) {
    val dateFormat = java.text.SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())

    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = backup.filename,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = dateFormat.format(Date(backup.lastModified)),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                Text(
                    text = backup.size,
                    style = MaterialTheme.typography.bodySmall
                )
            }

            if (backup.isManual) {
                Spacer(modifier = Modifier.height(8.dp))
                Surface(
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = " Manual ",
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onDownload,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Download")
                }
                Button(
                    onClick = onRestore,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Restore")
                }
            }
        }
    }
}
