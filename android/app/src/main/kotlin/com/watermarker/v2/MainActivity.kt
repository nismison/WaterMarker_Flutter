package com.watermarker.v2

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL_PERMISSION = "external_storage_permission"
    private val CHANNEL_MEDIA_STORE = "media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ===== 原来的权限功能保留 =====
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_PERMISSION
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openManageAllFilesPage" -> {
                    openManageAllFilesPermissionPage()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ===== 新增：MediaStore 插入图片，保证 100% 出现在相册 =====
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_MEDIA_STORE
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "insertImageToMediaStore" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("INVALID", "path 不能为空", null)
                    } else {
                        val ok = insertImageToMediaStore(path)
                        result.success(ok)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** MediaStore 插入逻辑：直接把图片注册到系统图库 */
    private fun insertImageToMediaStore(path: String): Boolean {
        return try {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DATA, path)       // 绝对路径
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

    /** 原功能：打开管理所有文件权限 */
    private fun openManageAllFilesPermissionPage() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } else {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
}
