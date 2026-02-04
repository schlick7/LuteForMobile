# Running Termux Commands from Your App Using Foreground Service (Android 16 Compatible)

This guide explains how to reliably start Termux commands from your
Android app using a **foreground service**, which is required on Android
12--16 due to background execution restrictions.

------------------------------------------------------------------------

## Why This Is Needed

Android 12+ blocks apps from starting background services in other
apps.\
Termux's `RUN_COMMAND` interface uses a service --- so if you call it
from the background, you get:

    background denied

A **foreground service** is allowed to start other services because it
is considered user-visible work.

------------------------------------------------------------------------

## What Counts as Foreground

Android considers your app foreground if:

-   An Activity is visible and resumed
-   A foreground service is running with a notification
-   The user just interacted with your app

Not foreground:

-   BroadcastReceiver
-   Background service
-   Application.onCreate
-   Boot receiver
-   JobScheduler jobs

------------------------------------------------------------------------

## Required Termux Setup

Inside Termux:

    ~/.termux/termux.properties

Add:

    allow-external-apps=true

Restart Termux after changing this.

------------------------------------------------------------------------

## Required Permission

Add to your app manifest:

``` xml
<uses-permission android:name="com.termux.permission.RUN_COMMAND"/>
```

Termux will prompt the user to approve this permission on first use.

------------------------------------------------------------------------

## Correct Execution Flow

    User launches your app
    → startForegroundService()
    → show notification immediately
    → send RUN_COMMAND intent to Termux

Order matters --- the foreground notification must exist before sending
the command.

------------------------------------------------------------------------

## Manifest Setup

``` xml
<service
    android:name=".TermuxTriggerService"
    android:foregroundServiceType="dataSync"
    android:exported="false"/>
```

------------------------------------------------------------------------

## Start Foreground Service From Activity

Must be called from a visible Activity:

``` java
Intent svc = new Intent(this, TermuxTriggerService.class);
ContextCompat.startForegroundService(this, svc);
```

------------------------------------------------------------------------

## Foreground Service Implementation

``` java
public class TermuxTriggerService extends Service {

    @Override
    public void onCreate() {
        super.onCreate();

        Notification notif = new NotificationCompat.Builder(this, "termux")
            .setContentTitle("Starting task")
            .setSmallIcon(R.drawable.ic_launcher)
            .build();

        startForeground(1, notif);

        runTermuxCommand();
    }

    private void runTermuxCommand() {
        Intent cmd = new Intent("com.termux.RUN_COMMAND");
        cmd.setClassName(
            "com.termux",
            "com.termux.app.RunCommandService"
        );

        cmd.putExtra(
            "command",
            "/data/data/com.termux/files/home/myscript.sh"
        );

        cmd.putExtra("background", true);

        startService(cmd);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
```

------------------------------------------------------------------------

## Notification Channel (Android 8+ Required)

Without this, the service crashes and never becomes foreground.

``` java
NotificationChannel channel =
    new NotificationChannel(
        "termux",
        "Termux Runner",
        NotificationManager.IMPORTANCE_LOW);

getSystemService(NotificationManager.class)
    .createNotificationChannel(channel);
```

------------------------------------------------------------------------

## Timing Rule (Android 14--16)

You must call:

    startForeground()

within **5 seconds** of service start or Android will kill the service.

------------------------------------------------------------------------

## Reliability Tip

Add a short delay before sending the Termux command to avoid race
conditions:

``` java
new Handler(Looper.getMainLooper()).postDelayed(
    this::runTermuxCommand,
    300
);
```

------------------------------------------------------------------------

## Common Failure Causes

Still denied even with foreground service if:

-   RUN_COMMAND sent before startForeground()
-   Service started from background receiver
-   Permission not granted
-   allow-external-apps not enabled in Termux
-   Notification channel missing
-   Foreground service started too late

------------------------------------------------------------------------

## Android 16 Compatibility Summary

  Method                              Works
  ----------------------------------- -------
  Foreground Activity → RUN_COMMAND   Yes
  Foreground Service → RUN_COMMAND    Yes
  Background → RUN_COMMAND            No
  BroadcastReceiver → RUN_COMMAND     No

------------------------------------------------------------------------

## Final Notes

There is no supported way to silently trigger Termux commands from the
background on Android 16 without foreground visibility or root access.
Foreground service is the most reliable production-safe method.
