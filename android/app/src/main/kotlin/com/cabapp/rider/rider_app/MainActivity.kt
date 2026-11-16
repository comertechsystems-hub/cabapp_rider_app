package com.cabapp.rider.rider_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createRiderNotificationChannels()
    }

    private fun createRiderNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            val riderChannelId = "cabapp_rider_alerts"
            val riderChannelName = "Ride Updates & Driver Arrivals"
            val riderChannelDesc = "Alerts when a driver accepts your trip, arrives at pickup, or updates counter-offers."
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(riderChannelId, riderChannelName, importance).apply {
                description = riderChannelDesc
                enableLights(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()
                setSound(ringtoneUri, audioAttributes)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }
}
