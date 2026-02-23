package com.example.notification_master

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.*
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.logging.HttpLoggingInterceptor
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * WorkManager worker for polling notifications from a remote server.
 * This is a battery-efficient way to periodically check for notifications.
 */
class NotificationPollingWorker(
    context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        private const val TAG = "NotificationPollingWorker"
        private const val WORK_NAME = "notification_polling_worker"

        // Input data keys
        private const val KEY_POLLING_URL = "polling_url"

        /**
         * Schedule periodic polling for notifications
         *
         * @param context The application context
         * @param pollingUrl The URL to poll for notifications
         * @param intervalMinutes The polling interval in minutes
         * @param existingWorkPolicy Policy for handling existing work
         */
        fun schedulePolling(
            context: Context,
            pollingUrl: String,
            intervalMinutes: Int,
            existingWorkPolicy: ExistingPeriodicWorkPolicy
        ) {
            // Create input data with polling URL
            val inputData = Data.Builder()
                .putString(KEY_POLLING_URL, pollingUrl)
                .build()

            // Run when network is available; no battery constraint so system can run
            // when other apps trigger background work or when device is idle (e.g. every 15 min)
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            // Create the periodic work request
            val workRequest = PeriodicWorkRequestBuilder<NotificationPollingWorker>(
                intervalMinutes.toLong(), TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setInputData(inputData)
                .setBackoffCriteria(
                    BackoffPolicy.LINEAR,
                    30000, // 30 seconds backoff
                    TimeUnit.MILLISECONDS
                )
                .build()

            // Enqueue the work request
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                existingWorkPolicy,
                workRequest
            )

            Log.d(TAG, "Scheduled notification polling every $intervalMinutes minutes")
        }

        /**
         * Cancel the notification polling
         *
         * @param context The application context
         */
        fun cancelPolling(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "Cancelled notification polling")
        }
    }

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

    override fun doWork(): Result {
        Log.d(TAG, "Starting notification polling work")

        // Get the polling URL from input data
        val pollingUrl = inputData.getString(KEY_POLLING_URL)
        if (pollingUrl.isNullOrEmpty()) {
            Log.e(TAG, "Polling URL is null or empty")
            return Result.failure()
        }

        try {
            // Create the HTTP request
            val request = Request.Builder()
                .url(pollingUrl)
                .get()
                .build()

            // Execute the request
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    Log.e(TAG, "Polling request failed: ${response.code}")
                    return Result.retry()
                }

                // Parse the response body
                val responseBody = response.body?.string()
                if (responseBody.isNullOrEmpty()) {
                    Log.d(TAG, "Empty response body")
                    return Result.success()
                }

                // Parse the notifications from the response
                try {
                    // First try to parse as a standard notification response
                    val adapter = moshi.adapter(NotificationResponse::class.java)
                    val notificationResponse = adapter.fromJson(responseBody)

                    if (notificationResponse != null && notificationResponse.notifications.isNotEmpty()) {
                        // Process each notification
                        for (notification in notificationResponse.notifications) {
                            showNotification(notification)
                        }
                    } else {
                        // If no notifications found in standard format, try to create a notification from the response itself
                        // This is useful for testing with generic APIs like jsonplaceholder
                        Log.d(TAG, "No notifications found in standard format, creating a test notification")
                        val testNotification = NotificationData(
                            title = "Test Notification",
                            message = "Response received from server",
                            bigText = responseBody.take(500), // Take first 500 chars of response
                            channelId = "high_priority_channel"
                        )
                        showNotification(testNotification)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to parse notification response", e)

                    // Create a test notification even if parsing fails
                    Log.d(TAG, "Creating a test notification due to parsing failure")
                    val testNotification = NotificationData(
                        title = "Test Notification",
                        message = "Received response but couldn't parse it",
                        bigText = "Response body: ${responseBody.take(200)}...\n\nError: ${e.message}",
                        channelId = "high_priority_channel"
                    )
                    showNotification(testNotification)

                    // Return success since we showed a notification anyway
                    return Result.success()
                }
            }

            return Result.success()
        } catch (e: IOException) {
            Log.e(TAG, "Network error during polling", e)
            return Result.retry()
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during polling", e)
            return Result.failure()
        }
    }

    /**
     * Show a notification using the NotificationReceiver
     */
    private fun showNotification(notification: NotificationData) {
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

    /**
     * Data class for notification response from the server
     */
    data class NotificationResponse(
        val notifications: List<NotificationData>
    )

    /**
     * Data class for a single notification
     */
    data class NotificationData(
        val title: String,
        val message: String,
        val bigText: String? = null,
        val channelId: String? = null
    )
}
