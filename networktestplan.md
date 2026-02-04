# Network Test & Request Queue Plan

## Overview

This document outlines the plan to implement a robust network layer that handles server unavailability gracefully by queueing requests and leveraging existing cache strategies.

## Requirements

1. **Queue API Requests**: All API requests should be queued if the server test fails.
2. **Server Check**: Add a server check for when the local URL is active.
3. **Retry Logic**: Retry every 200ms until successful, then resume queued requests.
4. **Early Launch**: Run the server test as early as possible in the app launch.
5. **Deduplication**: Combine identical requests (same URL + Method + Body) if one is already queued.
6. **Cache Preservation**: The app should load and use cache even if the server is failing.
7. **Visual Feedback**: Show "Connecting..." banner if cache is empty, or use cache if available.

---

## Architecture

### Phase 1: Early Server Health Check (Priority: High)

**Objective:** Determine server availability **before** the UI starts making requests.

#### `lib/core/services/server_health_service.dart`

A lightweight service with a single method: `Future<bool> isReachable(String url)`.

```dart
class ServerHealthService {
  static Future<bool> isReachable(String url) async {
    // Uses a fast HEAD request to check server availability
    // Returns true if server responds with 200
  }
}
```

#### Modifications to `lib/main.dart`

1. Load SharedPreferences & Initialize Hive Caches (runs immediately, blocking if needed).
2. Determine `serverUrl`.
3. (Non-blocking) Start polling the server every 200ms.
4. `runApp()` starts immediately, but the UI enters a "Connecting" or "Offline" mode if the server isn't ready yet.

### Phase 2: Request Queue & Deduplication (Priority: High)

**Objective:** Ensure all requests are eventually processed when the server returns.

#### `lib/core/network/api_request_queue.dart`

- **Deduplication**: Uses a key `MD5(Method + URL + Body)` to identify identical requests.
  - If Request A and B are identical and A is pending, B waits for A's result instead of adding a duplicate.
- **Queueing**: Stores pending `Dio` request options.
- **Auto-Flush**: A background loop checks server health every 200ms. When healthy, it replays the queue FIFO.

#### `lib/core/network/queued_dio_interceptor.dart`

A `Dio` interceptor that:
1. Wraps every request.
2. If `ServerHealthService.isReachable()` is false, adds the request to `ApiRequestQueue` and pauses the Dio `Chain`.
3. When the queue flushes (server returns), resolves the `Chain` with the successful response.

#### Modifications to `lib/core/network/api_service.dart`

Inject the queue interceptor into the Dio instance.

### Phase 3: UI Connectivity Status (Priority: Low)

**Objective:** Visual feedback without blocking UX.

#### Enhancements to `lib/shared/providers/server_status_provider.dart`

Extend `ServerStatusNotifier` to track "Connecting" vs "Offline" states:

```dart
enum ServerState {
  connecting,  // Initial launch, waiting for server
  online,      // Server is reachable
  offline,     // Server unreachable, requests queued
}
```

#### UI Updates

- **`AppDrawer` or `MainNavigation`**: Show a slim "Connecting..." banner if `state == connecting` and `activeBooks.isEmpty`.
- If `activeBooks.isNotEmpty` (cache hit), show nothing or a subtle toast on failed actions.

### Phase 4: Cache Strategy Enforcement (Priority: High)

**Objective:** Ensure the UI never blocks on network errors.

#### `lib/features/books/providers/books_provider.dart`

- **Current State**: Already looks good - checks cache first, then network.
- **Enhancement**: If network fails, set `errorMessage` but **keep** the cached books in `activeBooks`. Don't clear them.

#### `lib/features/reader/providers/reader_provider.dart`

- **Current State**: Already looks good - uses cache, fetches fresh data in background.
- **Enhancement**: If fetch fails and we have cached page data, merge it and hide the error.

---

## Behavior Matrix

| Scenario | Behavior |
|----------|----------|
| **App Launch, Server Down, Cache Empty** | App launches → Shows "Connecting..." banner → Empty book list. Requests are queued. |
| **App Launch, Server Down, Cache Exists** | App launches → Shows cached books immediately → "Connecting..." banner (subtle) → Requests queued. |
| **Server Comes Online** | Queue flushes automatically → Requests replay → UI updates live. |
| **User Clicks "Refresh" (Server Down)** | Shows error toast → Keeps showing cached data. |
| **User Edits Term (Server Down)** | Request queued → Success toast when server returns (or silently succeeds in background). |

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/core/services/server_health_service.dart` | **Create** | Generic server reachability check. |
| `lib/core/network/api_request_queue.dart` | **Create** | Request deduplication & FIFO queue. |
| `lib/core/network/queued_dio_interceptor.dart` | **Create** | Dio interceptor to pause/resume requests. |
| `lib/core/network/api_service.dart` | **Modify** | Inject the queue interceptor. |
| `lib/main.dart` | **Modify** | Early server poll before `runApp()`. |
| `lib/shared/providers/server_status_provider.dart` | **Modify** | Track "connecting" state. |
| `lib/features/books/providers/books_provider.dart` | **Modify** | Keep cached books on network error. |
| `lib/features/reader/providers/reader_provider.dart` | **Modify** | Keep cached page on network error. |

---

## Implementation Order

1. **`server_health_service.dart`**: Foundation for all health checks.
2. **`main.dart` modification**: Early polling logic.
3. **`api_request_queue.dart`**: Core queue logic with deduplication.
4. **`queued_dio_interceptor.dart`**: Dio integration.
5. **`api_service.dart` integration**: Wiring it all together.
6. **`server_status_provider.dart`**: UI state management.
7. **Provider enhancements**: Cache preservation.

---

## Key Technical Details

### Request Signature for Deduplication

The request signature is computed as:
```dart
String signature = MD5('$method:$url:$body').toString();
```

This ensures that:
- `POST /term/datatables` with `data: {id: 1}` is distinct from `POST /term/datatables` with `data: {id: 2}`.
- Two clicks on "Mark Page Read" for the same page are deduplicated.

### Queue Processing Order

- **FIFO (First In, First Out)**: Requests are processed in the order they were received.
- **Retry Interval**: The queue attempts to flush every 200ms by polling `ServerHealthService`.

### Connection Timeout

- All requests should use a short timeout (e.g., 5 seconds) to fail fast and enter the queue.
- The queue ensures these requests are eventually retried.

---

## Future Enhancements (Out of Scope)

- **Request Timeout in Queue**: Currently, requests stay in the queue forever until the app closes.
- **Queue Size Limit**: Unlimited for now, but could be added later.
- **Visual Indicator of Queue Size**: No indicator requested by the user.
