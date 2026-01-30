termux integration for android. Is it possible?
- Detect installed Termux and auto install Lutev3 Server
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

### Phase 2: Detect Installed Termux

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
```

---

### Phase 3: Auto-Install Lutev3 Server

**Installation Script:**
```kotlin
fun installLuteV3Server(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", """
            pkg update -y && 
            pkg install python -y && 
            pip install lutev3-server
        """.trimIndent()))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

---

### Phase 4: Launch Server

```kotlin
fun launchLuteV3Server(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/lutev3-server")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("--port", "8080"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
    }
    context.startService(intent)
}
```

---

### Phase 5: Close Server

**Option A: Immediate Stop**
```kotlin
fun stopLuteV3Server(context: Context) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/pkill")
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-f", "lutev3-server"))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

**Option B: Auto-Shutdown with Inactivity Timeout (30 min)**

*Approach: Monitor server activity and auto-kill after idle period*

```kotlin
class LuteV3ServerManager(private val context: Context) {
    private var lastActivityTime = System.currentTimeMillis()
    private var isServerRunning = false
    private val timeoutMillis = 30 * 60 * 1000L // 30 minutes
    private val handler = Handler(Looper.getMainLooper())
    
    private val inactivityChecker = object : Runnable {
        override fun run() {
            if (isServerRunning) {
                val idleTime = System.currentTimeMillis() - lastActivityTime
                if (idleTime >= timeoutMillis) {
                    stopLuteV3Server()
                    isServerRunning = false
                    // Notify user that server auto-stopped due to inactivity
                } else {
                    // Check again in 1 minute
                    handler.postDelayed(this, 60 * 1000L)
                }
            }
        }
    }
    
    fun onServerActivity() {
        lastActivityTime = System.currentTimeMillis()
    }
    
    fun startServerWithTimeout() {
        launchLuteV3Server(context)
        isServerRunning = true
        lastActivityTime = System.currentTimeMillis()
        handler.postDelayed(inactivityChecker, 60 * 1000L) // Start checking after 1 min
    }
    
    fun stopServer() {
        stopLuteV3Server(context)
        isServerRunning = false
        handler.removeCallbacks(inactivityChecker)
    }
}
```

**Option C: Server-Side Auto-Shutdown (if LuteV3 supports it)**

*Check if LuteV3 server has built-in idle timeout flag:*

```kotlin
fun launchLuteV3ServerWithIdleTimeout(context: Context, idleTimeoutMinutes: Int = 30) {
    val intent = Intent().apply {
        setClassName("com.termux", "com.termux.app.RunCommandService")
        action = "com.termux.RUN_COMMAND"
        putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/lutev3-server")
        // Check if LuteV3 supports --idle-timeout or similar flag
        putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(
            "--port", "8080",
            "--idle-timeout", "${idleTimeoutMinutes}m"  // Hypothetical flag
        ))
        putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
    }
    context.startService(intent)
}
```

**Option D: Wrapper Script for Auto-Shutdown**

*If LuteV3 doesn't support idle timeout natively, create a monitoring script:*

```kotlin
fun launchServerWithAutoShutdownWrapper(context: Context) {
    val script = """
        #!/data/data/com.termux/files/usr/bin/bash
        
        # Start LuteV3 server in background
        lutev3-server --port 8080 &
        SERVER_PID=$!
        
        # Monitor for activity (check every minute)
        IDLE_TIME=0
        TIMEOUT=1800  # 30 minutes in seconds
        
        while true; do
            sleep 60
            
            # Check if server is still running
            if ! ps -p $SERVER_PID > /dev/null 2>&1; then
                echo "Server stopped"
                exit 0
            fi
            
            # Check for recent activity (modify based on how LuteV3 logs activity)
            # This is a placeholder - actual implementation depends on LuteV3's logging
            RECENT_ACTIVITY=$(find /data/data/com.termux/files/home/.lutev3 -name "*.log" -mtime -0.02 2>/dev/null | wc -l)
            
            if [ "$RECENT_ACTIVITY" -gt 0 ]; then
                IDLE_TIME=0
                echo "Activity detected, resetting timer"
            else
                IDLE_TIME=$((IDLE_TIME + 60))
                echo "No activity for $IDLE_TIME seconds"
                
                if [ $IDLE_TIME -ge $TIMEOUT ]; then
                    echo "Idle timeout reached (30 min), stopping server..."
                    kill $SERVER_PID
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
    }
    context.startService(intent)
}
```

---

## Key Implementation Notes

### Limitations:
1. **User must manually enable `allow-external-apps`** - Cannot be done programmatically
2. **User must manually grant permission** - Though this can be guided via Settings UI
3. **Background execution** - Server runs in Termux background session

### Error Handling:
- Check if Termux is installed before attempting commands
- Handle SecurityException if permission not granted
- Monitor server status via process checks

### Alternative: Using termux-shared Library
```gradle
dependencies {
    implementation 'com.github.termux:termux-app:termux-shared:master-SNAPSHOT'
}
```

This provides constants like `TermuxConstants.TERMUX_PACKAGE_NAME` instead of hardcoded strings.

---

## User Flow

1. **First Launch:**
   - Check if Termux installed → Prompt to install if not
   - Check if permission granted → Open Settings if not
   - Show instructions for `allow-external-apps`

2. **Install Server:**
   - User taps "Install Server"
   - App sends RUN_COMMAND intent to install dependencies
   - Show progress/status

3. **Launch Server:**
   - User taps "Start Server"
   - App sends RUN_COMMAND intent
   - Server starts in Termux background

4. **Stop Server:**
   - User taps "Stop Server" 
   - App sends kill command via RUN_COMMAND

---

## References

- [Termux RUN_COMMAND Intent Wiki](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent)
- Package name: `com.termux`
- Service: `com.termux.app.RunCommandService`
- Action: `com.termux.RUN_COMMAND`
- Required permission: `com.termux.permission.RUN_COMMAND`

