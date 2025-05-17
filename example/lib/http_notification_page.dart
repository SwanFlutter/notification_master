import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class HttpNotificationPage extends StatefulWidget {
  const HttpNotificationPage({super.key});

  @override
  State<HttpNotificationPage> createState() => _HttpNotificationPageState();
}

class _HttpNotificationPageState extends State<HttpNotificationPage> {
  final _notificationMaster = NotificationMaster();
  final _urlController = TextEditingController(
    text: 'http://10.0.2.2:3000/', // Default URL for Android emulator
  );
  final _intervalController = TextEditingController(text: '15');
  bool _isPolling = false;
  String _statusMessage = 'Polling is not active';

  @override
  void initState() {
    super.initState();
    _checkPollingStatus();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  // Check if polling is active (this is a mock implementation)
  Future<void> _checkPollingStatus() async {
    // In a real app, you would check if polling is active
    // For this example, we'll just assume it's not active initially
    setState(() {
      _isPolling = false;
      _statusMessage = 'Polling is not active';
    });
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
    final hasPermission =
        await _notificationMaster.checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission not granted')),
      );
      return;
    }

    // Start polling
    final success = await _notificationMaster.startNotificationPolling(
      pollingUrl: url,
      intervalMinutes: interval,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isPolling = true;
        _statusMessage = 'Polling active: Checking every $interval minutes';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification polling started!')),
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
      setState(() {
        _isPolling = false;
        _statusMessage = 'Polling is not active';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification polling stopped!')),
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
    final hasPermission =
        await _notificationMaster.checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission not granted')),
      );
      return;
    }

    // Start foreground service
    final success = await _notificationMaster.startForegroundService(
      pollingUrl: url,
      intervalMinutes: interval,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _statusMessage =
            'Foreground service active: Checking every $interval minutes';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foreground service started!')),
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
      setState(() {
        _statusMessage = 'Foreground service stopped';
      });
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
                color:
                    _isPolling ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Text(
                    _isPolling ? 'Polling Active' : 'Polling Inactive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _isPolling
                              ? Colors.green.shade800
                              : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color:
                          _isPolling
                              ? Colors.green.shade800
                              : Colors.grey.shade800,
                    ),
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

            // URL field
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Notification Server URL',
                hintText: 'https://example.com/notifications',
                border: OutlineInputBorder(),
              ),
              enabled: !_isPolling,
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

            // Control buttons
            if (_isPolling)
              ElevatedButton(
                onPressed: _stopPolling,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Stop Polling'),
              )
            else
              ElevatedButton(
                onPressed: _startPolling,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start Polling'),
              ),

            const SizedBox(height: 24),

            // Foreground service section
            const Text(
              'Foreground Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a foreground service for more reliable notification delivery. This creates a persistent notification but ensures the service keeps running.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startForegroundService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
