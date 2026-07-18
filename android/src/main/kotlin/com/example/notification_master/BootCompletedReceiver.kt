package com.example.notification_master

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
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

            // Re-arm scheduled (background) notifications after reboot.
            rescheduleNotifications(context)
        }
    }

    /**
     * Re-create every pending scheduled notification using the AlarmManager.
     * Notifications whose time has already passed are dropped.
     */
    private fun rescheduleNotifications(context: Context) {
        try {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val now = System.currentTimeMillis()

            for (item in ScheduledNotificationStore.all(context)) {
                if (item.triggerAtMillis <= now) {
                    // Missed while device was off — remove it.
                    ScheduledNotificationStore.remove(context, item.id)
                    continue
                }

                val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
                    action = ScheduledNotificationReceiver.ACTION_SCHEDULED
                    putExtra(ScheduledNotificationReceiver.EXTRA_ID, item.id)
                    putExtra(ScheduledNotificationReceiver.EXTRA_TITLE, item.title)
                    putExtra(ScheduledNotificationReceiver.EXTRA_MESSAGE, item.message)
                    putExtra(ScheduledNotificationReceiver.EXTRA_CHANNEL_ID, item.channelId)
                    putExtra(ScheduledNotificationReceiver.EXTRA_PRIORITY, item.priority)
                    putExtra(ScheduledNotificationReceiver.EXTRA_TARGET_SCREEN, item.targetScreen)
                    putExtra(ScheduledNotificationReceiver.EXTRA_EXTRA_DATA, item.extraDataJson)
                }

                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    android.app.PendingIntent.FLAG_IMMUTABLE or
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = android.app.PendingIntent.getBroadcast(
                    context, item.id, intent, flags
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    !alarmManager.canScheduleExactAlarms()
                ) {
                    alarmManager.setAndAllowWhileIdle(
                        android.app.AlarmManager.RTC_WAKEUP, item.triggerAtMillis, pendingIntent
                    )
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        android.app.AlarmManager.RTC_WAKEUP, item.triggerAtMillis, pendingIntent
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling notifications after boot", e)
        }
    }
}
