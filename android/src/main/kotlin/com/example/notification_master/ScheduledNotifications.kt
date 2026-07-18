package com.example.notification_master

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persistent store for scheduled notifications so they can be re-created after
 * a device reboot (the [BootCompletedReceiver] reads this and re-arms the alarms).
 */
object ScheduledNotificationStore {
    private const val PREFS = "notification_master_scheduled"
    private const val KEY_LIST = "scheduled_list"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(context: Context, item: ScheduledItem) {
        val prefs = prefs(context)
        val list = all(context).toMutableList()
        list.removeAll { it.id == item.id }
        list.add(item)
        persist(prefs, list)
    }

    fun remove(context: Context, id: Int) {
        val prefs = prefs(context)
        val list = all(context).toMutableList()
        list.removeAll { it.id == id }
        persist(prefs, list)
    }

    fun removeAll(context: Context) {
        persist(prefs(context), emptyList())
    }

    fun all(context: Context): List<ScheduledItem> {
        val raw = prefs(context).getString(KEY_LIST, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                runCatching { ScheduledItem.fromJson(array.getJSONObject(i)) }.getOrNull()
            }
        } catch (e: Exception) {
            Log.w("ScheduledNotificationStore", "Failed to read scheduled list: ${e.message}")
            emptyList()
        }
    }

    private fun persist(prefs: android.content.SharedPreferences, list: List<ScheduledItem>) {
        val array = JSONArray()
        list.forEach { array.put(it.toJson()) }
        prefs.edit().putString(KEY_LIST, array.toString()).apply()
    }
}

/**
 * A single scheduled notification.
 *
 * @param triggerAtMillis delivery time in milliseconds since epoch (System.currentTimeMillis() based).
 */
data class ScheduledItem(
    val id: Int,
    val title: String,
    val message: String,
    val channelId: String?,
    val priority: Int,
    val targetScreen: String?,
    val extraDataJson: String?,
    val triggerAtMillis: Long
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("title", title)
        put("message", message)
        put("channelId", channelId ?: JSONObject.NULL)
        put("priority", priority)
        put("targetScreen", targetScreen ?: JSONObject.NULL)
        put("extraData", extraDataJson ?: JSONObject.NULL)
        put("triggerAt", triggerAtMillis)
    }

    companion object {
        fun fromJson(obj: JSONObject): ScheduledItem = ScheduledItem(
            id = obj.optInt("id", 0),
            title = obj.optString("title", "Notification"),
            message = obj.optString("message", ""),
            channelId = obj.optString("channelId", null)?.takeIf { it.isNotEmpty() },
            priority = obj.optInt("priority", NotificationCompat.PRIORITY_DEFAULT),
            targetScreen = obj.optString("targetScreen", null)?.takeIf { it.isNotEmpty() },
            extraDataJson = obj.optString("extraData", null)?.takeIf { it != "null" && it.isNotEmpty() },
            triggerAtMillis = obj.optLong("triggerAt", 0L)
        )
    }
}

/**
 * BroadcastReceiver triggered by [AlarmManager] when a scheduled notification's
 * time arrives. It shows the notification and removes it from the persistent store.
 *
 * Works entirely on the OS alarm clock, so the app does not need to be running.
 */
class ScheduledNotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ScheduledNotificationRcv"
        const val ACTION_SCHEDULED =
            "com.example.notification_master.SCHEDULED_NOTIFICATION"
        const val EXTRA_ID = "id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_CHANNEL_ID = "channel_id"
        const val EXTRA_PRIORITY = "priority"
        const val EXTRA_TARGET_SCREEN = "target_screen"
        const val EXTRA_EXTRA_DATA = "extra_data"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_SCHEDULED) return

        val id = intent.getIntExtra(EXTRA_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Notification"
        val message = intent.getStringExtra(EXTRA_MESSAGE) ?: ""
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID)
        val priority = intent.getIntExtra(
            EXTRA_PRIORITY,
            androidx.core.app.NotificationCompat.PRIORITY_DEFAULT
        )
        val targetScreen = intent.getStringExtra(EXTRA_TARGET_SCREEN)
        val extraData = jsonToMap(intent.getStringExtra(EXTRA_EXTRA_DATA))

        try {
            val helper = NotificationHelper(context)
            val contentIntent = getTargetIntent(context, targetScreen, extraData)
            helper.showNotification(
                title = title,
                message = message,
                channelId = channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
                intent = contentIntent,
                priority = priority,
                autoCancel = true,
                customId = id
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error showing scheduled notification", e)
        }

        // Remove from the persistent store once it has fired.
        ScheduledNotificationStore.remove(context, id)
    }

    private fun getTargetIntent(
        context: Context,
        targetScreen: String?,
        extraData: Map<String, Any>?
    ): Intent? {
        if (targetScreen == null) return null

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return null

        return launchIntent.apply {
            action = Intent.ACTION_VIEW
            putExtra("route", targetScreen)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (extraData != null) {
                putExtra("extra_data", extraData.toString())
            }
        }
    }

    private fun jsonToMap(raw: String?): Map<String, Any>? {
        if (raw.isNullOrEmpty() || raw == "null") return null
        return try {
            val obj = JSONObject(raw)
            val map = mutableMapOf<String, Any>()
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                map[key] = obj.get(key)
            }
            map
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse extraData: ${e.message}")
            null
        }
    }
}
