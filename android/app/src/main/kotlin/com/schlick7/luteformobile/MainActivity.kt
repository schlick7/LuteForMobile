package com.schlick7.luteformobile

import android.content.SharedPreferences
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private var termuxBridge: TermuxBridge? = null
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var hasAutoLaunched = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
    
    override fun onResume() {
        super.onResume()
        // Delay auto-launch to avoid conflicts with app initialization
        if (!hasAutoLaunched) {
            hasAutoLaunched = true
            mainScope.launch {
                delay(500) // Reduced delay to 500ms for faster startup
                checkAndAutoLaunchTermux()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register Termux bridge
        termuxBridge = TermuxBridge(this)
        termuxBridge?.registerMethodChannel(flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        termuxBridge?.dispose()
    }

    /**
     * Checks if Termux auto-launch should be performed on app start.
     * This is called in onCreate() to ensure it runs early in the app lifecycle.
     */
    private fun checkAndAutoLaunchTermux() {
        try {
            val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            // Use the correct key format as determined by our logging
            val useTermux = prefs.getBoolean("flutter.use_termux", false)
            val autoLaunchEnabled = prefs.getBoolean("flutter.termux_auto_launch_enabled", false)

            android.util.Log.d(
                "MainActivity",
                "checkAndAutoLaunchTermux: useTermux=$useTermux, autoLaunchEnabled=$autoLaunchEnabled"
            )

            if (useTermux && autoLaunchEnabled) {
                // Perform auto-launch in a coroutine
                mainScope.launch {
                    try {
                        android.util.Log.d(
                            "MainActivity",
                            "Auto-launching Lute3 server..."
                        )
                        launchLute3ServerWithAutoShutdown(this@MainActivity)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Auto-launch failed: ${e.message}")
                    }
                }
            } else {
                android.util.Log.d(
                    "MainActivity",
                    "Auto-launch conditions not met: useTermux=$useTermux, autoLaunchEnabled=$autoLaunchEnabled"
                )
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error in checkAndAutoLaunchTermux: ${e.message}")
        }
    }
}
