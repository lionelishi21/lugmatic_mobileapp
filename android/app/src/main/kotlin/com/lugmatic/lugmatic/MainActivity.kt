package com.lugmatic.lugmatic

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "com.lugmatic/background_blur"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "setBlurEnabled") {
                val enabled = call.argument<Boolean>("enabled") ?: false
                // TODO: Implement native ML Kit background blur processing and LiveKit VideoProcessor bridging here
                println("Lugmatic Background Blur requested. Enabled: $enabled. (Native implementation pending)")
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
