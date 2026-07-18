// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

/// A cross-platform **timed reminder / alarm** example that uses the plugin's
/// native background scheduling.
///
/// You pick a time (or a quick duration) and the plugin asks the **operating
/// system** to deliver the notification at that exact moment — even when the
/// app is fully closed. No external plugin is required:
///
/// - **Android** → `AlarmManager` (exact, wake-up alarm; re-armed after reboot).
/// - **iOS / macOS** → `UNUserNotificationCenter` calendar/time-interval trigger.
/// - **Windows** → WinRT `ScheduledToastNotification` with the app's AUMI.
/// - **Linux** → a detached `notify-send` process that survives app close.
/// - **Web** → best-effort `Timer` (only while the tab stays open).
///
/// The fired notification is the loudest the platform allows: Windows & Android
/// use an alarm-style alert, the rest use a high-importance notification.
class ReminderAlarmPage extends StatefulWidget {
  const ReminderAlarmPage({super.key});

  @override
  State<ReminderAlarmPage> createState() => _ReminderAlarmPageState();
}

class _ReminderAlarmPageState extends State<ReminderAlarmPage> {
  final NotificationMaster _nm = NotificationMaster();

  bool _hasPermission = false;
  String _platform = 'Unknown';

  final TextEditingController _titleController = TextEditingController(
    text: 'Reminder',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'Time is up! This is your reminder.',
  );

  final List<_Reminder> _reminders = [];
  Timer? _ticker; // 1-second UI refresh timer for countdowns

  @override
  void initState() {
    super.initState();
    _platform = UnifiedNotificationService.getPlatformName();
    _checkPermission();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final granted = await _nm.checkNotificationPermission();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await _nm.requestNotificationPermission();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
    _snack(
      granted
          ? '✅ Notification permission granted'
          : '❌ Notification permission denied',
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  Future<void> _scheduleInDuration(Duration delay) async {
    if (!await _ensurePermission()) return;
    final fireAt = DateTime.now().add(delay);
    await _addReminder(fireAt);
  }

  Future<void> _scheduleAtTime() async {
    if (!await _ensurePermission()) return;

    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
      helpText: 'Pick the reminder time',
    );
    if (picked == null) return;

    var fireAt = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    // If the chosen time already passed today, schedule for tomorrow.
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    await _addReminder(fireAt);
  }

  Future<void> _addReminder(DateTime fireAt) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final title = _titleController.text.trim().isEmpty
        ? 'Reminder'
        : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'Time is up!'
        : _messageController.text.trim();

    final reminder = _Reminder(
      id: id,
      title: title,
      message: message,
      fireAt: fireAt,
    );

    // Native, OS-level scheduling — works even if the app is closed.
    bool ok = false;
    String? errorCode;
    try {
      debugPrint(
        '[NM-Dart] scheduleNotification: calling plugin, id=$id fireAt=$fireAt epochMillis=${fireAt.millisecondsSinceEpoch}',
      );
      ok = await _nm.scheduleNotification(
        id: id,
        title: '⏰ $title',
        message: message,
        scheduledTime: fireAt,
        alarmSound: true,
        importance: NotificationImportance.high,
      );
      debugPrint('[NM-Dart] scheduleNotification: returned ok=$ok');
    } on PlatformException catch (e) {
      errorCode = e.code;
      debugPrint(
        '[NM-Dart] scheduleNotification: PlatformException code=${e.code} msg=${e.message}',
      );
      ok = false;
    } catch (e) {
      debugPrint('[NM-Dart] scheduleNotification: unexpected error: $e');
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      setState(() => _reminders.add(reminder));
      _snack(
        '⏰ Reminder set for ${_formatClock(fireAt)}'
        ' (in ${_formatRemaining(fireAt.difference(DateTime.now()))})',
      );
    } else if (errorCode == 'EXACT_ALARM_PERMISSION_DENIED') {
      _showExactAlarmPermissionDialog();
    } else {
      _snack(
        '❌ Could not schedule reminder'
        '${errorCode != null ? " ($errorCode)" : ""}',
      );
    }
  }

  void _showExactAlarmPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alarm Permission Required'),
        content: const Text(
          'To fire alarms at the exact scheduled time, please grant the '
          '"Alarms & reminders" permission:\n\n'
          'Settings → Apps → [this app] → Special app access'
          ' → Alarms & reminders',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack(
                'Go to Settings → Apps → Special app access'
                ' → Alarms & reminders',
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReminder(_Reminder reminder) async {
    await _nm.cancelScheduledNotification(reminder.id);
    if (!mounted) return;
    setState(() => _reminders.remove(reminder));
    _snack('Reminder cancelled');
  }

  Future<void> _cancelAll() async {
    await _nm.cancelAllScheduledNotifications();
    if (!mounted) return;
    setState(() => _reminders.clear());
    _snack('All reminders cancelled');
  }

  Future<bool> _ensurePermission() async {
    if (_hasPermission) return true;
    await _requestPermission();
    return _hasPermission;
  }

  // ── Formatting helpers ───────────────────────────────────────────────────────

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏰ Timed Reminder / Alarm'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPermissionCard(),
            const SizedBox(height: 16),
            _buildContentCard(),
            const SizedBox(height: 16),
            _buildQuickCard(),
            const SizedBox(height: 16),
            _buildPickTimeButton(),
            const SizedBox(height: 24),
            _buildRemindersHeader(),
            const SizedBox(height: 8),
            _buildRemindersList(),
            const SizedBox(height: 16),
            _buildNoteCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    final ok = _hasPermission;
    return Card(
      color: ok ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.warning_amber,
              color: ok ? Colors.green[700] : Colors.orange[800],
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform: $_platform',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ok
                        ? 'Notification permission granted'
                        : 'Notification permission required',
                  ),
                ],
              ),
            ),
            if (!ok)
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Grant'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick reminder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('+10 sec', const Duration(seconds: 10)),
                _quickChip('+30 sec', const Duration(seconds: 30)),
                _quickChip('+1 min', const Duration(minutes: 1)),
                _quickChip('+5 min', const Duration(minutes: 5)),
                _quickChip('+15 min', const Duration(minutes: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, Duration delay) {
    return ActionChip(
      avatar: const Icon(Icons.timer, size: 18),
      label: Text(label),
      onPressed: () => _scheduleInDuration(delay),
    );
  }

  Widget _buildPickTimeButton() {
    return ElevatedButton.icon(
      onPressed: _scheduleAtTime,
      icon: const Icon(Icons.access_time),
      label: const Text('Pick a specific time'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildRemindersHeader() {
    return Row(
      children: [
        Text(
          'Scheduled reminders (${_reminders.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_reminders.isNotEmpty)
          TextButton.icon(
            onPressed: _cancelAll,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Cancel all'),
          ),
      ],
    );
  }

  Widget _buildRemindersList() {
    if (_reminders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No reminders yet.\nUse a quick chip or pick a time above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Already-fired reminders (time passed but the OS delivered them) drop off
    // the list automatically.
    _reminders.removeWhere((r) => r.fireAt.isBefore(DateTime.now()));

    final sorted = [..._reminders]
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

    return Column(
      children: sorted.map((r) {
        final remaining = r.fireAt.difference(DateTime.now());
        return Card(
          child: ListTile(
            leading: const Icon(Icons.alarm, color: Colors.deepPurple),
            title: Text(r.title),
            subtitle: Text(
              'At ${_formatClock(r.fireAt)}  •  in ${_formatRemaining(remaining)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _cancelReminder(r),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      color: Colors.blue[50],
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ℹ️ How reminders fire',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Reminders are scheduled natively by the plugin (no external '
              'plugin needed) and fire even when the app is closed:\n'
              '• Android → AlarmManager (also re-armed after reboot).\n'
              '• iOS / macOS → UNUserNotificationCenter trigger.\n'
              '• Windows → WinRT scheduled toast.\n'
              '• Linux → detached notify-send process.\n'
              '• Web → best-effort timer (tab must stay open).',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reminder {
  const _Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.fireAt,
  });

  final int id;
  final String title;
  final String message;
  final DateTime fireAt;
}
