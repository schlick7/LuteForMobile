# Lute3 Tmux Installation Plan

## Overview

Replace current fire-and-forget Termux command execution with a persistent tmux session approach. This provides:
- Single bash process for all operations
- Better process control and error handling
- User visibility into installation progress
- Reliable state preservation between commands

## Core Design

**Session Name:** `lute_session`
**Lifecycle:** Created on first use, closed when installation completes
**User Access:** Can attach via `tmux attach -t lute_session` in Termux app
**Progress:** Step-based tracking (1/5, 2/5, etc.) with file markers
**Logs:** Captured to Downloads directory for debugging
**Concurrency:** Lock file prevents multiple simultaneous installations

## Implementation Components

### 1. TmuxHelper.kt (New File)

Session management utilities:

```kotlin
object TmuxHelper {
    const val SESSION_NAME = "lute_session"
    const val LOCK_FILE = "lute_install.lock"

    fun sessionExists(): Boolean
    fun isSessionHealthy(): Boolean
    fun ensureSession(): Boolean
    fun sendCommand(command: String): Boolean
    fun cleanupOrphans(): Boolean
    fun killSession(): Boolean
    fun getAttachInstructions(): String
    fun isInstallInProgress(): Boolean
    fun createInstallLock(): Boolean
    fun clearInstallLock(): Boolean
}
```

### 2. Installation Steps

5-step installation process:
1. `pkg update -y` (Update package lists)
2. `pkg upgrade -y` (Upgrade packages)
3. `pkg install python3 -y` (Install Python)
4. `pip install --upgrade pip` (Update pip)
5. `pip install --upgrade lute3` (Install Lute3)

Each step:
- Updates status file with `STEP:N/5`
- Logs output to separate file in Downloads
- Stops immediately on error (`set -e`)
- Writes final status (COMPLETE/FAILED)

### 3. Progress Tracking

**Status File:** `$DOWNLOADS_DIR/lute_install_status.txt`

**Format:**
```
STEP:1/5          - Running pkg update
STEP:2/5          - Running pkg upgrade
STEP:3/5          - Running pkg install python3
STEP:4/5          - Running pip install --upgrade pip
STEP:5/5          - Running pip install --upgrade lute3
STEP:COMPLETE        - Installation finished successfully
STEP:FAILED:<reason>  - Installation failed, see error
```

**Polling:**
- Check status file every 5 seconds
- Maximum wait time: 30 minutes
- Notify UI of step changes
- Stop on COMPLETE, FAILED, or TIMEOUT

### 4. Log Files

All logs stored in Downloads directory:
- `lute_pkg_update.log` - pkg update output
- `lute_pkg_upgrade.log` - pkg upgrade output
- `lute_python_install.log` - python3 install output
- `lute_pip_upgrade.log` - pip upgrade output
- `lute_lute3_install.log` - lute3 install output

**Cleanup:**
- Delete all logs on new installation start
- Keep only current operation's logs
- No log rotation needed

### 5. Error Handling

**Lock File:**
`$DOWNLOADS_DIR/lute_install.lock`
- Created before installation starts
- Deleted after installation completes/fails
- Prevents concurrent installations

**Error Detection:**
- Script uses `set -e` to stop on first error
- Error writes `STEP:FAILED:<step_name>` to status file
- UI displays which step failed
- Logs contain full error output

**Recovery:**
1. User runs `dpkg --configure -a` in Termux (if dpkg corrupted)
2. User clears lock file if needed
3. Retry installation from beginning

### 6. Command Flow

```
App checks lock file
  ├─ If locked: Show "Installation in progress" error
  └─ If not locked:
      ├─ Create lock file
      ├─ Cleanup orphaned processes (pkill -f 'apt|dpkg')
      ├─ Ensure tmux session exists (create if needed)
      ├─ Delete old log files
      ├─ Send installation script to session
      └─ Poll status file for completion (30 min timeout)
          ├─ Update UI with step progress
          └─ On COMPLETE:
              ├─ Clear lock file
              ├─ Kill tmux session
              └─ Show success message
          └─ On FAILED:
              ├─ Clear lock file
              ├─ Kill tmux session
              └─ Show error with failed step
```

### 7. Installation Script

```bash
#!/data/data/com.termux/files/usr/bin/bash

set -e  # Stop on any error

DOWNLOADS_DIR="/sdcard/Download"
STATUS_FILE="$DOWNLOADS_DIR/lute_install_status.txt"

# Clear old status
echo "STEP:1/5" > $STATUS_FILE

# Step 1: Update package lists
echo "Starting: pkg update" > $DOWNLOADS_DIR/lute_pkg_update.log
pkg update -y 2>&1 | tee -a $DOWNLOADS_DIR/lute_pkg_update.log
echo "Completed: pkg update" >> $DOWNLOADS_DIR/lute_pkg_update.log
echo "STEP:2/5" > $STATUS_FILE

# Step 2: Upgrade packages
echo "Starting: pkg upgrade" > $DOWNLOADS_DIR/lute_pkg_upgrade.log
pkg upgrade -y 2>&1 | tee -a $DOWNLOADS_DIR/lute_pkg_upgrade.log
echo "Completed: pkg upgrade" >> $DOWNLOADS_DIR/lute_pkg_upgrade.log
echo "STEP:3/5" > $STATUS_FILE

# Step 3: Install Python3
echo "Starting: pkg install python3" > $DOWNLOADS_DIR/lute_python_install.log
pkg install python3 -y 2>&1 | tee -a $DOWNLOADS_DIR/lute_python_install.log
echo "Completed: pkg install python3" >> $DOWNLOADS_DIR/lute_python_install.log
echo "STEP:4/5" > $STATUS_FILE

# Step 4: Upgrade pip
echo "Starting: pip install --upgrade pip" > $DOWNLOADS_DIR/lute_pip_upgrade.log
pip install --upgrade pip 2>&1 | tee -a $DOWNLOADS_DIR/lute_pip_upgrade.log
echo "Completed: pip install --upgrade pip" >> $DOWNLOADS_DIR/lute_pip_upgrade.log
echo "STEP:5/5" > $STATUS_FILE

# Step 5: Install Lute3
echo "Starting: pip install --upgrade lute3" > $DOWNLOADS_DIR/lute_lute3_install.log
pip install --upgrade lute3 2>&1 | tee -a $DOWNLOADS_DIR/lute_lute3_install.log
echo "Completed: pip install --upgrade lute3" >> $DOWNLOADS_DIR/lute_lute3_install.log

# Complete
echo "STEP:COMPLETE" > $STATUS_FILE
exit 0
```

### 8. UI Updates

**Termux Settings Screen:**
- Current step display: "Step 2/5: Upgrading packages..."
- Progress indicator (optional): Progress bar advancing per step
- Error message: "Installation failed at step 2: pkg upgrade"
- Lock error: "Installation already in progress. Try again later."
- View logs button: Shows current operation's log file

**New Button:** "Attach to tmux session"
- Opens instructions on how to view live output
- Shows: `tmux attach -t lute_session`

### 9. File Structure

**New Files:**
```
android/app/src/main/kotlin/com/schlick7/luteformobile/
├── TmuxHelper.kt                    # Session management
├── TermuxInstallTmux.kt            # Installation logic
└── TermuxConstants.kt               # Add lock file constant
```

**Modified Files:**
```
android/app/src/main/kotlin/com/schlick7/luteformobile/
└── TermuxBridge.kt                  # Add installLute3Tmux handler

lib/core/services/
└── termux_service.dart               # Add installLute3Tmux() method

lib/features/settings/widgets/
└── termux_screen.dart              # Add tmux attach button
```

### 10. Method Channel Handlers

**Dart → Kotlin:**

`installLute3Tmux`
- Starts tmux-based installation
- Returns: "COMPLETE", "FAILED:<reason>", "TIMEOUT"

`getTmuxStatus`
- Returns: "RUNNING", "IDLE", "NOT_FOUND"

`attachTmuxSession`
- Returns: Instructions for manual attachment

### 11. TmuxHelper Implementation Details

**Session Existence Check:**
```kotlin
fun sessionExists(): Boolean {
    val process = ProcessBuilder("tmux", "has-session", "-t", SESSION_NAME)
        .redirectErrorStream(true)
        .start()
    return process.waitFor() == 0
}
```

**Ensure Session:**
```kotlin
fun ensureSession(): Boolean {
    if (sessionExists()) return true

    val process = ProcessBuilder(
        "tmux", "new-session", "-d", "-s", SESSION_NAME
    ).redirectErrorStream(true).start()

    val success = process.waitFor() == 0
    if (success) {
        android.util.Log.d("TmuxHelper", "Created tmux session: $SESSION_NAME")
    } else {
        android.util.Log.e("TmuxHelper", "Failed to create tmux session: ${process.inputStream.bufferedReader().readText()}")
    }
    return success
}
```

**Send Command:**
```kotlin
fun sendCommand(command: String): Boolean {
    val process = ProcessBuilder(
        "tmux", "send-keys", "-t", SESSION_NAME, command, "Enter"
    ).redirectErrorStream(true).start()

    val success = process.waitFor() == 0
    if (success) {
        android.util.Log.d("TmuxHelper", "Sent command: ${command.take(50)}...")
    } else {
        android.util.Log.e("TmuxHelper", "Failed to send command: ${process.inputStream.bufferedReader().readText()}")
    }
    return success
}
```

**Cleanup Orphans:**
```kotlin
fun cleanupOrphans(): Boolean {
    val process = ProcessBuilder(
        "pkill", "-9", "-f", "apt|dpkg|pkg"
    ).redirectErrorStream(true).start()

    return process.waitFor() == 0
}
```

**Kill Session:**
```kotlin
fun killSession(): Boolean {
    val process = ProcessBuilder(
        "tmux", "kill-session", "-t", SESSION_NAME
    ).redirectErrorStream(true).start()

    val success = process.waitFor() == 0
    android.util.Log.d("TmuxHelper", "Kill session result: $success")
    return success
}
```

### 12. Installation Status Tracking

```kotlin
suspend fun pollInstallationStatus(statusFile: String): InstallationStep {
    val startTime = System.currentTimeMillis()
    val timeoutMs = 30 * 60 * 1000L // 30 minutes

    while (System.currentTimeMillis() - startTime < timeoutMs) {
        delay(5000) // Poll every 5 seconds

        val file = File(statusFile)
        if (!file.exists()) continue

        val content = file.readText().trim()

        return when {
            content.contains("COMPLETE") -> InstallationStep.COMPLETE
            content.contains("FAILED") -> {
                val reason = content.substringAfter("FAILED:")
                InstallationStep.FAILED(reason)
            }
            content.contains("STEP:") -> {
                val step = content.substringAfter("STEP:")
                // Parse step number and update UI
                InstallationStep.RUNNING(step)
            }
            else -> InstallationStep.UNKNOWN
        }
    }

    return InstallationStep.TIMEOUT
}
```

### 13. User Instructions

**When installation fails:**
```
Installation failed at step 2: pkg upgrade

To recover:
1. Open Termux app
2. Run: dpkg --configure -a
3. Then retry installation

View logs:
- lute_pkg_update.log
- lute_pkg_upgrade.log
- lute_python_install.log
- lute_pip_upgrade.log
- lute_lute3_install.log
```

**To view live progress:**
```
Open Termux app and run:
tmux attach -t lute_session

Detach (return to app):
Ctrl+b, then press 'd'
```

## Advantages Over Current Implementation

1. **Single bash process** - All commands run in same context
2. **No orphans** - Explicit cleanup, session management
3. **User visibility** - Can see exactly what's happening
4. **State preservation** - Commands share working directory, env vars
5. **Better debugging** - Full logs captured for each step
6. **Progress tracking** - Clear indication of which step is running
7. **No lock issues** - Orphan cleanup prevents dpkg conflicts
8. **Manual intervention** - User can attach and debug if needed

## Testing Checklist

- [ ] Create tmux session from scratch
- [ ] Detect existing session
- [ ] Send commands successfully
- [ ] All 5 steps complete sequentially
- [ ] Error on step 2 stops execution
- [ ] Status file updates correctly
- [ ] Timeout after 30 minutes
- [ ] Lock file prevents concurrent installs
- [ ] Orphan cleanup prevents lock conflicts
- [ ] User can attach to session manually
- [ ] Session killed on completion
- [ ] Logs saved to Downloads
- [ ] UI shows step progress
- [ ] Error messages display correctly
