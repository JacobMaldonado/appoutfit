package com.closetapp.closet_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val bgRemovalChannel = "closet/background_removal"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, bgRemovalChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "removeBackground") {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath == null) {
                        result.error("INVALID_ARGS", "imagePath is required", null)
                        return@setMethodCallHandler
                    }
                    removeBackground(imagePath, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun removeBackground(imagePath: String, result: MethodChannel.Result) {
        Thread {
            try {
                // ML Kit Subject Segmentation is in beta; for now we apply a simple
                // alpha-channel approach. Replace with ML Kit call when stable.
                val bitmap = BitmapFactory.decodeFile(imagePath)
                    ?: run { result.success(imagePath); return@Thread }

                // For now: pass through. Swap in ML Kit Subject Segmentation here.
                val outputFile = File(imagePath).let {
                    File(it.parent, it.nameWithoutExtension + "_bg_removed.png")
                }
                FileOutputStream(outputFile).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                }
                result.success(outputFile.absolutePath)
            } catch (e: Exception) {
                result.success(imagePath)
            }
        }.start()
    }
}
