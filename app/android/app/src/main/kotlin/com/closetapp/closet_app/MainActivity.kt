package com.closetapp.closet_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
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
        val bitmap = BitmapFactory.decodeFile(imagePath)
        if (bitmap == null) {
            result.success(imagePath)
            return
        }

        val inputImage = InputImage.fromBitmap(bitmap, 0)
        val options = SubjectSegmenterOptions.Builder()
            .enableForegroundConfidenceMask()
            .build()
        val segmenter = SubjectSegmentation.getClient(options)

        segmenter.process(inputImage)
            .addOnSuccessListener { segmentationResult ->
                val mask = segmentationResult.foregroundConfidenceMask
                if (mask == null) {
                    result.success(imagePath)
                    return@addOnSuccessListener
                }

                val width = bitmap.width
                val height = bitmap.height
                val output = bitmap.copy(Bitmap.Config.ARGB_8888, true)

                // Apply the confidence mask: pixels below 0.5 confidence become transparent.
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        val confidence = mask.get()
                        if (confidence < 0.5f) {
                            output.setPixel(x, y, Color.TRANSPARENT)
                        }
                    }
                }
                mask.rewind()

                try {
                    val outputFile = File(imagePath).let {
                        File(it.parent, it.nameWithoutExtension + "_bg_removed.png")
                    }
                    FileOutputStream(outputFile).use { out ->
                        output.compress(Bitmap.CompressFormat.PNG, 100, out)
                    }
                    result.success(outputFile.absolutePath)
                } catch (e: Exception) {
                    result.success(imagePath)
                }
            }
            .addOnFailureListener {
                result.success(imagePath)
            }
    }
}
