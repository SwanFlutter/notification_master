// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

/// Demonstrates how device tokens and topic subscriptions work with
/// the NotificationMaster plugin.
///
/// Architecture note:
///   Firebase present  → getDeviceToken() wraps FirebaseMessaging.getToken()
///                        subscribeToTopic() calls FCM directly
///   Firebase absent   → getDeviceToken() returns a stable device ID
///                        topics are stored locally — sync to your own server
class TokenTopicPage extends StatefulWidget {
  const TokenTopicPage({super.key});

  @override
  State<TokenTopicPage> createState() => _TokenTopicPageState();
}

class _TokenTopicPageState extends State<TokenTopicPage> {
  final _nm = NotificationMaster();
  final _topicController = TextEditingController();

  String? _deviceToken;
  String  _tokenSource  = '';
  List<String> _subscribedTopics = [];

  // fine-grained loading flags so the page stays visible while loading
  bool _tokenLoading  = false;
  bool _topicLoading  = false;

  @override
  void initState() {
    super.initState();
    _loadSubscribedTopics();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<void> _loadSubscribedTopics() async {
    final topics = await _nm.getSubscribedTopics();
    if (mounted) setState(() => _subscribedTopics = topics);
  }

  void _snack(String msg, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  /// Detects token source from its length / format.
  String _detectSource(String token) {
    if (token.length > 100)  return 'FCM token (Firebase)';
    if (token.length == 36)  return 'UUID (no Firebase)';
    if (token.contains('-'))  return 'UUID / hostname (Desktop)';
    return 'Device ID (no Firebase)';
  }

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _getDeviceToken() async {
    setState(() => _tokenLoading = true);
    try {
      final token = await _nm.getDeviceToken();
      final source = token == null ? 'unavailable' : _detectSource(token);
      setState(() {
        _deviceToken  = token;
        _tokenSource  = source;
        _tokenLoading = false;
      });
      token != null
          ? _snack('Token received — $source')
          : _snack('Token unavailable', color: Colors.orange);
    } catch (e) {
      setState(() => _tokenLoading = false);
      _snack('Error: $e', color: Colors.red);
    }
  }

  Future<void> _copyToken() async {
    if (_deviceToken == null) return;
    await Clipboard.setData(ClipboardData(text: _deviceToken!));
    _snack('Copied to clipboard', color: Colors.blueGrey);
  }

  Future<void> _subscribeToTopic([String? overrideTopic]) async {
    final topic = (overrideTopic ?? _topicController.text).trim();
    if (topic.isEmpty) {
      _snack('Please enter a topic name', color: Colors.orange);
      return;
    }
    setState(() => _topicLoading = true);
    try {
      final ok = await _nm.subscribeToTopic(topic);
      _topicController.clear();
      await _loadSubscribedTopics();
      setState(() => _topicLoading = false);
      _snack(ok ? 'Subscribed to "$topic"' : 'Subscribe failed',
          color: ok ? Colors.green : Colors.red);
    } catch (e) {
      setState(() => _topicLoading = false);
      _snack('Error: $e', color: Colors.red);
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    setState(() => _topicLoading = true);
    try {
      final ok = await _nm.unsubscribeFromTopic(topic);
      await _loadSubscribedTopics();
      setState(() => _topicLoading = false);
      _snack(ok ? 'Unsubscribed from "$topic"' : 'Unsubscribe failed',
          color: ok ? Colors.green : Colors.red);
    } catch (e) {
      setState(() => _topicLoading = false);
      _snack('Error: $e', color: Colors.red);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token & Topics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoBox(),
            const SizedBox(height: 16),
            _tokenSection(),
            const SizedBox(height: 16),
            _topicSection(),
            const SizedBox(height: 16),
            _quickTestSection(),
          ],
        ),
      ),
    );
  }

  // ── info banner ───────────────────────────────────────────────────────────

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 18),
            SizedBox(width: 6),
            Text('How tokens work',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 6),
          Text(
            'Firebase present → real FCM token + direct topic subscription.\n'
            'Firebase absent  → stable device ID + local topic storage.\n'
            'Either way, a local notification confirms each action.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── token section ─────────────────────────────────────────────────────────

  Widget _tokenSection() {
    return _card(
      title: 'Device Token',
      icon: Icons.vpn_key,
      children: [
        ElevatedButton.icon(
          onPressed: _tokenLoading ? null : _getDeviceToken,
          icon: _tokenLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh),
          label: Text(_tokenLoading ? 'Fetching…' : 'Get Device Token'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        if (_deviceToken != null) ...[
          const SizedBox(height: 12),
          // source badge
          Row(children: [
            const Icon(Icons.source, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Source: $_tokenSource',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          const SizedBox(height: 6),
          // token value box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              _deviceToken!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _copyToken,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Token'),
          ),
        ],
      ],
    );
  }

  // ── topic section ─────────────────────────────────────────────────────────

  Widget _topicSection() {
    return _card(
      title: 'Topic Subscription',
      icon: Icons.label,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _topicController,
              enabled: !_topicLoading,
              decoration: InputDecoration(
                hintText: 'e.g. news, alerts, offers',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _subscribeToTopic(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _topicLoading ? null : _subscribeToTopic,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: _topicLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Subscribe'),
          ),
        ]),
        const SizedBox(height: 12),

        // subscribed topics list
        if (_subscribedTopics.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No active subscriptions',
                  style: TextStyle(
                      color: Colors.grey[500], fontStyle: FontStyle.italic)),
            ),
          )
        else ...[
          Text('Active (${_subscribedTopics.length}):',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ..._subscribedTopics.map((topic) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.label_outline, color: Colors.green),
                  title: Text(topic),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    tooltip: 'Unsubscribe',
                    onPressed: _topicLoading
                        ? null
                        : () => _unsubscribeFromTopic(topic),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 4),
        // server usage hint (collapsible)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('How to send from server',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6)),
                child: const SelectableText(
                  '// Firebase (FCM HTTP v1)\n'
                  'POST fcm.googleapis.com/v1/projects/{id}/messages:send\n'
                  '{\n'
                  '  "message": {\n'
                  '    "topic": "news",\n'
                  '    "notification": {"title":"...", "body":"..."}\n'
                  '  }\n'
                  '}\n\n'
                  '// No Firebase — your own server:\n'
                  '// 1. call getDeviceToken() + getSubscribedTopics()\n'
                  '// 2. POST token+topics to your backend\n'
                  '// 3. server pushes via FCM / APNs / any provider',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── quick test section ────────────────────────────────────────────────────

  Widget _quickTestSection() {
    const topics = ['news', 'promotions', 'alerts'];
    return _card(
      title: 'Quick Test',
      icon: Icons.bolt,
      children: [
        for (final topic in topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton.icon(
              onPressed: _topicLoading ? null : () => _subscribeToTopic(topic),
              icon: const Icon(Icons.add, size: 16),
              label: Text('Subscribe to "$topic"'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
            ),
          ),
      ],
    );
  }

  // ── shared card builder ───────────────────────────────────────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
