package com.example.notification_master

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Broadcast receiver for handling notification events.
 * This receiver can be used to handle notifications received from various sources,
 * including HTTP/JSON notifications.
 */
class NotificationReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "NotificationReceiver"
        const val ACTION_NOTIFICATION_RECEIVED = "com.example.notification_master.NOTIFICATION_RECEIVED"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_BIG_TEXT = "big_text"
        const val EXTRA_CHANNEL_ID = "channel_id"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received intent: ${intent.action}")
        
        if (intent.action == ACTION_NOTIFICATION_RECEIVED) {
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Notification"
            val message = intent.getStringExtra(EXTRA_MESSAGE) ?: ""
            val bigText = intent.getStringExtra(EXTRA_BIG_TEXT)
            val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: NotificationHelper.DEFAULT_CHANNEL_ID
            
            // Show the notification
            val notificationHelper = NotificationHelper(context)
            if (bigText != null) {
                notificationHelper.showBigTextNotification(title, message, bigText, channelId)
            } else {
                notificationHelper.showNotification(title, message, channelId)
            }
        }
    }
}
