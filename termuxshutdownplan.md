# Termux Server Shutdown Plan

## Problem Statement
Termux stays in notifications forever with "1 task" because there's no proper idle shutdown mechanism. The Lute3 server continues running even after the app is closed, draining battery and leaving a persistent notification.

## Requirements
- **30-minute idle timer** before server shutdown
- Server does NOT stop immediately when app closes
- Timer resets when user activity is detected
- Grace period allows server to stay warm for quick re-access
- Clean shutdown that removes Termux notification

## Proposed Solution

### 1. Idle Timer in TermuxForegroundService

**Implementation:**
- Add `lastHeartbeatTime` field to track last activity timestamp
- Run periodic check every 60 seconds using `Handler.postDelayed()`
- Calculate idle time: `currentTime - lastHeartbeatTime`
- If idle time > 30 minutes: stop server and service

**Why this works:**
- Service continues running in background even when app closes
- Timer persists across app lifecycle changes
- Independent of app state (open/closed/asleep)

### 2. Heartbeat Reset Mechanism

**Implementation:**
- Modify `touchHeartbeat()` to send broadcast to TermuxForegroundService
- Service receives broadcast via `onStartCommand()` with heartbeat action
- Updates `lastHeartbeatTime = System.currentTimeMillis()`

**Heartbeat triggers:**
- Automatic on every API request from app to server
- Periodic heartbeat (every 5 minutes) while app is in foreground
- Manual heartbeat when app returns from background

### 3. Activity Detection Strategy

**While app is open:**
- Heartbeats sent automatically on API calls
- Background timer sends periodic heartbeats every 5 minutes
- `lastHeartbeatTime` constantly refreshed

**When app is backgrounded:**
- Heartbeats may continue briefly (background timer)
- Eventually stop when Android pauses app
- Idle timer begins counting from last heartbeat

**When app is closed (swiped away):**
- Heartbeats stop immediately
- 30-minute countdown begins
- Server shuts down after timeout, removing notification

**When phone sleeps:**
- Same as app closed scenario
- Heartbeats stop
- Timer counts down in background service

### 4. Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| App closed | Server stops after 30 min idle |
| Phone sleeps with app open | Server stops after 30 min idle |
| App backgrounded temporarily | Resets when returning, no shutdown |
| Quick app switch | Timer continues, <30 min = no shutdown |
| Overnight | Server stops, fresh start next day |

### 5. Shutdown Sequence

1. Idle timer expires (30 minutes elapsed)
2. Service calls `stopLute3ServerInternal()`
3. Sends `pkill` command to Termux to stop Python process
4. Removes heartbeat file
5. Service calls `stopSelf()`
6. Android removes foreground notification
7. Termux notification disappears (no more "1 task")

## Files to Modify

1. **TermuxForegroundService.kt**
   - Add `lastHeartbeatTime` field
   - Add `startIdleMonitor()` method
   - Add `resetIdleTimer()` method
   - Handle heartbeat action in `onStartCommand()`
   - Call monitor in `onStartCommand()` after server starts

2. **TermuxServer.kt**
   - Modify `touchHeartbeat()` to send broadcast to service
   - Update signature if needed

3. **TermuxBridge.kt**
   - Update method channel handler for heartbeat
   - Send proper intent to service

## Configuration Constants

Already defined in `TermuxConstants.kt`:
- `IDLE_TIMEOUT_MINUTES = 30` (existing)
- `HEARTBEAT_CHECK_INTERVAL = 120` (existing, for health checks)

New constants needed:
- `IDLE_CHECK_INTERVAL_MS = 60000` (1 minute)
- `HEARTBEAT_ACTION = "HEARTBEAT_RECEIVED"`

## Benefits

- ✅ Server stays warm for quick access during active use
- ✅ Battery savings when not using the app
- ✅ Clean shutdown removes persistent notifications
- ✅ Simple implementation using existing architecture
- ✅ No modification to lute3 Python code required
- ✅ Works regardless of Android version or power settings

## Testing Scenarios

1. Open app → use for 10 minutes → close → verify server stops after 30 min total
2. Open app → background for 20 minutes → return → verify timer reset
3. Open app → close immediately → wait 30 minutes → verify shutdown
4. Open app → put phone to sleep → verify shutdown after 30 min
5. Verify Termux notification disappears after shutdown

## Future Enhancements (Optional)

- Make timeout duration user-configurable in settings
- Add "keep alive" toggle for extended sessions
- Smart shutdown based on time of day (e.g., don't stop during study hours)
- Push notification warning 5 minutes before shutdown
