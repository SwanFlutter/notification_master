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
   * Start polling for notifications from a remote server
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
      // Disable any other active notification service
      setActiveNotificationService(NOTIFICATION_SERVICE_POLLING)

      // Save polling settings to shared preferences
      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, true)
        putString(PREF_POLLING_URL, pollingUrl)
        putInt(PREF_POLLING_INTERVAL_MINUTES, intervalMinutes)
        apply()
      }

      // Schedule the polling worker
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
   * Start the foreground service for continuous notification polling
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
      // Disable any other active notification service
      setActiveNotificationService(NOTIFICATION_SERVICE_FOREGROUND)

      // Save polling settings to shared preferences
      context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
        putBoolean(PREF_POLLING_ENABLED, true)
        putString(PREF_POLLING_URL, pollingUrl)
        putInt(PREF_POLLING_INTERVAL_MINUTES, intervalMinutes)
        apply()
      }

      // Create intent to start the foreground service
      val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
        action = NotificationForegroundService.ACTION_START_SERVICE
        putExtra(NotificationForegroundService.EXTRA_POLLING_URL, pollingUrl)
        putExtra(NotificationForegroundService.EXTRA_INTERVAL_MINUTES, intervalMinutes.toLong())
        if (channelId != null) {
          putExtra(NotificationForegroundService.EXTRA_CHANNEL_ID, channelId)
        }
      }

      // Start the foreground service
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
   * Set the active notification service and disable other services
   */
  private fun setActiveNotificationService(serviceType: Int) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val currentService = prefs.getInt(PREF_ACTIVE_NOTIFICATION_SERVICE, NOTIFICATION_SERVICE_NONE)

    // If the same service is already active, do nothing
    if (currentService == serviceType) {
      return
    }

    // Disable the current active service
    when (currentService) {
      NOTIFICATION_SERVICE_POLLING -> {
        NotificationPollingWorker.cancelPolling(context)
        Log.d(TAG, "Disabled polling service due to service change")
      }
      NOTIFICATION_SERVICE_FOREGROUND -> {
        val serviceIntent = Intent(context, NotificationForegroundService::class.java).apply {
          action = NotificationForegroundService.ACTION_STOP_SERVICE
        }
        context.startService(serviceIntent)
        Log.d(TAG, "Disabled foreground service due to service change")
      }
      // Firebase doesn't need to be disabled as it's managed externally
    }

    // Save the new active service
    prefs.edit().apply {
      putInt(PREF_ACTIVE_NOTIFICATION_SERVICE, serviceType)
      apply()
    }

    Log.d(TAG, "Active notification service changed to: $serviceType")
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
