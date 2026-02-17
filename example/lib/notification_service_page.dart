import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class NotificationServicePage extends StatefulWidget {
  const NotificationServicePage({super.key});

  @override
  State<NotificationServicePage> createState() =>
      _NotificationServicePageState();
}

class _NotificationServicePageState extends State<NotificationServicePage> {
  final _notificationMaster = NotificationMaster();
  String _activeService = 'unknown';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkActiveService();
  }

  // Check which notification service is currently active
  Future<void> _checkActiveService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeService = await _notificationMaster
          .getActiveNotificationService();

      if (!mounted) return;

      setState(() {
        _activeService = activeService;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _activeService = 'error';
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking service: $e')));
    }
  }

  // Set Firebase as the active notification service
  Future<void> _setFirebaseAsActive() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationMaster.setFirebaseAsActiveService();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase set as active service')),
        );
        _checkActiveService();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set Firebase as active service'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error setting Firebase: $e')));
    }
  }

  // Start WorkManager polling service
  Future<void> _startPollingService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationMaster.startNotificationPolling(
        pollingUrl: 'http://10.0.2.2:3000/',
        intervalMinutes: 15,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polling service started')),
        );
        _checkActiveService();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start polling service')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting polling: $e')));
    }
  }

  // Start foreground service
  Future<void> _startForegroundService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationMaster.startForegroundService(
        pollingUrl: 'http://10.0.2.2:3000/',
        intervalMinutes: 15,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foreground service started')),
        );
        _checkActiveService();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start foreground service')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting foreground service: $e')),
      );
    }
  }

  // Stop all notification services
  Future<void> _stopAllServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Stop both services to be safe
      await _notificationMaster.stopNotificationPolling();
      await _notificationMaster.stopForegroundService();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notification services stopped')),
      );
      _checkActiveService();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error stopping services: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Service Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Active Notification Service',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildServiceStatusWidget(),
                          const SizedBox(height: 8),
                          Text(
                            _getServiceDescription(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Service selection
                  const Text(
                    'Select Notification Service',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Firebase option
                  _buildServiceButton(
                    title: 'Use Firebase Cloud Messaging',
                    description: 'Best for battery life and reliability',
                    icon: Icons.cloud,
                    color: Colors.blue,
                    onPressed: _setFirebaseAsActive,
                    isActive: _activeService == 'firebase',
                  ),
                  const SizedBox(height: 12),

                  // Polling option
                  _buildServiceButton(
                    title: 'Use WorkManager Polling',
                    description: 'Good battery life, checks periodically',
                    icon: Icons.sync,
                    color: Colors.green,
                    onPressed: _startPollingService,
                    isActive: _activeService == 'polling',
                  ),
                  const SizedBox(height: 12),

                  // Foreground service option
                  _buildServiceButton(
                    title: 'Use Foreground Service',
                    description: 'Higher battery usage, but more reliable',
                    icon: Icons.notifications_active,
                    color: Colors.orange,
                    onPressed: _startForegroundService,
                    isActive: _activeService == 'foreground',
                  ),
                  const SizedBox(height: 24),

                  // Stop all services
                  ElevatedButton.icon(
                    onPressed: _stopAllServices,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop All Notification Services'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Build the service status widget
  Widget _buildServiceStatusWidget() {
    IconData icon;
    Color color;
    String statusText;

    switch (_activeService) {
      case 'none':
        icon = Icons.notifications_off;
        color = Colors.grey;
        statusText = 'No Service Active';
        break;
      case 'polling':
        icon = Icons.sync;
        color = Colors.green;
        statusText = 'WorkManager Polling';
        break;
      case 'foreground':
        icon = Icons.notifications_active;
        color = Colors.orange;
        statusText = 'Foreground Service';
        break;
      case 'firebase':
        icon = Icons.cloud;
        color = Colors.blue;
        statusText = 'Firebase Cloud Messaging';
        break;
      default:
        icon = Icons.error;
        color = Colors.red;
        statusText = 'Unknown Status';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 12),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Get description text for the active service
  String _getServiceDescription() {
    switch (_activeService) {
      case 'none':
        return 'No notification service is currently active. Select a service below.';
      case 'polling':
        return 'WorkManager polling is active. Notifications are checked periodically in the background.';
      case 'foreground':
        return 'Foreground service is active. A persistent notification is shown to ensure reliable delivery.';
      case 'firebase':
        return 'Firebase Cloud Messaging is set as the active service. This is managed by Firebase.';
      default:
        return 'Unable to determine the active notification service.';
    }
  }

  // Build a service selection button
  Widget _buildServiceButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Card(
      elevation: isActive ? 4 : 1,
      color: isActive ? color.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isActive) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
