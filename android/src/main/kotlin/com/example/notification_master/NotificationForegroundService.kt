package com.example.notification_master

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.logging.HttpLoggingInterceptor
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Foreground service for continuous notification polling.
 * This service runs with higher priority than background tasks and is less likely to be killed by the system.
 */
class NotificationForegroundService : Service() {

    companion object {
        private const val TAG = "NotificationForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "notification_master_service_channel"
        private const val CHANNEL_NAME = "Notification Service"
        private const val DEFAULT_INTERVAL_MINUTES = 15L

        // Intent actions
        const val ACTION_START_SERVICE = "com.example.notification_master.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.example.notification_master.STOP_SERVICE"

        // Intent extras
        const val EXTRA_POLLING_URL = "polling_url"
        const val EXTRA_INTERVAL_MINUTES = "interval_minutes"
        const val EXTRA_CHANNEL_ID = "channel_id"

        // Constants for stopForeground
        const val STOP_FOREGROUND_REMOVE = 1

        // Service state
        private val isRunning = AtomicBoolean(false)

        /**
         * Check if the service is running
         */
        fun isServiceRunning(): Boolean {
            return isRunning.get()
        }
    }

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private var pollingJob: Job? = null

    private var pollingUrl: String? = null
    private var intervalMinutes: Long = DEFAULT_INTERVAL_MINUTES
    private var customChannelId: String? = null

    // Create OkHttpClient for making HTTP requests
    private val client by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BASIC
            })
            .build()
    }

    // Create Moshi for JSON parsing
    private val moshi by lazy {
        Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                pollingUrl = intent.getStringExtra(EXTRA_POLLING_URL)
                intervalMinutes = intent.getLongExtra(EXTRA_INTERVAL_MINUTES, DEFAULT_INTERVAL_MINUTES)
                customChannelId = intent.getStringExtra(EXTRA_CHANNEL_ID)

                Log.d(TAG, "Starting service with URL: $pollingUrl, interval: $intervalMinutes, channel: $customChannelId")

                if (pollingUrl.isNullOrEmpty()) {
                    Log.e(TAG, "Cannot start service: polling URL is null or empty")
                    stopSelf()
                    return START_NOT_STICKY
                }

                try {
                    startForegroundService()
                    startPolling()
                    isRunning.set(true)
                    Log.d(TAG, "Service started successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground service", e)
                    stopSelf()
                    return START_NOT_STICKY
                }
            }
            ACTION_STOP_SERVICE -> {
                Log.d(TAG, "Stopping service")
                stopPolling()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
                isRunning.set(false)
            }
        }

        // If the service is killed, restart it
        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        stopPolling()
        serviceJob.cancel()
        isRunning.set(false)
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    /**
     * Start the service in foreground mode with a persistent notification
     */
    private fun startForegroundService() {
        // Ensure notification channel is created before creating notification
        createNotificationChannel()
        val notification = createServiceNotification()
        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "Started foreground service")
    }

    /**
     * Create the notification channel for the service notification
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = customChannelId ?: CHANNEL_ID
            val channelName = if (customChannelId != null) "Custom Notification Channel" else CHANNEL_NAME

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for notification service"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Created notification channel: $channelId")
        }
    }

    /**
     * Create the persistent notification for the foreground service
     */
    private fun createServiceNotification(): Notification {
        // Get the notification icon resource ID
        val iconResId = resources.getIdentifier("notification_icon", "drawable", packageName)

        // Use custom channel ID if provided
        val channelId = customChannelId ?: CHANNEL_ID

        Log.d(TAG, "Creating service notification with channel: $channelId")

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Notification Service")
            .setContentText("Checking for notifications every $intervalMinutes minutes")
            .setSmallIcon(if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    /**
     * Start polling for notifications
     */
    private fun startPolling() {
        stopPolling() // Stop any existing polling

        pollingJob = serviceScope.launch {
            while (isActive) {
                try {
                    Log.d(TAG, "Polling for notifications from $pollingUrl")
                    checkForNotifications()
                } catch (e: Exception) {
                    Log.e(TAG, "Error during notification polling", e)
                }

                // Wait for the next interval
                delay(TimeUnit.MINUTES.toMillis(intervalMinutes))
            }
        }

        Log.d(TAG, "Started notification polling every $intervalMinutes minutes")
    }

    /**
     * Stop polling for notifications
     */
    private fun stopPolling() {
        pollingJob?.cancel()
        pollingJob = null
        Log.d(TAG, "Stopped notification polling")
    }

    /**
     * Check for notifications from the server
     */
    private suspend fun checkForNotifications() {
        val url = pollingUrl ?: return

        try {
            // Create the HTTP request
            val request = Request.Builder()
                .url(url)
                .get()
                .build()

            // Execute the request
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    Log.e(TAG, "Polling request failed: ${response.code}")
                    return
                }

                // Parse the response body
                val responseBody = response.body?.string()
                if (responseBody.isNullOrEmpty()) {
                    Log.d(TAG, "Empty response body")
                    return
                }

                // Parse the notifications from the response
                try {
                    val adapter = moshi.adapter(NotificationPollingWorker.NotificationResponse::class.java)
                    val notificationResponse = adapter.fromJson(responseBody)

                    // Process notifications if available
                    if (notificationResponse != null && notificationResponse.notifications.isNotEmpty()) {
                        // Process each notification
                        for (notification in notificationResponse.notifications) {
                            showNotification(notification)
                        }
                    } else {
                        Log.d(TAG, "No notifications found in response")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to parse notification response", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking for notifications", e)
        }
    }

    /**
     * Show a notification using the NotificationReceiver
     */
    private fun showNotification(notification: NotificationPollingWorker.NotificationData) {
        val intent = Intent(applicationContext, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_NOTIFICATION_RECEIVED
            putExtra(NotificationReceiver.EXTRA_TITLE, notification.title)
            putExtra(NotificationReceiver.EXTRA_MESSAGE, notification.message)

            if (notification.bigText != null) {
                putExtra(NotificationReceiver.EXTRA_BIG_TEXT, notification.bigText)
            }

            if (notification.channelId != null) {
                putExtra(NotificationReceiver.EXTRA_CHANNEL_ID, notification.channelId)
            }
        }

        applicationContext.sendBroadcast(intent)
    }
}
