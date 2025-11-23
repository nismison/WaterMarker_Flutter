package com.watermarker.v2

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL_PERMISSION = "external_storage_permission"
    private val CHANNEL_MEDIA_STORE = "media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ====== 存储权限 Channel ======
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_PERMISSION
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // 打开“允许访问所有文件”设置页（真正请求权限时用）
                "openManageAllFilesPage" -> {
                    openManageAllFilesPermissionPage()
                    result.success(null)
                }

                // 只检查当前是否具备“所有文件访问”能力（静默检查）
                "hasAllFilesPermission" -> {
                    val granted = hasAllFilesPermission()
                    result.success(granted)
                }

                else -> result.notImplemented()
            }
        }

        // ====== MediaStore Channel ======
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_MEDIA_STORE
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "insertImageToMediaStore" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val ok = insertImageToMediaStore(path)
                    result.success(ok)
                }

                else -> result.notImplemented()
            }
        }
    }

    /** 只检查是否拥有“所有文件访问”权限，不会触发任何请求或跳转 */
    private fun hasAllFilesPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ 官方 API：判断 MANAGE_EXTERNAL_STORAGE
            Environment.isExternalStorageManager()
        } else {
            // Android 10 及以下：看传统读写存储权限
            val readGranted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED

            val writeGranted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED

            readGranted && writeGranted
        }
    }

    /** MediaStore 插入逻辑：让图片出现在系统相册 */
    private fun insertImageToMediaStore(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) return false

            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DATA, path)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
                put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
            }

            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)

            println(">>> MediaStore 插入成功: $path")
            true
        } catch (e: Exception) {
            println(">>> MediaStore 插入失败: $e")
            false
        }
    }

    /** 打开管理所有文件权限设置页（真正请求权限时用） */
    private fun openManageAllFilesPermissionPage() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                startActivity(intent)
            }
        } else {
            // Android 10 及以下，如果你希望也跳设置页，可以打开应用详情页：
            try {
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } catch (_: Exception) {
                // 忽略
            }
        }
    }
}
