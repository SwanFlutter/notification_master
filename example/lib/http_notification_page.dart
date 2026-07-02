import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notification_master/notification_master.dart';

class HttpNotificationPage extends StatefulWidget {
  const HttpNotificationPage({super.key});

  @override
  State<HttpNotificationPage> createState() => _HttpNotificationPageState();
}

class _HttpNotificationPageState extends State<HttpNotificationPage> {
  final _notificationMaster = NotificationMaster();
  // URL dropdown options
  final List<Map<String, String>> _urlOptions = [
    {
      'label': 'Local Server (Emulator)',
      'value': 'http://10.0.2.2/simple_notification_server.php',
    },
    {
      'label': 'Local Server (Device)',
      'value': 'http://192.168.1.106/simple_notification_server.php',
    },
    {
      'label': 'Local Server (Full Path)',
      'value':
          'http://192.168.1.106/example/server/simple_notification_server.php',
    },
  ];

  String _selectedUrl = 'http://10.0.2.2/simple_notification_server.php';
  final _urlController = TextEditingController(
    text:
        'http://10.0.2.2/simple_notification_server.php', // Default URL for Android emulator
  );
  final _intervalController = TextEditingController(
    text: '1',
  ); // Set to 1 minute for testing
  bool _isPolling = false;
  String _statusMessage = 'Polling is not active';

  @override
  void initState() {
    super.initState();
    _checkPollingStatus();
    _createNotificationChannels();
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

    // Media channel
    await _notificationMaster.createCustomChannel(
      channelId: 'media_channel',
      channelName: 'Media',
      channelDescription: 'Channel for media notifications',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFF0000FF, // Blue color
      enableVibration: false,
      enableSound: true,
    );

    // Add a test notification to the server if needed
    _addTestNotificationToServer();
  }

  // Add a test notification to the server
  Future<void> _addTestNotificationToServer() async {
    try {
      // Try to add a test notification to the server
      final testUrls = [
        'http://192.168.1.106/simple_notification_server.php',
        'http://192.168.1.106/simple_notification_server.php',
        'http://192.168.1.106/example/server/simple_notification_server.php',
      ];

      for (final url in testUrls) {
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'title': 'Test Notification',
              'message': 'This is a test notification from the app',
              'big_text':
                  'This is an expanded text for the test notification. It contains more details about the notification.',
              'channel_id': 'high_priority_channel',
            }),
          );

          if (response.statusCode == 200) {
            debugPrint('Successfully added test notification to server: $url');
            break;
          }
        } catch (e) {
          debugPrint('Error adding test notification to server $url: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _addTestNotificationToServer: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  // Check if any notification service is active
  Future<void> _checkPollingStatus() async {
    try {
      // Get the active notification service
      final activeService = await _notificationMaster
          .getActiveNotificationService();

      setState(() {
        _isPolling = activeService == "polling";

        if (activeService == "none") {
          _statusMessage = 'No notification service is active';
        } else if (activeService == "polling") {
          _statusMessage = 'Background polling is active';
        } else if (activeService == "foreground") {
          _statusMessage = 'Foreground service is active';
        } else if (activeService == "firebase") {
          _statusMessage = 'Firebase Cloud Messaging is active';
        } else {
          _statusMessage = 'Unknown service is active: $activeService';
        }
      });
    } catch (e) {
      setState(() {
        _isPolling = false;
        _statusMessage = 'Error checking service status: $e';
      });
    }
  }

  // Start notification polling
  Future<void> _startPolling() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid URL')));
      return;
    }

    int? interval;
    try {
      interval = int.parse(_intervalController.text.trim());
      if (interval <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interval must be greater than 0')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid interval')),
      );
      return;
    }

    // Check permission
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      // Request permission if not granted
      final granted = await _notificationMaster.requestNotificationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission not granted')),
        );
        return;
      }
    }

    // Start polling
    final success = await _notificationMaster.startNotificationPolling(
      pollingUrl: url,
      intervalMinutes: interval,
    );

    if (!mounted) return;

    if (success) {
      _checkPollingStatus(); // Update status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Background polling started! Note: This may stop when the app is closed.',
          ),
          action: SnackBarAction(
            label: 'Use Foreground Service Instead',
            onPressed: () {
              _stopPolling().then((_) => _startForegroundService());
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

  // Stop notification polling
  Future<void> _stopPolling() async {
    final success = await _notificationMaster.stopNotificationPolling();

    if (!mounted) return;

    if (success) {
      _checkPollingStatus(); // Update status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background polling stopped!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop notification polling')),
      );
    }
  }

  // Start foreground service for continuous notification polling
  Future<void> _startForegroundService() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid URL')));
      return;
    }

    int? interval;
    try {
      interval = int.parse(_intervalController.text.trim());
      if (interval <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interval must be greater than 0')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid interval')),
      );
      return;
    }

    // Check permission
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      // Request permission if not granted
      final granted = await _notificationMaster.requestNotificationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission not granted')),
        );
        return;
      }
    }

    // Start foreground service
    final success = await _notificationMaster.startForegroundService(
      pollingUrl: url,
      intervalMinutes: interval,
    );

    if (!mounted) return;

    if (success) {
      _checkPollingStatus(); // Update status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foreground service started! Notifications will continue even when the app is closed.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start foreground service')),
      );
    }
  }

  // Stop foreground service
  Future<void> _stopForegroundService() async {
    final success = await _notificationMaster.stopForegroundService();

    if (!mounted) return;

    if (success) {
      _checkPollingStatus(); // Update status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foreground service stopped!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop foreground service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Notification Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _statusMessage.contains('Foreground service')
                    ? Colors.green.shade100
                    : _isPolling
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _statusMessage.contains('Foreground service')
                      ? Colors.green.shade300
                      : _isPolling
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
                        _statusMessage.contains('Foreground service')
                            ? Icons.notifications_active
                            : _isPolling
                            ? Icons.notifications
                            : Icons.notifications_off,
                        color: _statusMessage.contains('Foreground service')
                            ? Colors.green.shade800
                            : _isPolling
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusMessage.contains('Foreground service')
                            ? 'Foreground Service Active'
                            : _isPolling
                            ? 'Background Polling Active'
                            : 'Notification Service Inactive',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _statusMessage.contains('Foreground service')
                              ? Colors.green.shade800
                              : _isPolling
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
                      color: _statusMessage.contains('Foreground service')
                          ? Colors.green.shade800
                          : _isPolling
                          ? Colors.blue.shade800
                          : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Configuration section
            const Text(
              'Polling Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // URL selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server URL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a predefined URL or enter a custom one:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // URL dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Predefined URLs',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedUrl,
                    items: _urlOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                    onChanged: !_isPolling
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUrl = value;
                                _urlController.text = value;
                              });
                            }
                          }
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Custom URL field
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Custom URL (edit if needed)',
                      hintText: 'http://your-server.com/notifications',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isPolling,
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Note: For emulators, use 10.0.2.2 instead of localhost',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interval field
            TextField(
              controller: _intervalController,
              decoration: const InputDecoration(
                labelText: 'Polling Interval (minutes)',
                hintText: '15',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isPolling,
            ),
            const SizedBox(height: 24),

            // Service selection section
            const Text(
              'Notification Service Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose between background polling (may stop when app is closed) or foreground service (keeps running even when app is closed).',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Background polling section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Background Polling',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simple polling that may stop when the app is closed. Use for non-critical notifications.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_isPolling)
                    ElevatedButton(
                      onPressed: _stopPolling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Stop Background Polling'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _startPolling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Background Polling'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Foreground service section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Foreground Service (Recommended)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reliable notification delivery even when the app is closed. Creates a persistent notification but ensures the service keeps running.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _startForegroundService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Foreground Service'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _stopForegroundService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Stop Foreground Service'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Information section
            const Text(
              'Server Response Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The server should return JSON in this format:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('''
{
  "notifications": [
    {
      "title": "Notification Title",
      "message": "Notification Message",
      "bigText": "Optional expanded text",
      "channelId": "Optional custom channel ID"
    }
  ]
}'''),
                  SizedBox(height: 16),
                  Text(
                    'Available Channel IDs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('''
- high_priority_channel: With sound and vibration
- default_channel: With sound and vibration
- silent_channel: No sound or vibration
- media_channel: With sound, no vibration'''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Screen extends StatefulWidget {
  const Screen({super.key});

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Hello")));
  }
}
