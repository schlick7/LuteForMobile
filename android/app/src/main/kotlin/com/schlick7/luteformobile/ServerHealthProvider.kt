package com.schlick7.luteformobile

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

class ServerHealthProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "com.schlick7.luteformobile.serverhealth"
        val CONTENT_URI: Uri = Uri.parse("content://$AUTHORITY/status")
        
        private var _isServerRunning: Boolean = false
        val isServerRunning: Boolean get() = _isServerRunning
        
        fun clearCache() {
            _isServerRunning = false
        }
        
        private val mainScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
        
        private const val COLUMN_STATUS = "status"
    }

    override fun onCreate(): Boolean {
        context?.let { ctx ->
            mainScope.launch {
                checkServerHealth(ctx)
            }
        }
        return true
    }

    private suspend fun checkServerHealth(context: android.content.Context) {
        val port = TermuxConstants.LUTE3_DEFAULT_PORT
        val url = "http://127.0.0.1:$port"
        
        val client = OkHttpClient.Builder()
            .connectTimeout(500, TimeUnit.MILLISECONDS)
            .readTimeout(500, TimeUnit.MILLISECONDS)
            .callTimeout(500, TimeUnit.MILLISECONDS)
            .build()

        try {
            val request = Request.Builder()
                .url(url)
                .head()
                .build()

            val response = client.newCall(request).execute()
            _isServerRunning = response.isSuccessful
            response.close()
            
            android.util.Log.d("ServerHealthProvider", "Initial server health check: $_isServerRunning")
        } catch (e: Exception) {
            _isServerRunning = false
            android.util.Log.d("ServerHealthProvider", "Initial server health check failed: ${e.javaClass.simpleName}")
        }
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor {
        val cursor = MatrixCursor(arrayOf(COLUMN_STATUS))
        cursor.addRow(arrayOf(if (_isServerRunning) 1 else 0))
        return cursor
    }

    override fun getType(uri: Uri): String {
        return "vnd.android.cursor.item/vnd.$AUTHORITY.status"
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        return null
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
        return 0
    }

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int {
        return 0
    }
}
