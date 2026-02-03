package com.schlick7.luteformobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.pm.ServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class TermuxForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "lute3_server_channel"
        const val NOTIFICATION_ID = 1002
        const val EXTRA_PORT = "port"
        const val EXTRA_IDLE_TIMEOUT = "idle_timeout_minutes"

        fun createStartIntent(
            context: Context,
            port: Int = TermuxConstants.LUTE3_DEFAULT_PORT,
            idleTimeoutMinutes: Int = TermuxConstants.IDLE_TIMEOUT_MINUTES
        ): Intent {
            return Intent(context, TermuxForegroundService::class.java).apply {
                putExtra(EXTRA_PORT, port)
                putExtra(EXTRA_IDLE_TIMEOUT, idleTimeoutMinutes)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            Log.d("TermuxForegroundService", "Received STOP_SERVICE action")
            stopSelf()
            return START_NOT_STICKY
        }

        val port =
            intent?.getIntExtra(EXTRA_PORT, TermuxConstants.LUTE3_DEFAULT_PORT) ?: TermuxConstants.LUTE3_DEFAULT_PORT
        val idleTimeoutMinutes = intent?.getIntExtra(EXTRA_IDLE_TIMEOUT, TermuxConstants.IDLE_TIMEOUT_MINUTES)
            ?: TermuxConstants.IDLE_TIMEOUT_MINUTES

        Log.d(
            "TermuxForegroundService",
            "Starting foreground service on port $port with timeout $idleTimeoutMinutes minutes"
        )

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val stopIntent = Intent(this, TermuxForegroundService::class.java).apply {
            action = "STOP_SERVICE"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lute3 Server Running")
            .setContentText("Lute3 server is running on port $port")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop Server", stopPendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Actually start the Lute3 server
        startLute3ServerInternal(port, idleTimeoutMinutes)

        return START_STICKY
    }

    private fun startLute3ServerInternal(port: Int, idleTimeoutMinutes: Int) {
        val script = "python -m lute.main --port $port"

        Log.d("TermuxForegroundService", "Starting Lute3 server with script: $script")

        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", script))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_WORKDIR", TermuxConstants.TERMUX_HOME)
        }

        try {
            startService(intent)
            Log.d("TermuxForegroundService", "Lute3 server started successfully")
        } catch (e: Exception) {
            Log.e("TermuxForegroundService", "Failed to start Lute3 server: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("TermuxForegroundService", "Foreground service destroyed")

        // Stop the Lute3 server when the service is destroyed
        stopLute3ServerInternal()
    }

    private fun stopLute3ServerInternal() {
        val intent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "pkill -f \"python -m lute.main\" || true"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        startService(intent)

        val cleanupIntent = Intent().apply {
            setClassName(TermuxConstants.TERMUX_PACKAGE, TermuxConstants.TERMUX_SERVICE)
            action = TermuxConstants.TERMUX_ACTION
            putExtra("com.termux.RUN_COMMAND_PATH", TermuxConstants.TERMUX_BASH_PATH)
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "rm -f ${TermuxConstants.HEARTBEAT_FILE}"))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        }
        startService(cleanupIntent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Lute3 Server", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Lute3 server running in foreground"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
