package com.smartelectric.smart_electric_crm

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var pendingSaveFileName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_electric_crm/project_file_save"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFile" -> {
                    if (pendingSaveResult != null) {
                        result.error("already_active", "Save file dialog is already active.", null)
                        return@setMethodCallHandler
                    }

                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"

                    if (fileName.isNullOrBlank() || bytes == null) {
                        result.error("invalid_args", "File name and bytes are required.", null)
                        return@setMethodCallHandler
                    }

                    pendingSaveResult = result
                    pendingSaveBytes = bytes
                    pendingSaveFileName = fileName

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mimeType
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }

                    startActivityForResult(intent, REQUEST_CODE_SAVE_FILE)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE_SAVE_FILE) {
            val result = pendingSaveResult
            val bytes = pendingSaveBytes
            val fileName = pendingSaveFileName

            pendingSaveResult = null
            pendingSaveBytes = null
            pendingSaveFileName = null

            if (resultCode == Activity.RESULT_CANCELED) {
                result?.success(null)
                return
            }

            if (resultCode != Activity.RESULT_OK || data?.data == null || bytes == null || fileName == null) {
                result?.error("save_failed", "Failed to save file.", null)
                return
            }

            try {
                writeBytesToUri(data.data!!, bytes)
                result?.success(fileName)
            } catch (error: IOException) {
                result?.error("save_failed", error.message, null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun writeBytesToUri(uri: Uri, bytes: ByteArray) {
        val descriptor = contentResolver.openFileDescriptor(uri, "w")
            ?: throw IOException("Failed to open destination file.")

        descriptor.use { pfd: ParcelFileDescriptor ->
            FileOutputStream(pfd.fileDescriptor).use { output ->
                output.write(bytes)
                output.flush()
                output.fd.sync()
            }
        }
    }

    private companion object {
        const val REQUEST_CODE_SAVE_FILE = 24041
    }
}
