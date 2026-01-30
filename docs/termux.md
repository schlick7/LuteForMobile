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

### Phase 1: Prerequisites & Setup

**AndroidManifest.xml requirements:**
```xml
<uses-permission android:name="com.termux.permission.RUN_COMMAND" />

<!-- For Android 11+ package visibility -->
<queries>
    <package android:name="com.termux" />
</queries>
```

**User Setup Requirements (one-time):**
1. Install Termux app from F-Droid
2. Grant "Run commands in Termux environment" permission via:
   - Settings → Apps → LuteForMobile → Permissions → Additional Permissions
3. Enable external apps in Termux:
   ```bash
   echo "allow-external-apps=true" >> ~/.termux/termux.properties
   ```

---

### Phase 2: Detect Installed Termux & Server Status

```kotlin
fun isTermuxInstalled(context: Context): Boolean {
    return try {
        context.packageManager.getApplicationInfo("com.termux", 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}

fun isTermuxPermissionGranted(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(
        context, 
        "com.termux.permission.RUN_COMMAND"
    ) == PackageManager.PERMISSION_GRANTED
}

// Method 1: Check Termux process via Android (Preferred)
fun isLute3ServerRunning(context: Context): Boolean {
    return try {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningProcesses = activityManager.runningAppProcesses
        
        runningProcesses?.any { process ->
            process.processName.contains("com.termux") && 
            process.processName.contains("python")  // lute3 is Python
        } ?: false
    } catch (e: Exception) {
        false
    }
}

// Method 2: Fallback - HTTP request to localhost
suspend fun isLute3ServerRunningHttp(port: Int = 5001): Boolean {
    return try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("http://localhost:$port")
            .head()
            .build()
        val response = client.newCall(request).execute()
        response.isSuccessful
    } catch (e: Exception) {
        false
    }
}

// Method 3: Check if Lute3 is installed (without starting server)
suspend fun isLute3Installed(context: Context): InstallationStatus {
    val checkFile = "/data/data/com.termux/files/home/.lute3/installation_status.txt"
    
    return try {
        val script = """
            if pip show lute3 > /dev/null 2>&1; then
                echo "INSTALLED" > $checkFile
                pip show lute3 >> $checkFile
            else
                echo "NOT_INSTALLED" > $checkFile
            fi
        """.trimIndent()
        
        val intent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        context.startService(intent)
        
        delay(3000)
        
        val file = File(checkFile)
        if (!file.exists()) {
            return InstallationStatus.UNKNOWN
        }
        
        val content = file.readText()
        when {
            content.contains("INSTALLED") -> InstallationStatus.INSTALLED
            content.contains("NOT_INSTALLED") -> InstallationStatus.NOT_INSTALLED
            else -> InstallationStatus.UNKNOWN
        }
    } catch (e: Exception) {
        InstallationStatus.ERROR
    }
}

enum class InstallationStatus {
    INSTALLED,
    NOT_INSTALLED,
    UNKNOWN,
    ERROR
}
```

**Note**: RUN_COMMAND intent does NOT provide output or return codes. The shared file approach is the most reliable way to get installation status.

---

### Phase 3: Auto-Install Lute3 Server

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

### Phase 4: Launch Server with Auto-Shutdown (Heartbeat Method)

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

### Phase 5: Close Server

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

## References

- [Termux RUN_COMMAND Intent Wiki](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent)
- Package name: `com.termux`
- Service: `com.termux.app.RunCommandService`
- Action: `com.termux.RUN_COMMAND`
- Required permission: `com.termux.permission.RUN_COMMAND`
