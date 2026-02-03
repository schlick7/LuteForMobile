# Termux Freezing Fix Plan

## Problem Analysis

The Termux process is getting frozen because of **Android's background execution limits**. When your app starts the Lute3 server using `startService()`, it works initially while the app is in foreground, but Android immediately kills the background service when the app goes to background.

**Note:** This plan addresses only the Termux integration within the app and does not affect user-added local URL servers.

## Root Cause

The core issue is that your current implementation uses `startService()` for Termux operations, which:
1. Has no foreground guarantee on Android 8.0+
2. Can be killed within seconds when app goes to background
3. Has no heartbeat monitoring to detect when Termux dies
4. No auto-restart mechanism if Termux gets terminated

## Comprehensive Fix Plan

### Phase 1: Critical Fixes (Immediate)

**1. Convert to Foreground Service**
- Create `TermuxForegroundService` that runs Termux commands in foreground
- Use `startForegroundService()` instead of `startService()`
- Show persistent notification to keep service alive

### Phase 2: Enhancement Features

**2. Enhanced Server Status Detection**
- Replace simple file checks with HTTP status checks
- Implement proper timeout handling
- Add retry logic for server startup
- Auto-restart Termux if server is not responding

**4. Graceful Shutdown**
- Proper cleanup when app closes
- Save server state before termination
- Restore state on app restart

### Phase 3: Optimization

**5. User Experience Improvements**
- User-configurable timeout settings
- Auto-recovery notifications

### Potential Future Enhancements

**Wake Locks and Battery Optimization:**
- For scenarios requiring extended background processing
- Battery optimization whitelisting for improved reliability on some devices
- These features can be added if foreground service proves insufficient on certain devices


## Key Implementation Changes

**In TermuxServer.kt:**
- Replace `launchLute3ServerWithAutoShutdown()` with foreground service version
- Add robust HTTP-based server status detection methods

**New Components Needed:**
- `TermuxForegroundService` class

## Android Version Considerations

The fix will work across all Android versions by:
- Using foreground services (required for Android 8.0+)
- Implementing adaptive heartbeat intervals
- Adding proper permission handling

## Expected Outcome

After implementing these changes:
- Termux will stay running even when app is in background
- Lute3 server will remain accessible at port 5001
- Automatic recovery if Termux gets terminated
- Much more reliable long-running server operation

## Implementation Priority

**Phase 1 (Critical):**
1. Convert to foreground service for Termux operations

**Phase 2 (Enhancement):**
1. Implement robust server status detection with auto-restart
2. Implement graceful shutdown procedures
3. Add user notifications for service status

**Phase 3 (Optimization):**
1. User experience improvements and configurable settings

## Files to Modify

1. `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxServer.kt`
2. `android/app/src/main/kotlin/com/schlick7/luteformobile/TermuxLauncher.kt`
3. Create new `TermuxForegroundService.kt`
4. Update `TermuxConstants.kt` with new constants
5. Update Flutter integration code in `lib/core/services/termux_service.dart`

## Testing Strategy

1. Test on Android 8.0+ devices to verify foreground service works
2. Test background execution limits on various Android versions
3. Verify heartbeat monitoring and auto-restart functionality
4. Test server accessibility after app goes to background

## Risk Assessment

**Low Risk:**
- Adding heartbeat monitoring
- Improving server status detection

**Medium Risk:**
- Converting to foreground service
- Adding auto-restart logic

**High Risk:**
- Breaking existing Termux integration
- Changing service lifecycle management


---

**Note:** This plan addresses the fundamental Android background execution limitations that are causing the Termux freezing issue. The solution provides a robust, long-term fix that will work across all Android versions and usage scenarios.

**Important:** These changes apply exclusively to the integrated Termux functionality and do not impact user-configured local URL servers.