package com.example.quran_app

import android.content.Context
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.just_audio.BackgroundTaskRunner

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Konfigurasi audio session untuk background playback
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setUsage(C.USAGE_MEDIA)
            .build()
        
        // Inisialisasi background audio runner
        BackgroundTaskRunner.init(
            application = application,
            audioAttributes = audioAttributes,
            notificationEnabled = true,
            notificationId = 1001
        )
    }
}
