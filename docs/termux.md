termux integration for android. Is it possible?
- Detect installed Termux and auto install Lute3 Server
- launch server
- close server

---

# Termux Integration - Implementation Plan

## Research Summary: YES, this is possible!

Based on Termux's RUN_COMMAND Intent API (available since v0.95), we can integrate with Termux from an external Android app.

---

## Implementation Phases

### Phase 1: Prerequisites & Setup - ✅ IMPLEMENTED

**Status:** Complete

**Summary:**
- Added `com.termux.permission.RUN_COMMAND` permission to AndroidManifest.xml
- Added Termux package query for Android 11+ visibility
- Created `TermuxConstants.kt` with all configuration constants:
  - Termux paths, service info, and action strings
  - Lute3 configuration (port 5001, data paths)
  - Status tracking file paths (heartbeat, installation status, version files)
  - Command completion tracking constants
  - Timeout configurations (60-900 seconds for various operations)

**Files modified:**
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxConstants.kt` (new)

**User Setup Requirements (one-time):**
1. Install Termux app from F-Droid
2. Grant "Run commands in Termux environment" permission via:
   - Settings → Apps → LuteForMobile → Permissions → Additional Permissions
3. Enable external apps in Termux:
   ```bash
   echo "allow-external-apps=true" >> ~/.termux/termux.properties
   ```

---

### Phase 2: Detect Installed Termux & Server Status - ✅ IMPLEMENTED

**Status:** Complete

**Summary:**
- Created `TermuxStatus.kt` with status detection functions:
  - `CommandResult` sealed class (Success, Failed, Timeout)
  - `InstallationStatus` enum (INSTALLED, NOT_INSTALLED, UNKNOWN, ERROR)
  - `executeCommandWithCompletion()` - Execute commands with status file tracking and polling
  - `isTermuxInstalled()` - Check if Termux app is installed via PackageManager
  - `isTermuxPermissionGranted()` - Check RUN_COMMAND permission status
  - `isLute3ServerRunning()` - Check via Android running processes
  - `isLute3ServerRunningHttp()` - Check via HTTP request to localhost:5001
  - `isLute3Installed()` - Check if Lute3 is installed via pip

**Key Implementation Details:**
- Commands execute with status file tracking (writes SUCCESS/FAILED to status files)
- App polls for completion every 2 seconds up to configured timeout
- Uses OkHttp for HTTP requests to check server status
- Uses ActivityManager for process detection
- All blocking operations designed for IO dispatcher

**Files modified:**
- `android/app/build.gradle.kts` - Added OkHttp and coroutines dependencies
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxStatus.kt` (new)

---

### Phase 3: Settings UI - Check & Display Installation Status - ✅ IMPLEMENTED

**Status:** Complete

**Summary:**
- Created `TermuxSettings.kt` with comprehensive settings UI:
  - `TermuxConnectionStatus` data class aggregating all status information
  - `getTermuxConnectionStatus()` - Checks Termux install, permission, external apps, Lute3 install, server status
  - `getLute3Version()` - Retrieves Lute3 version via pip
  - `getTermuxVersion()` - Retrieves Termux version
  - `checkExternalAppsEnabled()` - Tests if external apps are enabled
- Created `TermuxServer.kt` with server control functions:
  - `launchLute3ServerWithAutoShutdown()` - Starts server with heartbeat monitoring
  - `stopLute3Server()` - Stops server and cleans up heartbeat file
  - `installLute3ServerWithProgress()` - Full Lute3 installation with step tracking
  - Individual installation step functions (setup storage, update, upgrade, install Python, install Lute3)
- Material 3 UI with responsive states:
  - Loading state with progress indicator
  - Termux not installed with F-Droid link
  - Permission not granted with settings link
  - External apps not enabled with copyable command
  - Lute3 not installed with install button
  - Full status dashboard when everything is configured
- Server status dashboard showing version info and running state
- Update/reinstall/heartbeat test buttons

**Files modified:**
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxSettings.kt` (new)
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxServer.kt` (new)

---

### Phase 4: Auto-Install Lute3 Server - ✅ IMPLEMENTED

**Status:** Complete

**Summary:**
- Created `InstallationStep` enum with all installation steps and estimated times
- Implemented individual Termux command functions:
  - `termuxSetupStorage()` - Grants storage permissions
  - `termuxUpdatePackages()` - Updates package lists
  - `termuxUpgradePackages()` - Upgrades installed packages
  - `termuxInstallPython3()` - Installs Python3
  - `termuxInstallLute3()` - Installs/upgrades Lute3
- Implemented `installLute3ServerWithProgress()` with step-by-step execution and status callbacks
- Created `InstallationProgressScreen` Composable with:
  - Real-time progress tracking across all installation steps
  - Visual progress bar showing completion percentage
  - Step-by-step status messages
  - Estimated time remaining display
  - Error handling with failure UI
  - Automatic server verification after installation

**Files modified:**
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxServer.kt`
- `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxSettings.kt`

**Installation Script:**
```kotlin
// Step 1: Setup storage permissions
fun termuxSetupStorage(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "termux-setup-storage"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

// Step 2: Update packages
fun termuxUpdatePackages(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg update -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

// Step 3: Upgrade packages
fun termuxUpgradePackages(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg upgrade -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

// Step 4: Install Python3
fun termuxInstallPython3(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkg install python3 -y"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}

// Step 5: Install Lute3
fun termuxInstallLute3(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pip install --upgrade lute3"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

**Installation Flow with Status Updates:**
```kotlin
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

suspend fun installLute3ServerWithProgress(
    context: Context,
    onStepChange: (InstallationStep) -> Unit
): InstallationStep {
    try {
        onStepChange(InstallationStep.SETUP_STORAGE)
        termuxSetupStorage(context)
        delay(3000)
        
        onStepChange(InstallationStep.UPDATING_PACKAGES)
        termuxUpdatePackages(context)
        delay(15000)
        
        onStepChange(InstallationStep.UPGRADING_PACKAGES)
        termuxUpgradePackages(context)
        delay(30000)
        
        onStepChange(InstallationStep.INSTALLING_PYTHON)
        termuxInstallPython3(context)
        delay(45000)
        
        onStepChange(InstallationStep.INSTALLING_LUTE3)
        termuxInstallLute3(context)
        delay(60000)
        
        onStepChange(InstallationStep.VERIFYING)
        delay(5000)
        
        if (isLute3ServerRunningHttp(5001)) {
            return InstallationStep.COMPLETE
        } else {
            return InstallationStep.FAILED
        }
    } catch (e: Exception) {
        return InstallationStep.FAILED
    }
}
```

**UI Integration Example:**
```kotlin
@Composable
fun InstallationProgressScreen() {
    var currentStep by remember { mutableStateOf(InstallationStep.SETUP_STORAGE) }
    var progress by remember { mutableFloatStateOf(0f) }
    
    val totalEstimatedTime = 158f // seconds (sum of all steps)
    var elapsedTime by remember { mutableFloatStateOf(0f) }
    
    LaunchedEffect(Unit) {
        currentStep = installLute3ServerWithProgress(context) { step ->
            currentStep = step
            progress = elapsedTime / totalEstimatedTime
        }
    }
    
    Column {
        Text("Installing Lute3 Server")
        LinearProgressIndicator(progress = progress)
        Text(currentStep.status)
        Text("Estimated time: ${currentStep.estimatedTimeSeconds}s")
    }
}
```

**Note on Installation Progress:**
- RUN_COMMAND intent does NOT provide real-time progress feedback
- Show generic "Installing Lute3 Server..." message to user
- Server will be ready ~1-3 minutes after command completes
- Use HTTP check to `localhost:5001` to verify installation success

---

### Phase 5: Launch Server with Auto-Shutdown (Heartbeat Method)

**How it works:**
1. Bash script starts Lute3 server in background
2. Script monitors a "heartbeat" file every 2 minutes
3. Your Flutter app touches heartbeat file on each API call
4. If no heartbeat for 30 minutes, script kills the server

**Flutter side - Touch heartbeat on API calls:**
```kotlin
fun touchHeartbeat(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/touch")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "/data/data/com.termux/files/home/.lute3/heartbeat"
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

**Launch server with monitoring script:**
```kotlin
fun launchLute3ServerWithAutoShutdown(
    context: Context, 
    port: Int = 5001,
    idleTimeoutMinutes: Int = 30
) {
    val script = """
        #!/data/data/com.termux/files/usr/bin/bash
        
        # Setup
        HEARTBEAT_FILE="/data/data/com.termux/files/home/.lute3/heartbeat"
        mkdir -p "$(dirname "$HEARTBEAT_FILE")"
        touch "$HEARTBEAT_FILE"  # Initial heartbeat
        
        # Start Lute3 server in background
        python -m lute.main --port $port &
        SERVER_PID=$!
        
        echo "Lute3 server started with PID $SERVER_PID on port $port"
        
        # Monitor loop - check every 2 minutes
        MAX_IDLE_MINUTES=$idleTimeoutMinutes
        CHECK_INTERVAL_SECONDS=120
        MAX_CHECKS=$((MAX_IDLE_MINUTES * 60 / CHECK_INTERVAL_SECONDS))
        IDLE_CHECKS=0
        
        while true; do
            sleep $CHECK_INTERVAL_SECONDS
            
            # Check if server is still running
            if ! ps -p $SERVER_PID > /dev/null 2>&1; then
                echo "Server stopped, exiting monitor"
                exit 0
            fi
            
            # Check heartbeat
            CURRENT_TIME=$(date +%s)
            HEARTBEAT_TIME=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo "0")
            TIME_DIFF=$(( (CURRENT_TIME - HEARTBEAT_TIME) / 60 ))
            
            if [ $TIME_DIFF -lt 2 ]; then
                IDLE_CHECKS=0
                echo "Heartbeat detected (${TIME_DIFF}m ago), idle counter reset"
            else
                IDLE_CHECKS=$((IDLE_CHECKS + 1))
                IDLE_MINUTES=$((IDLE_CHECKS * 2))
                echo "No heartbeat for ${IDLE_MINUTES} minutes (check $IDLE_CHECKS/$MAX_CHECKS)"
                
                if [ $IDLE_CHECKS -ge $MAX_CHECKS ]; then
                    echo "Idle timeout reached (${MAX_IDLE_MINUTES} min), stopping server..."
                    kill $SERVER_PID 2>/dev/null
                    rm -f "$HEARTBEAT_FILE"
                    exit 0
                fi
            fi
        done
    """.trimIndent()
    
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
    }
    context.startService(intent)
}
```

**Alternative: Check active network connections instead of heartbeat:**
```bash
# Instead of heartbeat file, check for active connections:
ACTIVE_CONNECTIONS=$(netstat -an 2>/dev/null | grep ':5001' | grep 'ESTABLISHED' | wc -l)
if [ "$ACTIVE_CONNECTIONS" -gt 0 ]; then
    IDLE_CHECKS=0
else
    IDLE_CHECKS=$((IDLE_CHECKS + 1))
fi
```

---

### Phase 6: Close Server

**Immediate stop:**
```kotlin
fun stopLute3Server(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/pkill")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-f", "python -m lute.main"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

**Also clean up heartbeat file:**
```kotlin
fun cleanupHeartbeat(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/rm")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "-f", "/data/data/com.termux/files/home/.lute3/heartbeat"
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

---

## Error Handling Strategies

### 1. Termux Not Installed
**Detection:** `isTermuxInstalled()` returns `false`

**Error Message:**
```
Termux is not installed on your device.
```

**User Setup Required:**
1. Open F-Droid app store
2. Search for "Termux"
3. Install the Termux app
4. Return to LuteForMobile to continue

**User Action:** Show "Install Termux" button that opens F-Droid URL

---

### 2. Permission Not Granted
**Detection:** `isTermuxPermissionGranted()` returns `false`

**Error Message:**
```
Termux permission not granted.
LuteForMobile needs permission to run commands in Termux.
```

**User Setup Required:**
1. Open Android Settings
2. Go to Apps
3. Find and tap "LuteForMobile"
4. Tap "Permissions"
5. Tap "Additional permissions"
6. Find "Run commands in Termux environment" and enable it

**User Action:** Show "Grant Permission" button that opens App Info settings screen

---

### 3. External Apps Not Enabled in Termux
**Detection:** RUN_COMMAND intent fails with permission error

**Error Message:**
```
External apps not enabled in Termux.
Termux needs to be configured to accept commands from other apps.
```

**User Setup Required:**
1. Open Termux app
2. Run this command:
   ```bash
   echo "allow-external-apps=true" >> ~/.termux/termux.properties
   ```
3. Close Termux completely (swipe it away from recent apps)
4. Reopen Termux

**User Action:** Show "Copy Command" button to copy the command, with instructions

---

### 4. Installation Failed
**Detection:** HTTP check to `localhost:5001` fails after 3 minutes OR any step fails

**Error Messages by Step:**
```
Setup failed: Storage permissions could not be granted.
Update failed: Package list update failed.
Upgrade failed: Package upgrade failed.
Python installation failed: Python3 could not be installed.
Lute3 installation failed: Lute3 could not be installed via pip.
Verification failed: Lute3 server is not responding.
```

**User Setup Required:**
**Troubleshooting Steps:**

1. **Check Termux internet connection:**
   - Open Termux
   - Run: `ping -c 3 github.com`
   - If ping fails, check your device's internet connection

2. **Manually install Lute3 Server:**
   - Open Termux
   - Run each command one by one:
     ```bash
     termux-setup-storage
     pkg update -y
     pkg upgrade -y
     pkg install python3 -y
     pip install --upgrade lute3
     ```
   - Check for any error messages during installation

3. **Verify Python installation:**
   - In Termux, run: `python --version`
   - Should show Python 3.x.x

4. **Common Issues:**
   - **"command not found: pkg"** → Run `apt update` first, then `apt install python3`
   - **"pip: command not found"** → Install pip: `apt install python-pip`
   - **"package not found"** → Check internet, try `pkg update` again
   - **"Permission denied"** → Run `termux-setup-storage` first

**User Action:** 
- Show which step failed with specific error message
- Show "Retry Failed Step" button (restarts from failed step)
- Show "Retry Full Installation" button
- Show "Open Termux" button

---

### 5. Server Failed to Start
**Detection:** `isLute3ServerRunning()` returns `false` 30 seconds after start command

**Error Message:**
```
Server failed to start.
The Lute3 server process could not be detected.
```

**User Setup Required:**
**Troubleshooting Steps:**

1. **Check if port 5001 is in use:**
   - In Termux, run: `netstat -an | grep :5001`
   - If you see output, another app is using this port
   - Solution: Use a different port in settings (try 5002, 8080, or 8000)

2. **Check if Lute3 is installed:**
   - In Termux, run: `pip show lute3`
   - If not found, run installation again (see Error #4)

3. **Check Python dependencies:**
   - In Termux, run: `pip list | grep lute3`
   - Should show `lute3` in the list

4. **Try manual start to see error:**
   - In Termux, run:
     ```bash
     python -m lute.main --port 5001
     ```
   - Look for error messages (database issues, missing files, etc.)

5. **Check Termux logs:**
   - Open Termux app
   - Look at the terminal output from the startup command
   - Errors will show here

**User Action:**
- Show error details from Termux logs
- Show "Try Different Port" dropdown (5001, 5002, 8080, 8000)
- Show "Retry Start" button
- Show "Open Termux" button

---

### 6. Server Crashed or Connection Lost
**Detection:** HTTP request fails during normal operation

**Error Message:**
```
Server connection lost.
The Lute3 server stopped responding.
```

**User Setup Required:**
**Automatic Recovery:**
- LuteForMobile will attempt to restart the server automatically
- This may take 10-30 seconds

**Manual Recovery (if automatic fails):**
1. Check Termux app to see crash messages
2. Run `ps | grep "python -m lute.main"` to see if process is running
3. If not running, start server manually in Termux:
   ```bash
   python -m lute.main --port 5001
   ```

4. If it crashes immediately, check:
   - Available storage space (Termux may be full)
   - Database corruption (delete `~/.local/share/lute3/lute.db` and let Lute3 recreate it)
   - Python version compatibility

**User Action:**
- Show "Restarting server..." status
- Auto-retry server startup
- If still failing after 3 attempts, show manual recovery steps
**User Action:** Auto-restart server, notify user

---

## Key Implementation Notes

### How the Heartbeat Works:
1. **App makes API call** → Call `touchHeartbeat()` via RUN_COMMAND intent
2. **Script checks every 2 min** → Compares current time vs heartbeat file modification time
3. **30 min idle** → Script kills server process and exits

### Server Status Detection Strategy:
**Primary Method (Option B):**
- Check Android running processes for Termux + Python
- Most reliable, works even if server isn't responding
- Requires `GET_TASKS` or `GET_RUNNING_PROCESSES` permission

**Fallback Method (Option A):**
- HTTP HEAD request to `localhost:5001`
- Works if server is responsive
- Use as backup when process check fails

### Installation Progress Display:
**Reality:** RUN_COMMAND intent provides NO real-time feedback
**Approach:** Show generic message: "Installing Lute3 Server..."
**Verification:** After 60 seconds, try HTTP check to `localhost:5001`
**If success:** Show "Installation complete!"
**If failure after 3 minutes:** Show error, suggest manual installation in Termux

### Limitations:
1. **User must manually enable `allow-external-apps`** - Cannot be done programmatically
2. **User must manually grant permission** - Can guide via Settings UI
3. **Background execution** - Server runs in Termux background session
4. **No process feedback** - Termux doesn't report back if command succeeded
5. **Installation time** - May take 1-3 minutes, no progress indication

### User Flow:
1. **First Launch:** Check Termux install → Check permission → Show setup instructions
2. **Install Server:** User taps install → App sends RUN_COMMAND with pkg/pip commands → Show generic "Installing..." → Verify via HTTP
3. **Launch Server:** User taps start → App sends RUN_COMMAND with monitoring script → Verify server running → Auto-heartbeat on API calls
4. **Auto-shutdown:** Script monitors heartbeat, kills server after 30min idle
5. **Manual Stop:** User taps stop → App sends pkill command → Cleanup heartbeat file

### Heartbeat Timing:
- **Script checks:** Every 2 minutes
- **App touches:** On every API call (realistic: multiple times per minute while reading)
- **Result:** Server stays active as long as user is using app
- **Auto-shutdown:** After 30 minutes of no API calls = user not using app

---

---

## Phase 7: Database Backup, Restore & File Sync

### Lute3 Backup API Overview

Lute3 provides a built-in backup system accessible via HTTP API:
- **Backup endpoint:** `POST /backup/do_backup`
- **Backup list:** `GET /backup/index`
- **Download backup:** `GET /backup/download/<filename>`
- **Backup format:** Gzipped SQLite database (`lute_backup_YYYY-MM-DD_HHMMSS.db.gz`) + image folder (`userimages_backup/`)

---

### Backup Database to Termux

**Trigger Lute3 backup via HTTP API:**
```kotlin
suspend fun triggerLute3Backup(
    context: Context,
    port: Int = 5001,
    backupType: BackupType = BackupType.MANUAL
): BackupResult {
    return try {
        val client = OkHttpClient()
        val formBody = FormBody.Builder()
            .add("type", backupType.value)
            .build()
        
        val request = Request.Builder()
            .url("http://localhost:$port/backup/do_backup")
            .post(formBody)
            .build()
        
        val response = client.newCall(request).execute()
        
        if (response.isSuccessful) {
            val responseBody = response.body?.string()
            BackupResult.Success(responseBody ?: "Backup created successfully")
        } else {
            BackupResult.Error("Backup failed: ${response.code}")
        }
    } catch (e: Exception) {
        BackupResult.Error(e.message ?: "Unknown backup error")
    }
}

enum class BackupType(val value: String) {
    MANUAL("manual"),
    AUTOMATIC("automatic")
}

sealed class BackupResult {
    data class Success(val message: String) : BackupResult()
    data class Error(val message: String) : BackupResult()
}
```

---

### List Available Backups

**Fetch list of backups from Lute3:**
```kotlin
suspend fun listBackups(
    context: Context,
    port: Int = 5001
): List<LuteBackup>? {
    return try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port/backup/index")
            .build()
        
        val response = client.newCall(request).execute()
        
        if (response.isSuccessful) {
            // Parse HTML response or use JSON if available
            val html = response.body?.string() ?: return null
            parseBackupListFromHtml(html)
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }
}

data class LuteBackup(
    val filename: String,
    val lastModified: Long,
    val size: String,
    val isManual: Boolean
)
```

---

### Download Backup to Android Downloads

**Download backup file via Lute3 API to local storage:**
```kotlin
suspend fun downloadBackup(
    context: Context,
    filename: String,
    port: Int = 5001
): DownloadResult {
    return try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port/backup/download/$filename")
            .build()
        
        val response = client.newCall(request).execute()
        
        if (response.isSuccessful) {
            val inputStream = response.body?.byteStream()
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val outputFile = File(downloadsDir, filename)
            
            inputStream?.use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }
            
            DownloadResult.Success(outputFile.absolutePath)
        } else {
            DownloadResult.Error("Download failed: ${response.code}")
        }
    } catch (e: Exception) {
        DownloadResult.Error(e.message ?: "Unknown download error")
    }
}

sealed class DownloadResult {
    data class Success(val filePath: String) : DownloadResult()
    data class Error(val message: String) : DownloadResult()
}
```

---

### Restore Database from Downloads Folder

**Two-step restore process:**

**Step 1: Select backup file from Downloads:**
```kotlin
suspend fun selectBackupFile(context: Context): File? {
    return try {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        val backups = downloadsDir.listFiles { file ->
            file.name.matches(Regex("(manual_)?lute_backup_.*\\.db(\\.gz)?"))
        }?.sortedByDescending { it.lastModified() }
        
        if (backups.isNullOrEmpty()) null else backups?.first()
    } catch (e: Exception) {
        null
    }
}
```

**Step 2: Copy to Termux and restore:**
```kotlin
suspend fun restoreDatabaseFromDownloads(
    context: Context,
    backupFile: File
): RestoreResult {
    val dataPath = "/data/data/com.termux/files/home/.local/share/lute3"
    val dbPath = "$dataPath/lute.db"
    val backupPath = "$dataPath/${backupFile.name}"
    
    return try {
        // Stop Lute3 server first
        stopLute3Server(context)
        delay(2000)
        
        // Copy backup file to Termux data directory
        val copyScript = """
            cp '$backupFile' '$backupPath'
        """.trimIndent()
        
        val copyIntent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", copyScript))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(copyIntent)
        delay(3000)
        
        // Decompress if gzipped
        if (backupFile.name.endsWith(".gz")) {
            val decompressScript = """
                cd '$dataPath'
                gunzip -f '${backupFile.name}'
                mv '${backupFile.name.removeSuffix(".gz")}' lute.db
            """.trimIndent()
            
            val decompressIntent = Intent().apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                action = "com.termux.RUN_COMMAND"
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", decompressScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }
            context.startService(decompressIntent)
            delay(5000)
        } else {
            // Rename backup to lute.db
            val renameScript = """
                cd '$dataPath'
                mv '${backupFile.name}' lute.db
            """.trimIndent()
            
            val renameIntent = Intent().apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                action = "com.termux.RUN_COMMAND"
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", renameScript))
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            }
            context.startService(renameIntent)
            delay(3000)
        }
        
        // Start Lute3 server
        launchLute3ServerWithAutoShutdown(context)
        delay(5000)
        
        // Verify restore
        if (isLute3ServerRunningHttp(5001)) {
            RestoreResult.Success("Database restored successfully")
        } else {
            RestoreResult.Error("Server failed to start after restore")
        }
    } catch (e: Exception) {
        RestoreResult.Error(e.message ?: "Unknown restore error")
    }
}

sealed class RestoreResult {
    data class Success(val message: String) : RestoreResult()
    data class Error(val message: String) : RestoreResult()
}
```

---

### Sync with Other Servers

**Backup workflow for syncing across devices:**

```kotlin
suspend fun syncWithRemoteServer(
    context: Context,
    remoteUrl: String,  // URL of remote Lute3 instance
    apiKey: String? = null
): SyncResult {
    // Step 1: Create local backup
    val backupResult = triggerLute3Backup(context, BackupType.MANUAL)
    if (backupResult !is BackupResult.Success) {
        return SyncResult.Error("Failed to create backup: ${backupResult.message}")
    }
    
    // Step 2: Download backup file
    val backups = listBackups(context)
    if (backups.isNullOrEmpty()) {
        return SyncResult.Error("No backups found")
    }
    
    val latestBackup = backups.maxByOrNull { it.lastModified }
        ?: return SyncResult.Error("No valid backup found")
    
    val downloadResult = downloadBackup(context, latestBackup.filename)
    if (downloadResult !is DownloadResult.Success) {
        return SyncResult.Error("Failed to download backup: ${downloadResult.message}")
    }
    
    // Step 3: Upload to remote server (via HTTP API)
    return try {
        val client = OkHttpClient()
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("backup", latestBackup.filename,
                File(downloadResult.filePath).asRequestBody("application/gzip".toMediaType()))
            .build()
        
        val requestBuilder = Request.Builder()
            .url("$remoteUrl/backup/upload")  // Custom endpoint on remote server
            .post(requestBody)
        
        if (apiKey != null) {
            requestBuilder.addHeader("Authorization", "Bearer $apiKey")
        }
        
        val response = client.newCall(requestBuilder.build()).execute()
        
        if (response.isSuccessful) {
            SyncResult.Success("Backup synced to remote server")
        } else {
            SyncResult.Error("Upload failed: ${response.code}")
        }
    } catch (e: Exception) {
        SyncResult.Error(e.message ?: "Sync failed")
    }
}

sealed class SyncResult {
    data class Success(val message: String) : SyncResult()
    data class Error(val message: String) : SyncResult()
}

fun String.toMediaType(): okhttp3.MediaType = MediaType.parse(this) ?: "application/octet-stream".toMediaType()
```

---

### Settings UI for Backup & Sync

**Add backup/sync section to Termux settings:**
```kotlin
@Composable
fun TermuxBackupSettingsScreen() {
    var backups by remember { mutableStateOf<List<LuteBackup>?>(null) }
    var isBackingUp by remember { mutableStateOf(false) }
    var backupMessage by remember { mutableStateOf<String?>(null) }
    
    LaunchedEffect(Unit) {
        backups = listBackups(context)
    }
    
    Column {
        Text("Database Backup & Sync", style = MaterialTheme.typography.h5)
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Backup section
        Text("Create Backup")
        Button(
            onClick = {
                isBackingUp = true
                CoroutineScope(Dispatchers.IO).launch {
                    val result = triggerLute3Backup(context, BackupType.MANUAL)
                    isBackingUp = false
                    backupMessage = when (result) {
                        is BackupResult.Success -> result.message
                        is BackupResult.Error -> "Error: ${result.message}"
                    }
                    backups = listBackups(context)
                }
            },
            enabled = !isBackingUp
        ) {
            if (isBackingUp) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text("Create Backup")
        }
        
        if (backupMessage != null) {
            Text(
                backupMessage!!,
                color = if (backupMessage!!.contains("Error")) Color.Red else Color.Green
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Backup list
        if (backups != null) {
            Text("Available Backups")
            LazyColumn {
                items(backups) { backup ->
                    BackupItem(
                        backup = backup,
                        onDownload = {
                            CoroutineScope(Dispatchers.IO).launch {
                                val result = downloadBackup(context, backup.filename)
                                backupMessage = when (result) {
                                    is DownloadResult.Success -> "Downloaded: ${result.filePath}"
                                    is DownloadResult.Error -> "Error: ${result.message}"
                                }
                            }
                        },
                        onRestore = {
                            CoroutineScope(Dispatchers.IO).launch {
                                val file = selectBackupFile(context)
                                if (file != null) {
                                    val result = restoreDatabaseFromDownloads(context, file)
                                    backupMessage = when (result) {
                                        is RestoreResult.Success -> result.message
                                        is RestoreResult.Error -> "Error: ${result.message}"
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Sync section
        Text("Sync with Remote Server")
        OutlinedTextField(
            value = remoteUrl,
            onValueChange = { remoteUrl = it },
            label = { Text("Remote Server URL") },
            placeholder = { Text("https://your-lute-server.com") }
        )
        
        OutlinedTextField(
            value = apiKey,
            onValueChange = { apiKey = it },
            label = { Text("API Key (optional)") },
            placeholder = { Text("Your API key") }
        )
        
        Button(
            onClick = {
                CoroutineScope(Dispatchers.IO).launch {
                    val result = syncWithRemoteServer(context, remoteUrl, apiKey)
                    backupMessage = when (result) {
                        is SyncResult.Success -> result.message
                        is SyncResult.Error -> "Error: ${result.message}"
                    }
                }
            }
        ) {
            Text("Upload Backup to Remote")
        }
    }
}

@Composable
fun BackupItem(
    backup: LuteBackup,
    onDownload: () -> Unit,
    onRestore: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth().padding(8.dp)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        backup.filename,
                        style = MaterialTheme.typography.subtitle1
                    )
                    Text(
                        "${SimpleDateFormat("MMM dd, yyyy HH:mm").format(Date(backup.lastModified))}",
                        style = MaterialTheme.typography.caption
                    )
                }
                Text(backup.size, style = MaterialTheme.typography.caption)
            }
            
            if (backup.isManual) {
                Surface(
                    color = MaterialTheme.colors.primary.copy(alpha = 0.1f),
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        " Manual ",
                        style = MaterialTheme.typography.caption,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row {
                Button(
                    onClick = onDownload,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Download")
                }
                Spacer(modifier = Modifier.width(8.dp))
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
```

---

### Error Handling for Backup/Restore

**Common issues and solutions:**

```kotlin
// Check storage permissions before backup/restore
suspend fun checkStoragePermissions(context: Context): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        Environment.isExternalStorageManager()
    } else {
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }
}

// Verify backup integrity
suspend fun verifyBackup(backupFile: File): Boolean {
    return try {
        val db = SQLiteDatabase.openDatabase(
            backupFile.absolutePath,
            null,
            SQLiteDatabase.OPEN_READONLY
        )
        val count = DatabaseUtils.queryNumEntries(db, "words", null)
        db.close()
        count > 0
    } catch (e: Exception) {
        false
    }
}

// Handle large database backups
suspend fun handleLargeBackup(backupFile: File, maxFileSize: Long = 100 * 1024 * 1024): Boolean {
    return backupFile.length() < maxFileSize
}
```

---

## References

- [Termux RUN_COMMAND Intent Wiki](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent)
- [Lute3 Backup Documentation](https://luteorg.github.io/lute-manual/backup/backup.html)
- [Lute3 Restore Documentation](https://luteorg.github.io/lute-manual/backup/restore.html)
- Package name: `com.termux`
- Service: `com.termux.app.RunCommandService`
- Action: `com.termux.RUN_COMMAND`
- Required permission: `com.termux.permission.RUN_COMMAND`
