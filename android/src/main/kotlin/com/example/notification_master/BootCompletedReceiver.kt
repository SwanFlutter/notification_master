package com.example.notification_master

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy

/**
 * Restarts plugin background work after reboot or app update.
 *
 * Two **independent** paths:
 *
 * 1. **Local scheduled notifications (AlarmManager)** — always re-armed.
 *    These are normal OS alarms and do **not** start any polling/foreground service.
 *
 * 2. **Remote delivery services** (WorkManager polling OR foreground service) —
 *    restored **only** if that exact service was previously the active one.
 *    Local notifications alone never cause a service to start.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootCompletedReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val relevant = action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"

        if (!relevant) return

        Log.d(TAG, "Device/app event: $action — restoring scheduled alarms and active service only")

        // Path 1: local AlarmManager schedules (independent of services)
        rescheduleNotifications(context)

        // Path 2: only the previously active remote-delivery service
        restoreActiveBackgroundService(context)
    }

    /**
     * Restores polling OR foreground service if one was marked active.
     * Does nothing when active service is [NotificationMasterPlugin.NOTIFICATION_SERVICE_NONE]
     * or Firebase (managed outside this plugin).
     */
    private fun restoreActiveBackgroundService(context: Context) {
        val prefs = context.getSharedPreferences(
            NotificationMasterPlugin.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val active = prefs.getInt(
            NotificationMasterPlugin.PREF_ACTIVE_NOTIFICATION_SERVICE,
            NotificationMasterPlugin.NOTIFICATION_SERVICE_NONE
        )
        val pollingEnabled = prefs.getBoolean(
            NotificationMasterPlugin.PREF_POLLING_ENABLED,
            false
        )
        val pollingUrl = prefs.getString(NotificationMasterPlugin.PREF_POLLING_URL, null)
        val interval = prefs.getInt(
            NotificationMasterPlugin.PREF_POLLING_INTERVAL_MINUTES,
            NotificationMasterPlugin.DEFAULT_POLLING_INTERVAL_MINUTES
        )

        when (active) {
            NotificationMasterPlugin.NOTIFICATION_SERVICE_POLLING -> {
                if (pollingEnabled && !pollingUrl.isNullOrEmpty()) {
                    Log.d(TAG, "Restoring WorkManager polling service")
                    NotificationPollingWorker.schedulePolling(
                        context,
                        pollingUrl,
                        interval,
                        ExistingPeriodicWorkPolicy.UPDATE
                    )
                } else {
                    Log.d(TAG, "Polling was active flag but config missing — skip")
                }
            }
            NotificationMasterPlugin.NOTIFICATION_SERVICE_FOREGROUND -> {
                if (pollingEnabled && !pollingUrl.isNullOrEmpty()) {
                    Log.d(TAG, "Restoring foreground polling service")
                    val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
                        action = NotificationForegroundService.ACTION_START_SERVICE
                        putExtra(NotificationForegroundService.EXTRA_POLLING_URL, pollingUrl)
                        putExtra(
                            NotificationForegroundService.EXTRA_INTERVAL_MINUTES,
                            interval.toLong()
                        )
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to restore foreground service after boot", e)
                    }
                }
            }
            NotificationMasterPlugin.NOTIFICATION_SERVICE_FIREBASE -> {
                Log.d(TAG, "Firebase is active service — no local background service to restore")
            }
            else -> {
                Log.d(TAG, "No background notification service active — local notifs only")
            }
        }
    }

    /**
     * Re-create every pending scheduled notification using the AlarmManager.
     * Notifications whose time has already passed are dropped.
     */
    private fun rescheduleNotifications(context: Context) {
        try {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val now = System.currentTimeMillis()

            for (item in ScheduledNotificationStore.all(context)) {
                if (item.triggerAtMillis <= now) {
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
                    putExtra(ScheduledNotificationReceiver.EXTRA_ALARM_SOUND, item.alarmSound)
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
                        AlarmManager.RTC_WAKEUP, item.triggerAtMillis, pendingIntent
                    )
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, item.triggerAtMillis, pendingIntent
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling notifications after boot", e)
        }
    }
}
