package com.example.notification_master

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.Target
import java.io.IOException
import java.net.URL
import java.util.concurrent.ExecutionException

/**
 * Helper class for creating and showing notifications.
 * Handles notification channel creation for Android 8.0+ (API level 26+).
 */
class NotificationHelper(private val context: Context) {

    companion object {
        const val DEFAULT_CHANNEL_ID = "notification_master_default_channel"
        const val DEFAULT_CHANNEL_NAME = "Default Channel"
        const val DEFAULT_CHANNEL_DESCRIPTION = "Default notification channel"

        // High priority channel
        const val HIGH_PRIORITY_CHANNEL_ID = "notification_master_high_priority_channel"
        const val HIGH_PRIORITY_CHANNEL_NAME = "High Priority Channel"
        const val HIGH_PRIORITY_CHANNEL_DESCRIPTION = "Channel for important notifications"

        // Silent channel
        const val SILENT_CHANNEL_ID = "notification_master_silent_channel"
        const val SILENT_CHANNEL_NAME = "Silent Channel"
        const val SILENT_CHANNEL_DESCRIPTION = "Channel for silent notifications"

        // Notification IDs
        private var notificationId = 0

        // Get a unique notification ID
        fun getUniqueNotificationId(): Int = notificationId++

        // Notification importance levels
        const val IMPORTANCE_DEFAULT = 0
        const val IMPORTANCE_HIGH = 1
        const val IMPORTANCE_LOW = 2
        const val IMPORTANCE_MIN = 3
        const val IMPORTANCE_SILENT = 4
    }

    init {
        // Create notification channels for Android 8.0+
        createNotificationChannels()
    }

    /**
     * Create notification channels for Android 8.0+ (API level 26+)
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create the default notification channel
            val defaultChannel = NotificationChannel(
                DEFAULT_CHANNEL_ID,
                DEFAULT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = DEFAULT_CHANNEL_DESCRIPTION
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }

            // Create high priority channel
            val highPriorityChannel = NotificationChannel(
                HIGH_PRIORITY_CHANNEL_ID,
                HIGH_PRIORITY_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = HIGH_PRIORITY_CHANNEL_DESCRIPTION
                enableLights(true)
                lightColor = Color.RED
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500)
                setShowBadge(true)
            }

            // Create silent channel
            val silentChannel = NotificationChannel(
                SILENT_CHANNEL_ID,
                SILENT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = SILENT_CHANNEL_DESCRIPTION
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }

            // Register the channels with the system
            notificationManager.createNotificationChannels(
                listOf(defaultChannel, highPriorityChannel, silentChannel)
            )
        }
    }

    /**
     * Create a custom notification channel
     *
     * @param channelId The channel ID
     * @param channelName The channel name
     * @param channelDescription The channel description
     * @param importance The importance level (use constants from companion object)
     * @param enableLights Whether to enable lights
     * @param lightColor The light color
     * @param enableVibration Whether to enable vibration
     * @param enableSound Whether to enable sound
     */
    fun createCustomChannel(
        channelId: String,
        channelName: String,
        channelDescription: String,
        importance: Int,
        enableLights: Boolean = true,
        lightColor: Int = Color.BLUE,
        enableVibration: Boolean = true,
        enableSound: Boolean = true
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Map importance level to Android importance
            val androidImportance = when (importance) {
                IMPORTANCE_HIGH -> NotificationManager.IMPORTANCE_HIGH
                IMPORTANCE_LOW -> NotificationManager.IMPORTANCE_LOW
                IMPORTANCE_MIN -> NotificationManager.IMPORTANCE_MIN
                IMPORTANCE_SILENT -> NotificationManager.IMPORTANCE_LOW
                else -> NotificationManager.IMPORTANCE_DEFAULT
            }

            // Create the channel
            val channel = NotificationChannel(
                channelId,
                channelName,
                androidImportance
            ).apply {
                description = channelDescription
                enableLights(enableLights)
                if (enableLights) {
                    this.lightColor = lightColor
                }
                enableVibration(enableVibration)
                if (enableVibration) {
                    vibrationPattern = longArrayOf(0, 250, 250, 250)
                }
                if (!enableSound) {
                    setSound(null, null)
                }
            }

            // Register the channel with the system
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Show a simple notification
     *
     * @param title The notification title
     * @param message The notification message
     * @param channelId The notification channel ID (defaults to DEFAULT_CHANNEL_ID)
     * @param intent Optional intent to launch when the notification is tapped
     * @param priority The notification priority (for Android < 8.0)
     * @param autoCancel Whether the notification should be auto-canceled when tapped
     * @return The notification ID
     */
    fun showNotification(
        title: String,
        message: String,
        channelId: String = DEFAULT_CHANNEL_ID,
        intent: Intent? = null,
        priority: Int = NotificationCompat.PRIORITY_DEFAULT,
        autoCancel: Boolean = true
    ): Int {
        val notificationId = getUniqueNotificationId()

        // Create pending intent for notification tap action
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

        // Build the notification
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(priority)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(autoCancel)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        // Set the pending intent if available
        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
            } catch (e: SecurityException) {
                // Handle missing notification permission
                // This can happen on Android 13+ if POST_NOTIFICATIONS permission is not granted
                e.printStackTrace()
            }
        }

        return notificationId
    }

    /**
     * Show a notification with a big text style
     *
     * @param title The notification title
     * @param message The notification message
     * @param bigText The expanded text content
     * @param channelId The notification channel ID (defaults to DEFAULT_CHANNEL_ID)
     * @param intent Optional intent to launch when the notification is tapped
     * @param priority The notification priority (for Android < 8.0)
     * @param autoCancel Whether the notification should be auto-canceled when tapped
     * @return The notification ID
     */
    fun showBigTextNotification(
        title: String,
        message: String,
        bigText: String,
        channelId: String = DEFAULT_CHANNEL_ID,
        intent: Intent? = null,
        priority: Int = NotificationCompat.PRIORITY_DEFAULT,
        autoCancel: Boolean = true
    ): Int {
        val notificationId = getUniqueNotificationId()

        // Create pending intent for notification tap action
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

        // Build the notification with big text style
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setPriority(priority)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(autoCancel)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        // Set the pending intent if available
        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
            } catch (e: SecurityException) {
                // Handle missing notification permission
                e.printStackTrace()
            }
        }

        return notificationId
    }

    /**
     * Show a notification with an image
     *
     * @param title The notification title
     * @param message The notification message
     * @param imageUrl The URL of the image to display
     * @param channelId The notification channel ID (defaults to DEFAULT_CHANNEL_ID)
     * @param intent Optional intent to launch when the notification is tapped
     * @param priority The notification priority (for Android < 8.0)
     * @param autoCancel Whether the notification should be auto-canceled when tapped
     * @return The notification ID
     */
    fun showImageNotification(
        title: String,
        message: String,
        imageUrl: String,
        channelId: String = DEFAULT_CHANNEL_ID,
        intent: Intent? = null,
        priority: Int = NotificationCompat.PRIORITY_DEFAULT,
        autoCancel: Boolean = true
    ): Int {
        val notificationId = getUniqueNotificationId()

        // Create pending intent for notification tap action
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

        // First show a notification without the image
        val initialBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(priority)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(autoCancel)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setProgress(0, 0, true) // Show indeterminate progress while loading image

        // Set the pending intent if available
        if (pendingIntent != null) {
            initialBuilder.setContentIntent(pendingIntent)
        }

        // Show the initial notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, initialBuilder.build())
            } catch (e: SecurityException) {
                // Handle missing notification permission
                android.util.Log.e("NotificationHelper", "Permission error: ${e.message}")
                e.printStackTrace()
            }
        }

        // Load the image in a background thread
        Thread {
            try {
                // Load the image from URL
                val bitmap = loadImageFromUrl(imageUrl)

                // Update the notification with the image
                val updatedBuilder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(getNotificationIcon())
                    .setContentTitle(title)
                    .setContentText(message)
                    .setPriority(priority)
                    .setSound(null) // Don't play sound again on update
                    .setAutoCancel(autoCancel)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setOnlyAlertOnce(true) // Don't alert again

                // Add the image if it was loaded successfully
                if (bitmap != null) {
                    updatedBuilder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .bigPicture(bitmap)
                            .setBigContentTitle(title)
                            .setSummaryText(message)
                    )
                    updatedBuilder.setLargeIcon(bitmap)
                }

                // Set the pending intent if available
                if (pendingIntent != null) {
                    updatedBuilder.setContentIntent(pendingIntent)
                }

                // Update the notification
                with(NotificationManagerCompat.from(context)) {
                    try {
                        notify(notificationId, updatedBuilder.build())
                    } catch (e: SecurityException) {
                        // Handle missing notification permission
                        android.util.Log.e("NotificationHelper", "Permission error updating notification: ${e.message}")
                        e.printStackTrace()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("NotificationHelper", "Error in background thread: ${e.message}")
                e.printStackTrace()
            }
        }.start()

        return notificationId
    }

    /**
     * Show a notification with custom actions
     *
     * @param title The notification title
     * @param message The notification message
     * @param channelId The notification channel ID (defaults to DEFAULT_CHANNEL_ID)
     * @param intent Optional intent to launch when the notification is tapped
     * @param actions List of action pairs (action title to action intent)
     * @param priority The notification priority (for Android < 8.0)
     * @param autoCancel Whether the notification should be auto-canceled when tapped
     * @return The notification ID
     */
    fun showNotificationWithActions(
        title: String,
        message: String,
        channelId: String = DEFAULT_CHANNEL_ID,
        intent: Intent? = null,
        actions: List<Pair<String, Intent>>,
        priority: Int = NotificationCompat.PRIORITY_DEFAULT,
        autoCancel: Boolean = true
    ): Int {
        val notificationId = getUniqueNotificationId()

        // Create pending intent for notification tap action
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

        // Build the notification
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(priority)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(autoCancel)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        // Set the pending intent if available
        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        // Add actions
        for ((index, action) in actions.withIndex()) {
            val actionTitle = action.first
            val actionIntent = action.second

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val actionPendingIntent = PendingIntent.getActivity(
                context,
                notificationId + index + 1000, // Ensure unique request code
                actionIntent,
                flags
            )

            builder.addAction(0, actionTitle, actionPendingIntent)
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
            } catch (e: SecurityException) {
                // Handle missing notification permission
                e.printStackTrace()
            }
        }

        return notificationId
    }

    /**
     * Load an image from a URL using Glide
     *
     * @param imageUrl The URL of the image to load
     * @return The loaded bitmap, or null if loading failed
     */
    private fun loadImageFromUrl(imageUrl: String): Bitmap? {
        return try {
            // Use Glide to load the image - this handles all the networking and caching
            Glide.with(context.applicationContext)
                .asBitmap()
                .load(imageUrl)
                .submit(Target.SIZE_ORIGINAL, Target.SIZE_ORIGINAL)
                .get()
        } catch (e: ExecutionException) {
            Log.e("NotificationHelper", "Error loading image with Glide: ${e.message}")
            e.printStackTrace()
            null
        } catch (e: InterruptedException) {
            Log.e("NotificationHelper", "Image loading interrupted: ${e.message}")
            e.printStackTrace()
            null
        } catch (e: Exception) {
            Log.e("NotificationHelper", "Unexpected error loading image: ${e.message}")
            e.printStackTrace()
            null
        }
    }

    /**
     * Get the appropriate notification icon
     */
    private fun getNotificationIcon(): Int {
        // Try to get the app icon
        val packageManager = context.packageManager
        try {
            val appInfo = packageManager.getApplicationInfo(context.packageName, 0)
            return appInfo.icon
        } catch (e: Exception) {
            // Fallback to a default icon from the Android framework
            return android.R.drawable.ic_dialog_info
        }
    }
}
