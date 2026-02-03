# Termux Freezing Fix Plan

## Problem Analysis

The Termux process is getting frozen because of **Android's background execution limits**. When your app starts the Lute3 server using `startService()`, it works initially while the app is in foreground, but Android immediately kills the background service when the app goes to background.

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

**2. Add Heartbeat Monitoring**
- Implement periodic heartbeat checks (every 2 minutes)
- Auto-restart Termux if heartbeat fails
- Use the existing heartbeat file mechanism but make it more robust

**3. Enhanced Server Status Detection**
- Replace simple file checks with HTTP status checks
- Implement proper timeout handling
- Add retry logic for server startup

### Phase 2: Enhancement Features

**4. Keep-Alive Mechanism**
- Periodic wake-up calls to prevent Android from suspending
- Adaptive heartbeat intervals based on Android version
- Battery optimization settings

**5. Graceful Shutdown**
- Proper cleanup when app closes
- Save server state before termination
- Restore state on app restart

### Phase 3: Optimization

**6. User Experience Improvements**
- User-configurable timeout settings
- Auto-recovery notifications

### 6. Battery optimization settings:
- Adaptive power management based on device state
- Battery level-based server behavior (e.g., reduce frequency when battery low)
- Background execution limits customization

### 6. Adaptive heartbeat intervals:
- Dynamic adjustment of heartbeat frequency based on network conditions
- Reduced polling when server is stable
- Increased frequency during recovery attempts

### 6. User-configurable timeout settings:
- Per-app timeout customization
- Different timeout profiles (battery saver, performance, balanced)
- Smart timeout based on usage patterns

## Key Implementation Changes

**In TermuxServer.kt:**
- Replace `launchLute3ServerWithAutoShutdown()` with foreground service version
- Add `isLute3ServerRunningHttp()` method for robust server detection
- Implement heartbeat monitoring loop

**In TermuxLauncher.kt:**
- Add `monitorTermuxHeartbeat()` coroutine
- Enhance `isTermuxServiceRunning()` with better timeout handling
- Add auto-restart logic

**New Components Needed:**
- `TermuxForegroundService` class
- Enhanced heartbeat monitoring system
- Robust server status detection

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
2. Add process monitoring and auto-restart
3. Implement robust server status detection

**Phase 2 (Enhancement):**
1. Add keep-alive mechanism with periodic heartbeats
2. Implement graceful shutdown procedures
3. Add user notifications for service status

**Phase 3 (Optimization):**
1. Battery optimization settings
2. Adaptive heartbeat intervals
3. User-configurable timeout settings

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
5. Verify battery optimization settings work correctly

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

## Rollback Plan

If issues arise, can revert to:
1. Original `startService()` implementation
2. Remove foreground service code
3. Keep heartbeat monitoring as enhancement

## Timeline

Estimated 2-3 days for full implementation and testing of Phase 1 fixes.

---

**Note:** This plan addresses the fundamental Android background execution limitations that are causing the Termux freezing issue. The solution provides a robust, long-term fix that will work across all Android versions and usage scenarios.