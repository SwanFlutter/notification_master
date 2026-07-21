import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:notification_master/notification_master.dart';

class SimplePollingPage extends StatefulWidget {
  const SimplePollingPage({super.key});

  @override
  State<SimplePollingPage> createState() => _SimplePollingPageState();
}

class _SimplePollingPageState extends State<SimplePollingPage> {
  final NotificationMaster _notificationMaster = NotificationMaster();
  bool _isPollingActive = false;
  bool _isForegroundActive = false;
  bool _isDaemonActive = false;
  String _statusMessage = 'Notification service is not active';

  // ── Debug log ──────────────────────────────────────────────────────────────
  final List<_LogEntry> _logs = [];
  bool _showDebugPanel = true;
  final ScrollController _logScroll = ScrollController();

  void _log(String msg, {_LogLevel level = _LogLevel.info}) {
    final entry = _LogEntry(time: TimeOfDay.now(), message: msg, level: level);

    // Print to console in real-time
    final levelPrefix = _getLevelPrefix(level);
    final timestamp = DateTime.now().toString().split('.')[0];
    debugPrint('[$timestamp] $levelPrefix $msg');

    setState(() => _logs.add(entry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getLevelPrefix(_LogLevel level) {
    switch (level) {
      case _LogLevel.ok:
        return '✅';
      case _LogLevel.error:
        return '❌';
      case _LogLevel.warning:
        return '⚠️ ';
      case _LogLevel.info:
        return 'ℹ️ ';
    }
  }

  // Default polling URL - using a mock API that always returns a valid response
  final String _pollingUrl =
      'http://192.168.1.105/php_polling_server/notifications.php';

  // Default polling interval in minutes
  final int _intervalMinutes = 1;

  @override
  void initState() {
    super.initState();
    _log('App started — polling URL: $_pollingUrl');
    _log('Interval: $_intervalMinutes minute(s)');
    _checkServiceStatus();
    _checkDaemonStatus();
    _createNotificationChannels();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    // Listen for notification taps
    _notificationMaster.onNotificationTap.listen((event) {
      _log(
        '🔔 Notification tapped! Route: ${event['targetScreen'] ?? "none"}',
        level: _LogLevel.ok,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification tapped → ${event['targetScreen'] ?? "none"}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Listen for action taps
    _notificationMaster.onActionTap.listen((event) {
      _log(
        '⚡ Action tapped! Route: ${event['route'] ?? event['targetScreen'] ?? "none"}',
        level: _LogLevel.ok,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action tapped → ${event['route'] ?? event['targetScreen'] ?? "none"}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  // ── Test Connection ────────────────────────────────────────────────────────
  Future<void> _testConnection() async {
    _log('⏳ Testing connection to $_pollingUrl …');
    try {
      final resp = await http
          .get(Uri.parse(_pollingUrl))
          .timeout(const Duration(seconds: 10));

      _log(
        '✅ HTTP ${resp.statusCode} — body length: ${resp.body.length} bytes',
        level: resp.statusCode == 200 ? _LogLevel.ok : _LogLevel.error,
      );

      if (resp.body.isEmpty) {
        _log(
          '⚠️  Empty body — PHP returned nothing!',
          level: _LogLevel.warning,
        );
        return;
      }

      // Pretty-print the first 600 chars
      final preview = resp.body.length > 600
          ? '${resp.body.substring(0, 600)}…'
          : resp.body;
      _log('📄 Response:\n$preview');

      // Validate JSON structure
      try {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final notifications = json['notifications'] as List<dynamic>? ?? [];
        if (notifications.isEmpty) {
          _log(
            '⚠️  JSON valid but notifications[] is EMPTY.\n'
            '   → All rows in the DB may already be delivered (delivered_at IS NOT NULL).\n'
            '   → Run the SQL reset below to get new rows.',
            level: _LogLevel.warning,
          );
        } else {
          _log(
            '🔔 Found ${notifications.length} pending notification(s):',
            level: _LogLevel.ok,
          );
          for (final n in notifications) {
            _log(
              '   title: "${n['title']}"  message: "${n['message']}"',
              level: _LogLevel.ok,
            );
          }
          _log(
            '✅ Structure is correct — polling SHOULD show toasts.',
            level: _LogLevel.ok,
          );
        }
      } catch (e) {
        _log(
          '❌ JSON parse error: $e\n'
          '   Response is NOT valid JSON — check PHP for errors/warnings.',
          level: _LogLevel.error,
        );
      }
    } on Exception catch (e) {
      _log(
        '❌ Connection FAILED: $e\n'
        '   → Is XAMPP running?\n'
        '   → Is the IP correct? (try opening in browser first)\n'
        '   → Windows Firewall may be blocking port 80.',
        level: _LogLevel.error,
      );
    }
  }

  // Check if the standalone background poller daemon is running.
  Future<void> _checkDaemonStatus() async {
    try {
      final running = await _notificationMaster.isBackgroundPollingRunning();
      if (!mounted) return;
      _log('Daemon status: ${running ? "RUNNING ✅" : "stopped"}');
      setState(() {
        _isDaemonActive = running;
      });
    } on PlatformException catch (e) {
      // isBackgroundPollingRunning is Windows-only — treat as "not running"
      // on other platforms without logging a scary error.
      if (e.code == 'PLATFORM_NOT_SUPPORTED') {
        if (!mounted) return;
        setState(() => _isDaemonActive = false);
      } else {
        _log('Error checking daemon: ${e.message}', level: _LogLevel.error);
        if (!mounted) return;
        setState(() => _isDaemonActive = false);
      }
    } catch (e) {
      _log('Error checking daemon: $e', level: _LogLevel.error);
      if (!mounted) return;
      setState(() => _isDaemonActive = false);
    }
  }

  // Check if any notification service is active
  Future<void> _checkServiceStatus() async {
    try {
      final activeService = await _notificationMaster
          .getActiveNotificationService();
      _log('Active service: $activeService');
      setState(() {
        _isPollingActive = activeService == "polling";
        _isForegroundActive = activeService == "foreground";

        if (activeService == "none") {
          _statusMessage = 'Notification service is not active';
        } else if (activeService == "polling") {
          _statusMessage = 'Background polling is active';
        } else if (activeService == "foreground") {
          _statusMessage = 'Foreground service is active';
        } else if (activeService == "firebase") {
          _statusMessage = 'Firebase Cloud Messaging is active';
        } else {
          _statusMessage = 'Unknown service is active: $activeService';
        }

        // On Windows, polling/foreground run as the standalone background
        // poller daemon, so reflect that in the daemon toggle too.
        _isDaemonActive = activeService == "polling";
      });
    } catch (e) {
      _log('Error checking service: $e', level: _LogLevel.error);
      setState(() {
        _isPollingActive = false;
        _isForegroundActive = false;
        _statusMessage = 'Error checking service status: $e';
      });
    }
  }

  // Create notification channels for different priorities
  Future<void> _createNotificationChannels() async {
    // High priority channel with sound
    await _notificationMaster.createCustomChannel(
      channelId: 'high_priority_channel',
      channelName: 'High Priority',
      channelDescription: 'Channel for important notifications',
      importance: NotificationImportance.high,
      enableLights: true,
      lightColor: 0xFFFF0000, // Red color
      enableVibration: true,
      enableSound: true,
    );

    // Default channel with sound
    await _notificationMaster.createCustomChannel(
      channelId: 'default_channel',
      channelName: 'Default Notifications',
      channelDescription: 'Channel for regular notifications',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFF00FF00, // Green color
      enableVibration: true,
      enableSound: true,
    );

    // Silent channel
    await _notificationMaster.createCustomChannel(
      channelId: 'silent_channel',
      channelName: 'Silent Notifications',
      channelDescription: 'Channel for silent notifications',
      importance: NotificationImportance.min,
      enableLights: false,
      enableVibration: false,
      enableSound: false,
    );
  }

  // Force an immediate HTTP poll (for testing) using the Flutter http package.
  Future<void> _forcePollNow() async {
    _log('🔄 Force polling $_pollingUrl …');
    try {
      final resp = await http
          .get(Uri.parse(_pollingUrl))
          .timeout(const Duration(seconds: 10));
      _log('HTTP ${resp.statusCode}');

      if (resp.statusCode != 200 || resp.body.isEmpty) {
        _log('⚠️  Bad response — check server.', level: _LogLevel.warning);
        return;
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final notifications = json['notifications'] as List<dynamic>? ?? [];

      if (notifications.isEmpty) {
        _log(
          '⚠️  notifications[] is empty — reset delivered_at in DB first.',
          level: _LogLevel.warning,
        );
        return;
      }

      _log(
        '📨 ${notifications.length} notification(s) received — showing via plugin…',
        level: _LogLevel.ok,
      );

      for (final n in notifications) {
        final title = n['title'] as String? ?? '';
        final message = n['message'] as String? ?? '';
        final bigText = n['bigText'] as String? ?? '';

        _log('  → "$title" / "$message"', level: _LogLevel.ok);

        if (bigText.isNotEmpty) {
          await _notificationMaster.showBigTextNotification(
            title: title,
            message: message,
            bigText: bigText,
            channelId: n['channelId'] as String? ?? 'high_priority_channel',
          );
        } else {
          await _notificationMaster.showNotification(
            title: title,
            message: message,
            channelId: n['channelId'] as String? ?? 'high_priority_channel',
          );
        }

        // Show in-app toast when app is in foreground
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
      _log('✅ Done — check Windows notification area.', level: _LogLevel.ok);
    } on Exception catch (e) {
      _log('❌ Force poll failed: $e', level: _LogLevel.error);
    }
  }

  // Read the background poller daemon's log file (next to the app .exe) and
  // print its tail into the on-screen debug panel. This is how you see what
  // notifications the daemon received from the server AFTER the app is closed.
  Future<void> _showDaemonLog() async {
    try {
      final exe = Platform.resolvedExecutable;
      final dir = File(exe).parent.path;
      final logPath =
          '$dir${Platform.pathSeparator}notification_master_poller.log';
      final file = File(logPath);
      if (!await file.exists()) {
        _log('⚠️  Daemon log not found at: $logPath', level: _LogLevel.warning);
        return;
      }
      final contents = await file.readAsString();
      final lines = contents.split('\n');
      final tail = lines.length > 60 ? lines.sublist(lines.length - 60) : lines;
      _log(
        '📜 Daemon log ($logPath) — last ${tail.length} lines:',
        level: _LogLevel.info,
      );
      for (final l in tail) {
        if (l.trim().isNotEmpty) _log(l.trim());
      }
    } catch (e) {
      _log('❌ Could not read daemon log: $e', level: _LogLevel.error);
    }
  }

  void _showResetSqlDialog() {
    const sql =
        'UPDATE notification_master.notifications\n'
        'SET delivered_at = NULL\n'
        'WHERE delivered_at IS NOT NULL;\n\n'
        '-- یا برای اضافه کردن یک ردیف جدید:\n'
        'INSERT INTO notification_master.notifications\n'
        '  (title, message, big_text, channel_id)\n'
        "VALUES\n"
        "  ('تست', 'پیام تست جدید', NULL, 'high_priority_channel');";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SQL برای بازنشانی دیتابیس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اگر نوتیفیکیشن نمی‌آید، احتمالاً همه ردیف‌ها قبلاً '
              'delivered شده‌اند.\nاین SQL را در phpMyAdmin اجرا کنید:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                sql,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sql));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SQL copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy SQL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show a test notification with navigation
  Future<void> _showTestNotification() async {
    await _notificationMaster.showBigTextNotification(
      title: 'Test Notification',
      message: 'This notification will open the main page when tapped',
      bigText:
          'This is a test notification to demonstrate the navigation capability. When you tap this notification, it will open the main page of the app.',
      channelId: 'high_priority_channel',
      targetScreen: '/',
      extraData: {'source': 'test', 'timestamp': DateTime.now().toString()},
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test notification sent! Try tapping it when it appears.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Toggle background polling
  Future<void> _toggleBackgroundPolling() async {
    if (_isPollingActive) {
      await _stopBackgroundPolling();
    } else {
      await _startBackgroundPolling();
    }
  }

  // Start background polling
  Future<void> _startBackgroundPolling() async {
    _log('Starting background polling …');
    // Check permission
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    _log('Notification permission: $hasPermission');
    if (!hasPermission) {
      if (!mounted) return;

      // Request permission if not granted
      final granted = await _notificationMaster.requestNotificationPermission();
      _log(
        'Permission request result: $granted',
        level: granted ? _LogLevel.ok : _LogLevel.error,
      );
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission not granted')),
        );
        return;
      }
    }

    // Start polling
    _log(
      'Calling startNotificationPolling(url=$_pollingUrl, interval=$_intervalMinutes)',
    );
    final success = await _notificationMaster.startNotificationPolling(
      pollingUrl: _pollingUrl,
      intervalMinutes: _intervalMinutes,
    );
    _log(
      'startNotificationPolling result: $success',
      level: success ? _LogLevel.ok : _LogLevel.error,
    );
    if (!success) {
      _log(
        '⚠️  On Windows this polls in-process (app must stay open).',
        level: _LogLevel.warning,
      );
    } else {
      _log(
        '✅ Polling started. First check happens NOW, then every $_intervalMinutes min.',
        level: _LogLevel.ok,
      );
    }

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Background polling started! Note: This may stop when the app is closed.',
          ),
          action: SnackBarAction(
            label: 'Use Foreground Service Instead',
            onPressed: () {
              _stopBackgroundPolling().then((_) => _startForegroundService());
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start notification polling')),
      );
    }
  }

  // Stop background polling
  Future<void> _stopBackgroundPolling() async {
    _log('Stopping background polling …');
    final success = await _notificationMaster.stopNotificationPolling();
    _log(
      'stopNotificationPolling result: $success',
      level: success ? _LogLevel.ok : _LogLevel.error,
    );

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background polling stopped!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop notification polling')),
      );
    }
  }

  // Toggle foreground service
  Future<void> _toggleForegroundService() async {
    if (_isForegroundActive) {
      await _stopForegroundService();
    } else {
      await _startForegroundService();
    }
  }

  // Start foreground service
  Future<void> _startForegroundService() async {
    try {
      _log('Starting foreground service …');

      // Check permission
      final hasPermission = await _notificationMaster
          .checkNotificationPermission();
      _log('Notification permission: $hasPermission');

      if (!hasPermission) {
        if (!mounted) return;

        // Request permission if not granted
        _log('Requesting notification permission …');
        final granted = await _notificationMaster
            .requestNotificationPermission();
        if (!granted) {
          if (!mounted) return;
          _log(
            'Notification permission denied by user',
            level: _LogLevel.warning,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission not granted'),
            ),
          );
          return;
        }
        _log('Notification permission granted ✅');
      }

      _log(
        'Calling startForegroundService(url=$_pollingUrl, interval=$_intervalMinutes)',
      );

      // Start foreground service with default channel parameters
      final success = await _notificationMaster.startForegroundService(
        pollingUrl: _pollingUrl,
        intervalMinutes: _intervalMinutes,
        channelId: 'high_priority_channel',
        channelName: 'High Priority',
        channelDescription: 'Channel for important notifications',
        importance: NotificationImportance.high,
        enableLights: true,
        lightColor: 0xFFFF0000, // Red color
        enableVibration: true,
        enableSound: true,
      );

      _log(
        'startForegroundService result: $success',
        level: success ? _LogLevel.ok : _LogLevel.error,
      );

      if (success) {
        _log(
          '✅ On Windows: foreground = same in-process polling thread.',
          level: _LogLevel.ok,
        );
      }

      if (!mounted) return;

      if (success) {
        _checkServiceStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foreground service started (daemon). Notifications keep arriving even after the app is closed.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start foreground service')),
        );
      }
    } catch (e, stackTrace) {
      _log(
        '❌ CRASH in _startForegroundService:\n$e\n\nStack:\n$stackTrace',
        level: _LogLevel.error,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting service: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Stop foreground service
  Future<void> _stopForegroundService() async {
    try {
      _log('Stopping foreground service …');
      final success = await _notificationMaster.stopForegroundService();
      _log(
        'stopForegroundService result: $success',
        level: success ? _LogLevel.ok : _LogLevel.error,
      );

      if (!mounted) return;

      if (success) {
        _checkServiceStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foreground service stopped!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to stop foreground service')),
        );
      }
    } catch (e, stackTrace) {
      _log(
        '❌ CRASH in _stopForegroundService:\n$e\n\nStack:\n$stackTrace',
        level: _LogLevel.error,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping service: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Toggle the standalone background poller daemon.
  Future<void> _toggleDaemon() async {
    if (_isDaemonActive) {
      await _stopDaemon();
    } else {
      await _startDaemon();
    }
  }

  // Start the standalone background poller (own process, survives app close).
  Future<void> _startDaemon() async {
    try {
      _log('Starting background poller daemon …');
      final hasPermission = await _notificationMaster
          .checkNotificationPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final granted = await _notificationMaster
            .requestNotificationPermission();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission not granted'),
            ),
          );
          return;
        }
      }

      _log(
        'Calling startBackgroundPollingService(url=$_pollingUrl, interval=$_intervalMinutes)',
      );
      final success = await _notificationMaster.startBackgroundPollingService(
        pollingUrl: _pollingUrl,
        intervalMinutes: _intervalMinutes,
      );
      _log(
        'startBackgroundPollingService result: $success',
        level: success ? _LogLevel.ok : _LogLevel.error,
      );
      if (!success) {
        _log(
          '❌ Daemon launch FAILED.\n'
          '   → notification_master_poller.exe must be next to the app .exe\n'
          '   → Build the daemon target first (cmake --build)',
          level: _LogLevel.error,
        );
      } else {
        _log(
          '✅ Daemon started. Logs → notification_master_poller.log next to .exe',
          level: _LogLevel.ok,
        );
      }

      if (!mounted) return;

      await _checkDaemonStatus();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Background poller started! It keeps polling even after the app is closed. '
              'Logs are written next to the app .exe (notification_master_poller.log).',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start background poller. Make sure the app is built '
              '(daemon .exe must exist next to the app).',
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'PLATFORM_NOT_SUPPORTED') {
        _log(
          '⚠️  Background daemon is not supported on this platform.\n'
          '   On Android/iOS use "Start Background Polling" or "Start Foreground Service" instead.\n'
          '   Details: ${e.message}',
          level: _LogLevel.warning,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Background daemon is not supported on Android/iOS. '
                'Use Background Polling or Foreground Service on this platform.',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        _log(
          '❌ CRASH in _startDaemon: ${e.code} — ${e.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e, stackTrace) {
      _log(
        '❌ CRASH in _startDaemon:\n$e\n\nStack:\n$stackTrace',
        level: _LogLevel.error,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting daemon: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Stop the standalone background poller.
  Future<void> _stopDaemon() async {
    try {
      _log('Stopping background poller daemon …');
      final success = await _notificationMaster.stopBackgroundPollingService();
      _log(
        'stopBackgroundPollingService result: $success',
        level: success ? _LogLevel.ok : _LogLevel.error,
      );
      if (!mounted) return;
      await _checkDaemonStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Background poller stopped!'
                : 'Failed to stop background poller.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'PLATFORM_NOT_SUPPORTED') {
        _log(
          '⚠️  stopBackgroundPollingService: Windows-only feature.',
          level: _LogLevel.warning,
        );
      } else {
        _log(
          '❌ CRASH in _stopDaemon: ${e.code} — ${e.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e, stackTrace) {
      _log(
        '❌ CRASH in _stopDaemon:\n$e\n\nStack:\n$stackTrace',
        level: _LogLevel.error,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping daemon: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple HTTP Notification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to examples'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: _isForegroundActive
                        ? Colors.green.shade100
                        : _isPollingActive
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: _isForegroundActive
                          ? Colors.green.shade300
                          : _isPollingActive
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isForegroundActive
                                ? Icons.notifications_active
                                : _isPollingActive
                                ? Icons.notifications
                                : Icons.notifications_off,
                            color: _isForegroundActive
                                ? Colors.green.shade800
                                : _isPollingActive
                                ? Colors.blue.shade800
                                : Colors.grey.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isForegroundActive
                                ? 'Foreground Service Active'
                                : _isPollingActive
                                ? 'Background Polling Active'
                                : 'Notification Service Inactive',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isForegroundActive
                                  ? Colors.green.shade800
                                  : _isPollingActive
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isForegroundActive
                              ? Colors.green.shade800
                              : _isPollingActive
                              ? Colors.blue.shade800
                              : Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Background polling button
                ElevatedButton.icon(
                  onPressed: _toggleBackgroundPolling,
                  icon: Icon(
                    _isPollingActive ? Icons.stop : Icons.play_arrow,
                    color: _isPollingActive ? Colors.red : Colors.white,
                  ),
                  label: Text(
                    _isPollingActive
                        ? 'Stop Background Polling'
                        : 'Start Background Polling',
                    style: TextStyle(
                      color: _isPollingActive ? Colors.red : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPollingActive
                        ? Colors.white
                        : Colors.blue,
                    foregroundColor: _isPollingActive
                        ? Colors.red
                        : Colors.white,
                    side: _isPollingActive
                        ? const BorderSide(color: Colors.red)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 16),

                // Foreground service button
                ElevatedButton.icon(
                  onPressed: _toggleForegroundService,
                  icon: Icon(
                    _isForegroundActive ? Icons.stop : Icons.play_arrow,
                    color: _isForegroundActive ? Colors.red : Colors.white,
                  ),
                  label: Text(
                    _isForegroundActive
                        ? 'Stop Foreground Service'
                        : 'Start Foreground Service',
                    style: TextStyle(
                      color: _isForegroundActive ? Colors.red : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isForegroundActive
                        ? Colors.white
                        : Colors.green,
                    foregroundColor: _isForegroundActive
                        ? Colors.red
                        : Colors.white,
                    side: _isForegroundActive
                        ? const BorderSide(color: Colors.red)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 16),

                // Standalone background poller (daemon) button — keeps polling even
                // after the app is fully closed because it runs in its own process.
                ElevatedButton.icon(
                  onPressed: _toggleDaemon,
                  icon: Icon(
                    _isDaemonActive ? Icons.stop : Icons.cloud_download,
                    color: _isDaemonActive ? Colors.red : Colors.white,
                  ),
                  label: Text(
                    _isDaemonActive
                        ? 'Stop Background Poller (daemon)'
                        : 'Start Background Poller (daemon)',
                    style: TextStyle(
                      color: _isDaemonActive ? Colors.red : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDaemonActive
                        ? Colors.white
                        : Colors.deepPurple,
                    foregroundColor: _isDaemonActive
                        ? Colors.red
                        : Colors.white,
                    side: _isDaemonActive
                        ? const BorderSide(color: Colors.red)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Debug / Diagnostics section ──────────────────────────
                Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    const Text(
                      'Debug & Diagnostics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showDebugPanel = !_showDebugPanel),
                      icon: Icon(
                        _showDebugPanel ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_showDebugPanel ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Test connection button
                ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('🔍 Test PHP Server Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),

                // Force poll now button
                ElevatedButton.icon(
                  onPressed: _isPollingActive || _isForegroundActive
                      ? _forcePollNow
                      : null,
                  icon: const Icon(Icons.notifications_active),
                  label: Text(
                    _isPollingActive || _isForegroundActive
                        ? '🔔 Force Poll Now (test)'
                        : '🔔 Start a service first, then poll',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),

                // Show SQL reset dialog
                ElevatedButton.icon(
                  onPressed: () => _showResetSqlDialog(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('📋 Show SQL to reset delivered rows'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 8),

                // Print the daemon's background-poller log (what the server
                // returned while the app was closed) into the debug panel.
                ElevatedButton.icon(
                  onPressed: _showDaemonLog,
                  icon: const Icon(Icons.terminal),
                  label: const Text('🖨️ Print daemon log (server responses)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),

                if (_showDebugPanel) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepOrange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade800,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'LOG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => setState(() => _logs.clear()),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _logScroll,
                            padding: const EdgeInsets.all(8),
                            itemCount: _logs.length,
                            itemBuilder: (_, i) {
                              final e = _logs[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: SelectableText(
                                  '[${e.time.format(context)}] ${e.message}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: e.level == _LogLevel.error
                                        ? Colors.red.shade300
                                        : e.level == _LogLevel.warning
                                        ? Colors.yellow.shade300
                                        : e.level == _LogLevel.ok
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Information section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• On Windows, Linux, and macOS, polling runs in a background daemon so it keeps working after the app is closed.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Use "Background Poller (daemon)" or the polling/foreground buttons above — they all launch the daemon.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Foreground service shows a persistent notification',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Background Poller (daemon) is a separate process: keeps polling & toasting after the app is closed. Logs: notification_master_poller.log next to the .exe.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current server URL: $_pollingUrl',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Note: Using a mock API for testing. In a real app, you would use your own server.',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        'Polling interval: $_intervalMinutes minute(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showTestNotification,
                        icon: const Icon(Icons.notifications_active),
                        label: const Text(
                          'Send Test Notification with Navigation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Debug log helpers ──────────────────────────────────────────────────────

enum _LogLevel { info, ok, warning, error }

class _LogEntry {
  final TimeOfDay time;
  final String message;
  final _LogLevel level;
  _LogEntry({required this.time, required this.message, required this.level});
}
