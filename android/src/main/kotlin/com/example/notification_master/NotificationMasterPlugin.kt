package com.example.notification_master

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import org.json.JSONObject
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingPeriodicWorkPolicy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** NotificationMasterPlugin */
class NotificationMasterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  companion object {
    private const val TAG = "NotificationMasterPlugin"

    // Permission request codes
    private const val REQUEST_NOTIFICATION_PERMISSION = 1001

    // Notification service types
    const val NOTIFICATION_SERVICE_NONE = 0
    const val NOTIFICATION_SERVICE_POLLING = 1
    const val NOTIFICATION_SERVICE_FOREGROUND = 2
    const val NOTIFICATION_SERVICE_FIREBASE = 3

    // Shared preferences
    const val PREFS_NAME = "notification_master_prefs"
    const val PREF_POLLING_ENABLED = "polling_enabled"
    const val PREF_POLLING_URL = "polling_url"
    const val PREF_POLLING_INTERVAL_MINUTES = "polling_interval_minutes"
    const val PREF_ACTIVE_NOTIFICATION_SERVICE = "active_notification_service"
    const val PREF_SUBSCRIBED_TOPICS = "subscribed_topics"
    const val DEFAULT_POLLING_INTERVAL_MINUTES = 15
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null

  // Pending permission result
  private var pendingPermissionResult: Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "notification_master")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "requestNotificationPermission" -> {
        requestNotificationPermission(result)
      }
      "checkNotificationPermission" -> {
        checkNotificationPermission(result)
      }
      "showNotification" -> {
        val id = call.argument<Int>("id")
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val channelId = call.argument<String>("channelId")
        // Handle both Int and Long values for priority
        val priorityValue = call.argument<Any>("priority")
        val priority = when (priorityValue) {
          is Int -> priorityValue
          is Long -> priorityValue.toInt()
          else -> NotificationCompat.PRIORITY_DEFAULT
        }
        val autoCancel = call.argument<Boolean>("autoCancel") ?: true
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        showNotification(id, title, message, channelId, priority, autoCancel, targetScreen, extraData, result)
      }
      "showBigTextNotification" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val bigText = call.argument<String>("bigText") ?: ""
        val channelId = call.argument<String>("channelId")
        val priority = call.argument<Int>("priority") ?: NotificationCompat.PRIORITY_DEFAULT
        val autoCancel = call.argument<Boolean>("autoCancel") ?: true
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        showBigTextNotification(title, message, bigText, channelId, priority, autoCancel, targetScreen, extraData, result)
      }
      "showImageNotification" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val imageUrl = call.argument<String>("imageUrl")
        val channelId = call.argument<String>("channelId")
        val priority = call.argument<Int>("priority") ?: NotificationCompat.PRIORITY_DEFAULT
        val autoCancel = call.argument<Boolean>("autoCancel") ?: true
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        if (imageUrl.isNullOrEmpty()) {
          result.error("INVALID_URL", "Image URL cannot be null or empty", null)
          return
        }

        showImageNotification(title, message, imageUrl, channelId, priority, autoCancel, targetScreen, extraData, result)
      }
      "showNotificationWithActions" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val channelId = call.argument<String>("channelId")
        val priority = call.argument<Int>("priority") ?: NotificationCompat.PRIORITY_DEFAULT
        val autoCancel = call.argument<Boolean>("autoCancel") ?: true
        val actions = call.argument<List<Map<String, String>>>("actions")
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        if (actions.isNullOrEmpty()) {
          result.error("INVALID_ACTIONS", "Actions cannot be null or empty", null)
          return
        }

        showNotificationWithActions(title, message, channelId, actions, priority, autoCancel, targetScreen, extraData, result)
      }
      "createCustomChannel" -> {
        val channelId = call.argument<String>("channelId")
        val channelName = call.argument<String>("channelName")
        val channelDescription = call.argument<String>("channelDescription") ?: ""
        // Handle both Int and Long values
        val importanceValue = call.argument<Any>("importance")
        val importance = when (importanceValue) {
          is Int -> importanceValue
          is Long -> importanceValue.toInt()
          else -> NotificationHelper.IMPORTANCE_DEFAULT
        }

        val enableLights = call.argument<Boolean>("enableLights") ?: true

        // Handle both Int and Long values for lightColor
        val lightColorValue = call.argument<Any>("lightColor")
        val lightColor = when (lightColorValue) {
          is Int -> lightColorValue
          is Long -> lightColorValue.toInt()
          else -> Color.BLUE
        }

        val enableVibration = call.argument<Boolean>("enableVibration") ?: true
        val enableSound = call.argument<Boolean>("enableSound") ?: true

        if (channelId.isNullOrEmpty() || channelName.isNullOrEmpty()) {
          result.error("INVALID_CHANNEL", "Channel ID and name cannot be null or empty", null)
          return
        }

        createCustomChannel(
          channelId,
          channelName,
          channelDescription,
          importance,
          enableLights,
          lightColor,
          enableVibration,
          enableSound,
          result
        )
      }
      "startNotificationPolling" -> {
        val pollingUrl = call.argument<String>("pollingUrl")
        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: DEFAULT_POLLING_INTERVAL_MINUTES

        startNotificationPolling(pollingUrl, intervalMinutes, result)
      }
      "stopNotificationPolling" -> {
        stopNotificationPolling(result)
      }
      "startForegroundService" -> {
        val pollingUrl = call.argument<String>("pollingUrl")
        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: DEFAULT_POLLING_INTERVAL_MINUTES
        val channelId = call.argument<String>("channelId")

        startForegroundService(pollingUrl, intervalMinutes, channelId, result)
      }
      "stopForegroundService" -> {
        stopForegroundService(result)
      }
      "setFirebaseAsActiveService" -> {
        setFirebaseAsActiveService(result)
      }
      "getActiveNotificationService" -> {
        getActiveNotificationService(result)
      }
      "showHeadsUpNotification" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        showHeadsUpNotification(title, message, targetScreen, extraData, result)
      }
      "showFullScreenNotification" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        showFullScreenNotification(title, message, targetScreen, extraData, result)
      }
      "showStyledNotification" -> {
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        val channelId = call.argument<String>("channelId")
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        showStyledNotification(title, message, channelId, targetScreen, extraData, result)
      }
      "scheduleNotification" -> {
        val id = call.argument<Int>("id") ?: 0
        val title = call.argument<String>("title") ?: "Notification"
        val message = call.argument<String>("message") ?: ""
        // Epoch millis are always decoded as Long on Android.
        val scheduledEpochMillis = call.argument<Long>("scheduledEpochMillis") ?: 0L
        val channelId = call.argument<String>("channelId")
        val priorityValue = call.argument<Any>("priority")
        val priority = when (priorityValue) {
          is Int -> priorityValue
          is Long -> priorityValue.toInt()
          else -> NotificationCompat.PRIORITY_DEFAULT
        }
        val alarmSound = call.argument<Boolean>("alarmSound") ?: false
        val targetScreen = call.argument<String>("targetScreen")
        val extraData = call.argument<Map<String, Any>>("extraData")

        scheduleNotification(
          id, title, message, scheduledEpochMillis, channelId, priority,
          alarmSound, targetScreen, extraData, result
        )
      }
      "cancelScheduledNotification" -> {
        val id = call.argument<Int>("id") ?: 0
        cancelScheduledNotification(id, result)
      }
      "cancelAllScheduledNotifications" -> {
        cancelAllScheduledNotifications(result)
      }
      "getPendingScheduledNotifications" -> {
        getPendingScheduledNotifications(result)
      }
      "getDeviceToken" -> {
        getDeviceToken(result)
      }
      "subscribeToTopic" -> {
        val topic = call.argument<String>("topic")
        if (topic.isNullOrEmpty()) {
          result.error("INVALID_TOPIC", "Topic cannot be null or empty", null)
        } else {
          subscribeToTopic(topic, result)
        }
      }
      "unsubscribeFromTopic" -> {
        val topic = call.argument<String>("topic")
        if (topic.isNullOrEmpty()) {
          result.error("INVALID_TOPIC", "Topic cannot be null or empty", null)
        } else {
          unsubscribeFromTopic(topic, result)
        }
      }
      "getSubscribedTopics" -> {
        getSubscribedTopics(result)
      }
      "canScheduleExactAlarms" -> {
        canScheduleExactAlarms(result)
      }
      "openExactAlarmSettings" -> {
        openExactAlarmSettings(result)
      }
      "openAppNotificationSettings" -> {
        openAppNotificationSettings(result)
      }
      "startBackgroundPollingService" -> {
        // The background daemon is supported on Windows, Linux, and macOS only.
        // On Android use startForegroundService() or startNotificationPolling().
        result.error(
          "PLATFORM_NOT_SUPPORTED",
          "startBackgroundPollingService is only available on Windows, Linux, and macOS. " +
          "Use startForegroundService() or startNotificationPolling() on Android.",
          null
        )
      }
      "stopBackgroundPollingService" -> {
        result.error(
          "PLATFORM_NOT_SUPPORTED",
          "stopBackgroundPollingService is only available on Windows, Linux, and macOS. " +
          "Use stopForegroundService() or stopNotificationPolling() on Android.",
          null
        )
      }
      "isBackgroundPollingRunning" -> {
        result.error(
          "PLATFORM_NOT_SUPPORTED",
          "isBackgroundPollingRunning is only available on Windows, Linux, and macOS.",
          null
        )
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  /**
   * Request notification permission for Android 13+ (API level 33+)
   */
  private fun requestNotificationPermission(result: Result) {
    // For Android 13+ (API level 33+), we need to request the POST_NOTIFICATIONS permission
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val activity = activity
      if (activity != null) {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS)
          != PackageManager.PERMISSION_GRANTED) {

          // Store the result to respond after permission request
          pendingPermissionResult = result

          // Request the permission
          ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATION_PERMISSION
          )
        } else {
          // Permission already granted
          result.success(true)
        }
      } else {
        // No activity available
        result.error("NO_ACTIVITY", "No activity available to request permission", null)
      }
    } else {
      // Permission not needed for Android < 13
      result.success(true)
    }
  }

  /**
   * Check if notification permission is granted
   */
  private fun checkNotificationPermission(result: Result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val granted = (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
        == PackageManager.PERMISSION_GRANTED)
      result.success(granted)
    } else {
      // Permission not needed for Android < 13
      result.success(true)
    }
  }

  /**
   * Show a simple notification
   */
  private fun showNotification(
    id: Int?,
    title: String,
    message: String,
    channelId: String?,
    priority: Int,
    autoCancel: Boolean,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)

      // Create intent for notification tap action if targetScreen is provided
      val intent = getTargetIntent(targetScreen, extraData)

      val notificationId = notificationHelper.showNotification(
        title,
        message,
        channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
        intent,
        priority,
        autoCancel,
        id
      )
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Show a notification with big text style
   */
  private fun showBigTextNotification(
    title: String,
    message: String,
    bigText: String,
    channelId: String?,
    priority: Int,
    autoCancel: Boolean,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)

      // Create intent for notification tap action if targetScreen is provided
      val intent = getTargetIntent(targetScreen, extraData)

      val notificationId = notificationHelper.showBigTextNotification(
        title,
        message,
        bigText,
        channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
        intent,
        priority,
        autoCancel
      )
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing big text notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Show a notification with an image
   */
  private fun showImageNotification(
    title: String,
    message: String,
    imageUrl: String,
    channelId: String?,
    priority: Int,
    autoCancel: Boolean,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)

      // Create intent for notification tap action if targetScreen is provided
      val intent = getTargetIntent(targetScreen, extraData)

      val notificationId = notificationHelper.showImageNotification(
        title,
        message,
        imageUrl,
        channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
        intent,
        priority,
        autoCancel
      )
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing image notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Show a notification with custom actions
   */
  private fun showNotificationWithActions(
    title: String,
    message: String,
    channelId: String?,
    actions: List<Map<String, String>>,
    priority: Int,
    autoCancel: Boolean,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)

      // Create intent for notification tap action if targetScreen is provided
      val contentIntent = getTargetIntent(targetScreen, extraData)

      // Convert actions to pairs of title and intent
      val actionPairs = actions.mapNotNull { actionMap ->
        val actionTitle = actionMap["title"]
        val actionRoute = actionMap["route"]

        if (actionTitle != null && actionRoute != null) {
          // Create an intent for the action
          val actionIntent = getTargetIntent(actionRoute, null)

          if (actionIntent != null) {
            Pair(actionTitle, actionIntent)
          } else {
            null
          }
        } else {
          null
        }
      }

      if (actionPairs.isEmpty()) {
        result.error("INVALID_ACTIONS", "No valid actions provided", null)
        return
      }

      val notificationId = notificationHelper.showNotificationWithActions(
        title,
        message,
        channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
        contentIntent,
        actionPairs,
        priority,
        autoCancel
      )
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing notification with actions", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Create a custom notification channel
   */
  private fun createCustomChannel(
    channelId: String,
    channelName: String,
    channelDescription: String,
    importance: Int,
    enableLights: Boolean,
    lightColor: Int,
    enableVibration: Boolean,
    enableSound: Boolean,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)
      notificationHelper.createCustomChannel(
        channelId,
        channelName,
        channelDescription,
        importance,
        enableLights,
        lightColor,
        enableVibration,
        enableSound
      )
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error creating custom channel", e)
      result.error("CHANNEL_ERROR", e.message, null)
    }
  }

  /**
   * Start WorkManager polling for remote HTTP notifications.
   *
   * This is a **separate** remote-delivery path from local notifications
   * ([showNotification], [scheduleNotification]). It is never started
   * automatically by local alarms — only when the host app calls this method
   * and no other remote service should remain active (they are mutually exclusive).
   */
  private fun startNotificationPolling(
    pollingUrl: String?,
    intervalMinutes: Int,
    result: Result
  ) {
    if (pollingUrl.isNullOrEmpty()) {
      result.error("INVALID_URL", "Polling URL cannot be null or empty", null)
      return
    }

    try {
      // Mutually exclusive with foreground / firebase remote delivery
      setActiveNotificationService(NOTIFICATION_SERVICE_POLLING)

      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, true)
        putString(PREF_POLLING_URL, pollingUrl)
        putInt(PREF_POLLING_INTERVAL_MINUTES, intervalMinutes)
        apply()
      }

      NotificationPollingWorker.schedulePolling(
        context,
        pollingUrl,
        intervalMinutes,
        ExistingPeriodicWorkPolicy.UPDATE
      )

      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error starting notification polling", e)
      result.error("POLLING_ERROR", e.message, null)
    }
  }

  /**
   * Stop polling for notifications
   */
  private fun stopNotificationPolling(result: Result) {
    try {
      // Update shared preferences
      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, false)
        putInt(PREF_ACTIVE_NOTIFICATION_SERVICE, NOTIFICATION_SERVICE_NONE)
        apply()
      }

      // Cancel the polling worker
      NotificationPollingWorker.cancelPolling(context)

      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error stopping notification polling", e)
      result.error("POLLING_ERROR", e.message, null)
    }
  }

  /**
   * Start the foreground service for continuous HTTP polling.
   *
   * Separate from local notifications/alarms. Only one of
   * polling | foreground | firebase may be active at a time.
   * Local [scheduleNotification] never starts this service.
   */
  private fun startForegroundService(
    pollingUrl: String?,
    intervalMinutes: Int,
    channelId: String?,
    result: Result
  ) {
    if (pollingUrl.isNullOrEmpty()) {
      result.error("INVALID_URL", "Polling URL cannot be null or empty", null)
      return
    }

    try {
      setActiveNotificationService(NOTIFICATION_SERVICE_FOREGROUND)

      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, true)
        putString(PREF_POLLING_URL, pollingUrl)
        putInt(PREF_POLLING_INTERVAL_MINUTES, intervalMinutes)
        apply()
      }

      val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
        action = NotificationForegroundService.ACTION_START_SERVICE
        putExtra(NotificationForegroundService.EXTRA_POLLING_URL, pollingUrl)
        putExtra(NotificationForegroundService.EXTRA_INTERVAL_MINUTES, intervalMinutes.toLong())
        if (channelId != null) {
          putExtra(NotificationForegroundService.EXTRA_CHANNEL_ID, channelId)
        }
      }

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(serviceIntent)
      } else {
        context.startService(serviceIntent)
      }

      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error starting foreground service", e)
      result.error("SERVICE_ERROR", e.message, null)
    }
  }

  /**
   * Stop the foreground service
   */
  private fun stopForegroundService(result: Result) {
    try {
      // Update shared preferences
      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, false)
        putInt(PREF_ACTIVE_NOTIFICATION_SERVICE, NOTIFICATION_SERVICE_NONE)
        apply()
      }

      // Create intent to stop the foreground service
      val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
        action = NotificationForegroundService.ACTION_STOP_SERVICE
      }

      // Stop the foreground service
      context.startService(serviceIntent)

      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error stopping foreground service", e)
      result.error("SERVICE_ERROR", e.message, null)
    }
  }

  /**
   * Set Firebase Cloud Messaging as the active notification service
   */
  private fun setFirebaseAsActiveService(result: Result) {
    try {
      setActiveNotificationService(NOTIFICATION_SERVICE_FIREBASE)
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error setting Firebase as active service", e)
      result.error("SERVICE_ERROR", e.message, null)
    }
  }

  /**
   * Get the currently active notification service
   */
  private fun getActiveNotificationService(result: Result) {
    try {
      val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      val serviceType = prefs.getInt(PREF_ACTIVE_NOTIFICATION_SERVICE, NOTIFICATION_SERVICE_NONE)

      // Return the service type as a string for better readability in Dart
      val serviceTypeString = when (serviceType) {
        NOTIFICATION_SERVICE_NONE -> "none"
        NOTIFICATION_SERVICE_POLLING -> "polling"
        NOTIFICATION_SERVICE_FOREGROUND -> "foreground"
        NOTIFICATION_SERVICE_FIREBASE -> "firebase"
        else -> "unknown"
      }

      result.success(serviceTypeString)
    } catch (e: Exception) {
      Log.e(TAG, "Error getting active notification service", e)
      result.error("SERVICE_ERROR", e.message, null)
    }
  }

  /**
   * Show a heads-up notification with custom styling
   */
  private fun showHeadsUpNotification(
    title: String,
    message: String,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val customNotificationHelper = CustomNotificationHelper(context)
      val intent = getTargetIntent(targetScreen, extraData)
      
      val notificationId = customNotificationHelper.showCustomLayoutNotification(
        title,
        message,
        intent
      )
      
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing heads-up notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Show a full screen notification
   */
  private fun showFullScreenNotification(
    title: String,
    message: String,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val customNotificationHelper = CustomNotificationHelper(context)
      val intent = getTargetIntent(targetScreen, extraData)
      
      val notificationId = customNotificationHelper.showFullScreenNotification(
        title,
        message,
        intent
      )
      
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing full screen notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Show a styled notification (like in the image with app icon)
   */
  private fun showStyledNotification(
    title: String,
    message: String,
    channelId: String?,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      val notificationHelper = NotificationHelper(context)
      val intent = getTargetIntent(targetScreen, extraData)
      
      val notificationId = notificationHelper.showStyledNotification(
        title,
        message,
        channelId ?: NotificationHelper.DEFAULT_CHANNEL_ID,
        intent,
        NotificationCompat.PRIORITY_HIGH,
        true
      )
      
      result.success(notificationId)
    } catch (e: Exception) {
      Log.e(TAG, "Error showing styled notification", e)
      result.error("NOTIFICATION_ERROR", e.message, null)
    }
  }

  /**
   * Schedule a **local** notification via AlarmManager (Windows Alarm Time style).
   *
   * This path is independent of polling / foreground / Firebase services.
   * It never starts or stops those services.
   */
  private fun scheduleNotification(
    id: Int,
    title: String,
    message: String,
    scheduledEpochMillis: Long,
    channelId: String?,
    priority: Int,
    alarmSound: Boolean,
    targetScreen: String?,
    extraData: Map<String, Any>?,
    result: Result
  ) {
    try {
      // Ensure default + alarm channels exist
      NotificationHelper(context)

      val effectiveChannelId = channelId ?: if (alarmSound) {
        NotificationHelper.ALARM_CHANNEL_ID
      } else {
        NotificationHelper.DEFAULT_CHANNEL_ID
      }
      val effectivePriority = if (alarmSound) {
        NotificationCompat.PRIORITY_MAX
      } else {
        priority
      }

      val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager

      val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
        action = ScheduledNotificationReceiver.ACTION_SCHEDULED
        putExtra(ScheduledNotificationReceiver.EXTRA_ID, id)
        putExtra(ScheduledNotificationReceiver.EXTRA_TITLE, title)
        putExtra(ScheduledNotificationReceiver.EXTRA_MESSAGE, message)
        putExtra(ScheduledNotificationReceiver.EXTRA_CHANNEL_ID, effectiveChannelId)
        putExtra(ScheduledNotificationReceiver.EXTRA_PRIORITY, effectivePriority)
        putExtra(ScheduledNotificationReceiver.EXTRA_TARGET_SCREEN, targetScreen)
        putExtra(
          ScheduledNotificationReceiver.EXTRA_EXTRA_DATA,
          mapToJson(extraData)
        )
        putExtra(ScheduledNotificationReceiver.EXTRA_ALARM_SOUND, alarmSound)
      }

      val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        android.app.PendingIntent.FLAG_IMMUTABLE or
          android.app.PendingIntent.FLAG_UPDATE_CURRENT
      } else {
        android.app.PendingIntent.FLAG_UPDATE_CURRENT
      }
      val pendingIntent = android.app.PendingIntent.getBroadcast(
        context, id, intent, flags
      )

      val triggerAt = if (scheduledEpochMillis > 0) scheduledEpochMillis else 0L

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        !alarmManager.canScheduleExactAlarms()
      ) {
        Log.w(TAG, "SCHEDULE_EXACT_ALARM not granted — cannot schedule exact alarm id=$id")
        result.error(
          "EXACT_ALARM_PERMISSION_DENIED",
          "Exact alarm permission not granted. Call openExactAlarmSettings() or direct the user to " +
            "Settings → Apps → ${context.packageName} → Special app access → Alarms & reminders.",
          null
        )
        return
      } else {
        alarmManager.setExactAndAllowWhileIdle(
          android.app.AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent
        )
      }

      ScheduledNotificationStore.save(
        context,
        ScheduledItem(
          id = id,
          title = title,
          message = message,
          channelId = effectiveChannelId,
          priority = effectivePriority,
          targetScreen = targetScreen,
          extraDataJson = mapToJson(extraData),
          triggerAtMillis = triggerAt,
          alarmSound = alarmSound
        )
      )

      // Local schedule only — do NOT touch remote delivery services
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error scheduling notification", e)
      result.error("SCHEDULE_ERROR", e.message, null)
    }
  }

  /** Whether the app can schedule exact alarms (Android 12+). Always true below API 31. */
  private fun canScheduleExactAlarms(result: Result) {
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val alarmManager =
          context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        result.success(alarmManager.canScheduleExactAlarms())
      } else {
        result.success(true)
      }
    } catch (e: Exception) {
      result.error("ALARM_CHECK_ERROR", e.message, null)
    }
  }

  /**
   * Opens system Settings so the user can grant "Alarms & reminders"
   * (SCHEDULE_EXACT_ALARM). Manual user action only — never auto-granted.
   */
  private fun openExactAlarmSettings(result: Result) {
    try {
      val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
          data = android.net.Uri.parse("package:${context.packageName}")
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      } else {
        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
          data = android.net.Uri.parse("package:${context.packageName}")
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      }
      context.startActivity(intent)
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error opening exact alarm settings", e)
      result.error("SETTINGS_ERROR", e.message, null)
    }
  }

  /**
   * Opens app notification settings so the user can enable notifications /
   * full-screen intents / channels. Manual user action only.
   */
  private fun openAppNotificationSettings(result: Result) {
    try {
      val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
          putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      } else {
        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
          data = android.net.Uri.parse("package:${context.packageName}")
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      }
      context.startActivity(intent)
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error opening notification settings", e)
      result.error("SETTINGS_ERROR", e.message, null)
    }
  }

  /**
   * Cancel a previously scheduled notification by id.
   */
  private fun cancelScheduledNotification(id: Int, result: Result) {
    try {
      val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager

      val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
        action = ScheduledNotificationReceiver.ACTION_SCHEDULED
        putExtra(ScheduledNotificationReceiver.EXTRA_ID, id)
      }

      val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        android.app.PendingIntent.FLAG_IMMUTABLE or
          android.app.PendingIntent.FLAG_NO_CREATE
      } else {
        android.app.PendingIntent.FLAG_NO_CREATE
      }
      val pendingIntent = android.app.PendingIntent.getBroadcast(
        context, id, intent, flags
      )
      if (pendingIntent != null) {
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
      }

      ScheduledNotificationStore.remove(context, id)
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error cancelling scheduled notification", e)
      result.error("SCHEDULE_ERROR", e.message, null)
    }
  }

  /**
   * Cancel all notifications scheduled with [scheduleNotification].
   */
  private fun cancelAllScheduledNotifications(result: Result) {
    try {
      val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager

      for (item in ScheduledNotificationStore.all(context)) {
        val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
          action = ScheduledNotificationReceiver.ACTION_SCHEDULED
          putExtra(ScheduledNotificationReceiver.EXTRA_ID, item.id)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          android.app.PendingIntent.FLAG_IMMUTABLE or
            android.app.PendingIntent.FLAG_NO_CREATE
        } else {
          android.app.PendingIntent.FLAG_NO_CREATE
        }
        val pendingIntent = android.app.PendingIntent.getBroadcast(
          context, item.id, intent, flags
        )
        if (pendingIntent != null) {
          alarmManager.cancel(pendingIntent)
          pendingIntent.cancel()
        }
      }

      ScheduledNotificationStore.removeAll(context)
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error cancelling all scheduled notifications", e)
      result.error("SCHEDULE_ERROR", e.message, null)
    }
  }

  /**
   * Return the ids of notifications scheduled with [scheduleNotification].
   */
  private fun getPendingScheduledNotifications(result: Result) {
    try {
      val ids = ScheduledNotificationStore.all(context).map { it.id }
      result.success(ids)
    } catch (e: Exception) {
      Log.e(TAG, "Error getting pending scheduled notifications", e)
      result.error("SCHEDULE_ERROR", e.message, null)
    }
  }

  /** Convert a Dart [Map] to a JSON string for persistence. */
  private fun mapToJson(map: Map<String, Any>?): String? {
    if (map == null) return null
    return try {
      val obj = JSONObject()
      for ((k, v) in map) {
        obj.put(k, v)
      }
      obj.toString()
    } catch (e: Exception) {
      null
    }
  }

  /**
   * Switch the **remote-delivery** service (polling | foreground | firebase | none).
   *
   * Local notifications and AlarmManager schedules are **not** managed here and
   * keep working regardless of which remote service is active.
   *
   * At most one remote service is active: starting one stops the previous.
   */
  private fun setActiveNotificationService(serviceType: Int) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val currentService = prefs.getInt(PREF_ACTIVE_NOTIFICATION_SERVICE, NOTIFICATION_SERVICE_NONE)

    if (currentService == serviceType) {
      return
    }

    when (currentService) {
      NOTIFICATION_SERVICE_POLLING -> {
        NotificationPollingWorker.cancelPolling(context)
        Log.d(TAG, "Stopped WorkManager polling (service switch)")
      }
      NOTIFICATION_SERVICE_FOREGROUND -> {
        val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
          action = NotificationForegroundService.ACTION_STOP_SERVICE
        }
        try {
          context.startService(serviceIntent)
        } catch (e: Exception) {
          Log.w(TAG, "Could not stop foreground service: ${e.message}")
        }
        Log.d(TAG, "Stopped foreground service (service switch)")
      }
      // Firebase is external — host app owns its lifecycle
    }

    // Clear polling-enabled when leaving polling/foreground
    val enablePolling = serviceType == NOTIFICATION_SERVICE_POLLING ||
      serviceType == NOTIFICATION_SERVICE_FOREGROUND

    prefs.edit().apply {
      putInt(PREF_ACTIVE_NOTIFICATION_SERVICE, serviceType)
      if (!enablePolling && serviceType != NOTIFICATION_SERVICE_NONE) {
        // firebase: remote push, not our HTTP poller
        putBoolean(PREF_POLLING_ENABLED, false)
      }
      if (serviceType == NOTIFICATION_SERVICE_NONE) {
        putBoolean(PREF_POLLING_ENABLED, false)
      }
      apply()
    }

    Log.d(TAG, "Active remote notification service → $serviceType")
  }

  private fun getTargetIntent(targetScreen: String?, extraData: Map<String, Any>?): Intent? {
    if (targetScreen == null) return null

    val intent = if (activity != null) {
      Intent(context, activity!!.javaClass)
    } else {
      context.packageManager.getLaunchIntentForPackage(context.packageName)
    }

    return intent?.apply {
      action = Intent.ACTION_VIEW
      putExtra("route", targetScreen)
      flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP

      if (extraData != null) {
        putExtra("extra_data", extraData.toString())
      }
    }
  }

  // ── helper: show a local confirmation notification ───────────────────────
  private fun showConfirmationNotification(title: String, message: String) {
    try {
      val helper = NotificationHelper(context)
      helper.showNotification(
        title = title,
        message = message,
        channelId = NotificationHelper.DEFAULT_CHANNEL_ID,
        intent = null,
        priority = androidx.core.app.NotificationCompat.PRIORITY_DEFAULT,
        autoCancel = true
      )
    } catch (e: Exception) {
      Log.w(TAG, "Could not show confirmation notification: ${e.message}")
    }
  }

  /**
   * Get the device token for push notifications.
   * Tries Firebase Messaging first, falls back to ANDROID_ID.
   * On success shows a local notification with the token source.
   */
  private fun getDeviceToken(result: Result) {
    try {
      val firebaseMessagingClass = Class.forName("com.google.firebase.messaging.FirebaseMessaging")
      val getInstance = firebaseMessagingClass.getMethod("getInstance")
      val messaging = getInstance.invoke(null)
      val getToken = messaging.javaClass.getMethod("getToken")
      val task = getToken.invoke(messaging)

      val addOnCompleteListener = task.javaClass.getMethod(
        "addOnCompleteListener",
        Class.forName("com.google.android.gms.tasks.OnCompleteListener")
      )
      val listenerProxy = java.lang.reflect.Proxy.newProxyInstance(
        Class.forName("com.google.android.gms.tasks.OnCompleteListener").classLoader,
        arrayOf(Class.forName("com.google.android.gms.tasks.OnCompleteListener"))
      ) { _, method, args ->
        if (method.name == "onComplete") {
          val token = args[0]?.javaClass?.getMethod("getResult")?.invoke(args[0])
          val exception = args[0]?.javaClass?.getMethod("getException")?.invoke(args[0])
          if (exception == null) {
            val tokenStr = token as? String
            showConfirmationNotification(
              "Device Token (FCM)",
              "Token: ${tokenStr?.take(24)}…"
            )
            result.success(tokenStr)
          } else {
            result.error("TOKEN_ERROR", "Failed to get FCM token: $exception", null)
          }
        }
        null
      }
      addOnCompleteListener.invoke(task, listenerProxy)

    } catch (e: ClassNotFoundException) {
      val deviceId = android.provider.Settings.Secure.getString(
        context.contentResolver, android.provider.Settings.Secure.ANDROID_ID
      )
      showConfirmationNotification(
        "Device Token (Android ID)",
        "Token: ${deviceId.take(24)}…"
      )
      result.success(deviceId)
    } catch (e: Exception) {
      Log.e(TAG, "Error getting device token", e)
      val deviceId = android.provider.Settings.Secure.getString(
        context.contentResolver, android.provider.Settings.Secure.ANDROID_ID
      )
      showConfirmationNotification(
        "Device Token (Fallback)",
        "Token: ${deviceId.take(24)}…"
      )
      result.success(deviceId)
    }
  }

  /**
   * Subscribe to a Firebase Cloud Messaging topic.
   * On success shows a local notification confirming the subscription.
   */
  private fun subscribeToTopic(topic: String, result: Result) {
    try {
      val firebaseMessagingClass = Class.forName("com.google.firebase.messaging.FirebaseMessaging")
      val getInstance = firebaseMessagingClass.getMethod("getInstance")
      val messaging = getInstance.invoke(null)
      val subscribeToTopic = messaging.javaClass.getMethod("subscribeToTopic", String::class.java)
      val task = subscribeToTopic.invoke(messaging, topic)

      val addOnCompleteListener = task.javaClass.getMethod(
        "addOnCompleteListener",
        Class.forName("com.google.android.gms.tasks.OnCompleteListener")
      )
      val listenerProxy = java.lang.reflect.Proxy.newProxyInstance(
        Class.forName("com.google.android.gms.tasks.OnCompleteListener").classLoader,
        arrayOf(Class.forName("com.google.android.gms.tasks.OnCompleteListener"))
      ) { _, method, args ->
        if (method.name == "onComplete") {
          val exception = args[0]?.javaClass?.getMethod("getException")?.invoke(args[0])
          if (exception == null) {
            saveTopicLocally(topic)
            showConfirmationNotification(
              "Subscribed (FCM)",
              "You are now subscribed to topic: $topic"
            )
            Log.d(TAG, "Subscribed to FCM topic: $topic")
            result.success(true)
          } else {
            result.error("SUBSCRIBE_ERROR", "Failed to subscribe: $exception", null)
          }
        }
        null
      }
      addOnCompleteListener.invoke(task, listenerProxy)

    } catch (e: ClassNotFoundException) {
      saveTopicLocally(topic)
      showConfirmationNotification(
        "Subscribed (Local)",
        "Subscribed to topic: $topic (Firebase not available)"
      )
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error subscribing to topic", e)
      saveTopicLocally(topic)
      showConfirmationNotification(
        "Subscribed (Local)",
        "Subscribed to topic: $topic"
      )
      result.success(true)
    }
  }

  /**
   * Unsubscribe from a Firebase Cloud Messaging topic.
   * On success shows a local notification confirming the removal.
   */
  private fun unsubscribeFromTopic(topic: String, result: Result) {
    try {
      val firebaseMessagingClass = Class.forName("com.google.firebase.messaging.FirebaseMessaging")
      val getInstance = firebaseMessagingClass.getMethod("getInstance")
      val messaging = getInstance.invoke(null)
      val unsubscribeFromTopic = messaging.javaClass.getMethod("unsubscribeFromTopic", String::class.java)
      val task = unsubscribeFromTopic.invoke(messaging, topic)

      val addOnCompleteListener = task.javaClass.getMethod(
        "addOnCompleteListener",
        Class.forName("com.google.android.gms.tasks.OnCompleteListener")
      )
      val listenerProxy = java.lang.reflect.Proxy.newProxyInstance(
        Class.forName("com.google.android.gms.tasks.OnCompleteListener").classLoader,
        arrayOf(Class.forName("com.google.android.gms.tasks.OnCompleteListener"))
      ) { _, method, args ->
        if (method.name == "onComplete") {
          val exception = args[0]?.javaClass?.getMethod("getException")?.invoke(args[0])
          if (exception == null) {
            removeTopicLocally(topic)
            showConfirmationNotification(
              "Unsubscribed (FCM)",
              "You have unsubscribed from topic: $topic"
            )
            Log.d(TAG, "Unsubscribed from FCM topic: $topic")
            result.success(true)
          } else {
            result.error("UNSUBSCRIBE_ERROR", "Failed to unsubscribe: $exception", null)
          }
        }
        null
      }
      addOnCompleteListener.invoke(task, listenerProxy)

    } catch (e: ClassNotFoundException) {
      removeTopicLocally(topic)
      showConfirmationNotification(
        "Unsubscribed (Local)",
        "Unsubscribed from topic: $topic (Firebase not available)"
      )
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error unsubscribing from topic", e)
      removeTopicLocally(topic)
      showConfirmationNotification(
        "Unsubscribed (Local)",
        "Unsubscribed from topic: $topic"
      )
      result.success(true)
    }
  }

  /**
   * Get the list of locally subscribed topics.
   * This reflects Firebase subscriptions (when available) and local fallback subscriptions.
   */
  private fun getSubscribedTopics(result: Result) {
    try {
      val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      val topicsSet = prefs.getStringSet(PREF_SUBSCRIBED_TOPICS, emptySet()) ?: emptySet()
      result.success(topicsSet.toList())
    } catch (e: Exception) {
      Log.e(TAG, "Error getting subscribed topics", e)
      result.error("TOPICS_ERROR", e.message, null)
    }
  }

  /** Persist a topic subscription in SharedPreferences. */
  private fun saveTopicLocally(topic: String) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val topics = prefs.getStringSet(PREF_SUBSCRIBED_TOPICS, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
    topics.add(topic)
    prefs.edit().putStringSet(PREF_SUBSCRIBED_TOPICS, topics).apply()
  }

  /** Remove a topic subscription from SharedPreferences. */
  private fun removeTopicLocally(topic: String) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val topics = prefs.getStringSet(PREF_SUBSCRIBED_TOPICS, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
    topics.remove(topic)
    prefs.edit().putStringSet(PREF_SUBSCRIBED_TOPICS, topics).apply()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == REQUEST_NOTIFICATION_PERMISSION) {
      val granted = grantResults.isNotEmpty() &&
        grantResults[0] == PackageManager.PERMISSION_GRANTED

      pendingPermissionResult?.success(granted)
      pendingPermissionResult = null

      return true
    }

    return false
  }
}
