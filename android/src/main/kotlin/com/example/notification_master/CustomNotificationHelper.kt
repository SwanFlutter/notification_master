package com.example.notification_master

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Helper class for creating custom styled notifications with custom layouts
 * This allows for full UI customization of notifications
 */
class CustomNotificationHelper(private val context: Context) {

    companion object {
        const val CUSTOM_CHANNEL_ID = "custom_styled_channel"
        const val CUSTOM_CHANNEL_NAME = "Custom Styled Notifications"
        private var notificationId = 5000
        
        fun getUniqueNotificationId(): Int = notificationId++
    }

    init {
        createCustomStyledChannel()
    }

    /**
     * Create a channel for custom styled notifications
     */
    private fun createCustomStyledChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CUSTOM_CHANNEL_ID,
                CUSTOM_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for custom styled notifications with custom UI"
                enableLights(true)
                lightColor = Color.CYAN
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                setShowBadge(true)
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d("CustomNotificationHelper", "✅ Custom styled channel created")
        }
    }

    /**
     * Show a notification with custom layout
     * This creates a heads-up notification with custom UI
     */
    fun showCustomLayoutNotification(
        title: String,
        message: String,
        intent: Intent? = null
    ): Int {
        val notificationId = getUniqueNotificationId()

        Log.d("CustomNotificationHelper", "📱 Creating custom layout notification")

        // Create pending intent
        val pendingIntent = if (intent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            PendingIntent.getActivity(context, notificationId, intent, flags)
        } else {
            null
        }

        // Build notification with custom layout
        val builder = NotificationCompat.Builder(context, CUSTOM_CHANNEL_ID)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setVibrate(longArrayOf(0, 300, 200, 300))
            .setLights(Color.CYAN, 1000, 500)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())

        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
                Log.d("CustomNotificationHelper", "✅ Custom notification shown")
            } catch (e: SecurityException) {
                Log.e("CustomNotificationHelper", "❌ Permission error: ${e.message}")
                e.printStackTrace()
            }
        }

        return notificationId
    }

    /**
     * Show a heads-up notification with full screen intent
     * This is the most intrusive notification type
     */
    fun showFullScreenNotification(
        title: String,
        message: String,
        intent: Intent? = null
    ): Int {
        val notificationId = getUniqueNotificationId()

        Log.d("CustomNotificationHelper", "📱 Creating full screen notification")

        // Create full screen intent
        val fullScreenIntent = if (intent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            PendingIntent.getActivity(context, notificationId, intent, flags)
        } else {
            null
        }

        // Build notification
        val builder = NotificationCompat.Builder(context, CUSTOM_CHANNEL_ID)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setVibrate(longArrayOf(0, 500, 250, 500))
            .setLights(Color.RED, 1000, 500)

        if (fullScreenIntent != null) {
            builder.setFullScreenIntent(fullScreenIntent, true)
            builder.setContentIntent(fullScreenIntent)
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
                Log.d("CustomNotificationHelper", "✅ Full screen notification shown")
            } catch (e: SecurityException) {
                Log.e("CustomNotificationHelper", "❌ Permission error: ${e.message}")
                e.printStackTrace()
            }
        }

        return notificationId
    }

    /**
     * Get the appropriate notification icon
     */
    private fun getNotificationIcon(): Int {
        val packageManager = context.packageManager
        try {
            val appInfo = packageManager.getApplicationInfo(context.packageName, 0)
            return appInfo.icon
        } catch (e: Exception) {
            return android.R.drawable.ic_dialog_info
        }
    }
}
