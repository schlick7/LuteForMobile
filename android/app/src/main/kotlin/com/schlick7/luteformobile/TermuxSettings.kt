package com.schlick7.luteformobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

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

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
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
            onClick = {
                isInstalling = true
                coroutineScope.launch {
                    installLute3ServerWithProgress(
                        onStepChange = { step ->
                            // Handle step changes if needed
                        }
                    )
                    isInstalling = false
                    onInstallClick()
                }
            },
            enabled = !isInstalling
        ) {
            if (isInstalling) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    color = MaterialTheme.colorScheme.onPrimary
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text("Install Lute3")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Installation may take 1-3 minutes",
            style = MaterialTheme.typography.bodySmall
        )
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
