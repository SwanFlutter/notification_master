package com.example.notification_master

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.WorkManager

/**
 * Broadcast receiver that gets triggered when the device boots up.
 * Used to restart the notification polling service if it was previously enabled.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootCompletedReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Boot completed, checking if notification polling should be started")
            
            // Check if notification polling was previously enabled
            val prefs = context.getSharedPreferences(NotificationMasterPlugin.PREFS_NAME, Context.MODE_PRIVATE)
            val pollingEnabled = prefs.getBoolean(NotificationMasterPlugin.PREF_POLLING_ENABLED, false)
            
            if (pollingEnabled) {
                Log.d(TAG, "Notification polling was enabled, restarting it")
                
                // Get the polling URL and interval
                val pollingUrl = prefs.getString(NotificationMasterPlugin.PREF_POLLING_URL, null)
                val pollingIntervalMinutes = prefs.getInt(
                    NotificationMasterPlugin.PREF_POLLING_INTERVAL_MINUTES, 
                    NotificationMasterPlugin.DEFAULT_POLLING_INTERVAL_MINUTES
                )
                
                if (pollingUrl != null) {
                    // Restart the notification polling worker
                    NotificationPollingWorker.schedulePolling(
                        context,
                        pollingUrl,
                        pollingIntervalMinutes,
                        ExistingPeriodicWorkPolicy.UPDATE
                    )
                }
            }
        }
    }
}
