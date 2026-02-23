import 'package:flutter/material.dart';

import 'web_example.dart';

/// Web-only platform selector: always show web example.
class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebExamplePage();
  }
}

class UnsupportedPlatformPage extends StatelessWidget {
  const UnsupportedPlatformPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsupported Platform'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Unsupported'),
      ),
    );
  }
}
