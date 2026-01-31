package com.schlick7.luteformobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

object StorageHelper {
    
    fun isScopedStorageRequired(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
    }
    
    fun isManageExternalStoragePermissionGranted(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        }
    }
    
    fun hasStoragePermissions(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val readMediaImages = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.READ_MEDIA_IMAGES
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            val readMediaVideo = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.READ_MEDIA_VIDEO
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            readMediaImages && readMediaVideo
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.READ_EXTERNAL_STORAGE
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        }
    }
    
    fun getDownloadsDirectory(): File {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        } else {
            File(
                Environment.getExternalStorageDirectory(),
                Environment.DIRECTORY_DOWNLOADS
            )
        }
    }
    
    fun createFileInDownloads(
        context: Context,
        fileName: String,
        content: ByteArray
    ): Result<File> {
        return try {
            val downloadsDir = getDownloadsDirectory()
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { output ->
                output.write(content)
            }
            
            Result.success(file)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun saveDownloadedFile(
        context: Context,
        fileName: String,
        inputStream: InputStream
    ): Result<File> {
        return try {
            val downloadsDir = getDownloadsDirectory()
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            
            val outputFile = File(downloadsDir, fileName)
            
            inputStream.use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }
            
            Result.success(outputFile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun findBackupFiles(context: Context): List<File> {
        return try {
            val downloadsDir = getDownloadsDirectory()
            if (!downloadsDir.exists()) {
                return emptyList()
            }
            
            downloadsDir.listFiles { file ->
                file.name.matches(Regex("(manual_)?lute_backup_.*\\.db(\\.gz)?"))
            }?.sortedByDescending { it.lastModified() } ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    fun createStorageAccessIntent(): Intent {
        return Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        }
    }
    
    fun copyFileFromUri(
        context: Context,
        uri: Uri,
        destinationFile: File
    ): Result<Unit> {
        return try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destinationFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return Result.failure(Exception("Unable to open input stream"))
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun getRequiredPermissions(): List<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO,
                android.Manifest.permission.MANAGE_EXTERNAL_STORAGE
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            listOf(
                android.Manifest.permission.MANAGE_EXTERNAL_STORAGE
            )
        } else {
            listOf(
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }
    }
    
    fun shouldRequestPermissionRationale(context: Context, permission: String): Boolean {
        return ActivityCompat.shouldShowRequestPermissionRationale(
            context as Activity,
            permission
        )
    }
}