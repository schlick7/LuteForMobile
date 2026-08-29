package com.schlick7.luteformobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge for an optional, user-chosen SAF backup
 * folder on shared external storage.
 *
 * The on-device lute database lives in app-private storage
 * (`filesDir/lute/`) which is deleted on "Clear storage" and on
 * uninstall. Backups are only durable if they also live somewhere
 * outside the app. We let the user pick any folder via the Storage
 * Access Framework (`ACTION_OPEN_DOCUMENT_TREE`); the resulting
 * URI grant is persisted by the OS, so the app can keep writing
 * there with no broad permissions and no "All files access" toggle.
 *
 * The chosen URI is remembered in SharedPreferences (not Hive, which
 * lives in the cache dir). A "Clear storage" wipes that pointer, but
 * the already-exported backup files in the picked folder survive.
 *
 * The SAF picker is launched via the classic
 * `startActivityForResult` + `onActivityResult` flow (FlutterActivity
 * is not a ComponentActivity, so `registerForActivityResult` is not
 * available). MainActivity forwards `onActivityResult` here via
 * [handleActivityResult].
 *
 * Channel:  com.schlick7.luteformobile/backup_folder
 *
 * Methods:
 *  - getFolder()        -> { uri, name } | null
 *  - pickFolder()       -> { uri, name } | null (SAF chooser)
 *  - clearFolder()      -> null
 *  - exportBackup(bytes, filename, maxKeep) -> { kept, filename }
 *  - listFiles()        -> [ filename, ... ]
 */
class BackupFolderBridge(private val activity: Activity) {
    companion object {
        private const val TAG = "BackupFolderBridge"
        const val CHANNEL = "com.schlick7.luteformobile/backup_folder"
        const val REQUEST_PICK_FOLDER = 4001

        private const val PREFS = "lute_backup_folder"
        private const val KEY_URI = "uri"
        private const val KEY_NAME = "name"

        // Backups we export to the external folder are pruned to at
        // most this many newest files so we never just pile dozens
        // of .db files there.
        const val DEFAULT_MAX_KEEP = 10

        private val BACKUP_REGEX =
            Regex("(manual_)?lute_backup_.*\\.db(\\.gz)?")
    }

    private val prefs
        get() = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val resolver
        get() = activity.contentResolver

    private var pendingResult: MethodChannel.Result? = null

    /** Launch the SAF folder chooser. Result arrives via [handleActivityResult]. */
    fun launchPicker() {
        activity.startActivityForResult(
            StorageHelper.createStorageAccessIntent(),
            REQUEST_PICK_FOLDER,
        )
    }

    /** Process the result of the SAF picker (called from Activity.onActivityResult). */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_PICK_FOLDER) return
        val r = pendingResult
        pendingResult = null
        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            val uri = data.data!!
            try {
                resolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
            } catch (e: Exception) {
                Log.e(TAG, "takePersistableUriPermission failed: ${e.message}", e)
            }
            val name = queryTreeName(uri) ?: uri.toString()
            prefs.edit()
                .putString(KEY_URI, uri.toString())
                .putString(KEY_NAME, name)
                .apply()
            r?.success(mapOf("uri" to uri.toString(), "name" to name))
        } else {
            // User cancelled the chooser.
            r?.success(null)
        }
    }

    fun register(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getFolder" -> result.success(currentFolder())
                "pickFolder" -> {
                    if (pendingResult != null) {
                        result.error("BUSY", "Folder chooser already open", null)
                    } else {
                        pendingResult = result
                        launchPicker()
                    }
                }
                "clearFolder" -> {
                    prefs.edit().remove(KEY_URI).remove(KEY_NAME).apply()
                    result.success(null)
                }
                "listFiles" -> result.success(listFiles())
                "exportBackup" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val filename = call.argument<String>("filename")
                    val maxKeep =
                        call.argument<Int>("maxKeep") ?: DEFAULT_MAX_KEEP
                    if (bytes == null || filename.isNullOrBlank()) {
                        result.error("BAD_ARGS", "Missing bytes/filename", null)
                        return@setMethodCallHandler
                    }
                    Thread({
                        try {
                            val kept = exportBackup(bytes, filename, maxKeep)
                            mainResult(result, mapOf("kept" to kept, "filename" to filename))
                        } catch (e: Exception) {
                            Log.e(TAG, "exportBackup failed", e)
                            mainError(result, "EXPORT_FAILED", e.message ?: e.toString())
                        }
                    }, "lute-backup-export").start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun currentFolder(): Map<String, Any?>? {
        val uri = prefs.getString(KEY_URI, null) ?: return null
        return mapOf(
            "uri" to uri,
            "name" to (prefs.getString(KEY_NAME, null) ?: uri),
        )
    }

    /** Name of a freshly-picked tree, or null if unavailable. */
    private fun queryTreeName(uri: Uri): String? {
        return try {
            resolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { c ->
                if (c.moveToFirst()) {
                    c.getString(0)
                } else null
            }
        } catch (e: Exception) {
            Log.w(TAG, "queryTreeName failed: ${e.message}")
            null
        }
    }

    /**
     * Write `bytes` into the picked folder as `filename`, then prune
     * the folder's lute backups down to `maxKeep` newest. Returns the
     * number of backup files kept after pruning.
     */
    private fun exportBackup(
        bytes: ByteArray,
        filename: String,
        maxKeep: Int,
    ): Int {
        val uri = prefs.getString(KEY_URI, null)
            ?: throw IllegalStateException("No backup folder chosen")
        val treeUri = Uri.parse(uri)
        // Re-take the persisted grant on every export (idempotent).
        // Guards against a stale URI whose permission was never
        // persisted (or was dropped), which would otherwise fail with
        // "Invalid URI" from the provider.
        try {
            resolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (e: Exception) {
            throw IllegalStateException(
                "No permission for folder: ${e.message}",
            )
        }

        // DocumentFile (androidx.documentfile) handles providers whose
        // authority isn't literally "documents" (e.g.
        // com.android.externalstorage.documents), which the
        // DocumentsContract.getTreeDocumentId /
        // buildChildDocumentsUriUsingTree helpers reject with
        // "Invalid URI".
        val tree = DocumentFile.fromTreeUri(activity, treeUri)
            ?: throw IllegalStateException("Could not open folder")
        val doc = tree.createFile("application/octet-stream", filename)
            ?: throw IllegalStateException("createFile returned null")
        resolver.openOutputStream(doc.uri)?.use { out ->
            out.write(bytes)
        } ?: throw IllegalStateException("openOutputStream returned null")

        pruneTo(tree, maxKeep)
        return maxKeep.coerceAtLeast(0)
    }

    /** List lute backup filenames currently in the folder (newest last). */
    private fun listFiles(): List<String> {
        val uri = prefs.getString(KEY_URI, null) ?: return emptyList()
        return try {
            val tree = DocumentFile.fromTreeUri(activity, Uri.parse(uri))
                ?: return emptyList()
            tree.listFiles()
                .filter { it.name != null && BACKUP_REGEX.matches(it.name!!) }
                .sortedBy { it.lastModified() }
                .map { it.name!! }
        } catch (e: Exception) {
            Log.w(TAG, "listFiles failed: ${e.message}")
            emptyList()
        }
    }

    /** Delete all but the `maxKeep` newest lute backup files. */
    private fun pruneTo(tree: DocumentFile, maxKeep: Int) {
        if (maxKeep <= 0) return
        val docs = tree.listFiles()
            .filter { it.name != null && BACKUP_REGEX.matches(it.name!!) }
            .sortedByDescending { it.lastModified() } // newest first
        if (docs.size <= maxKeep) return
        for (old in docs.drop(maxKeep)) {
            try {
                if (old.delete()) {
                    Log.d(TAG, "pruned old backup: ${old.name}")
                }
            } catch (e: Exception) {
                Log.w(TAG, "failed to prune ${old.name}: ${e.message}")
            }
        }
    }

    private fun mainResult(result: MethodChannel.Result, value: Any) {
        activity.runOnUiThread { result.success(value) }
    }

    private fun mainError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        activity.runOnUiThread { result.error(code, message, null) }
    }
}