import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'android_example.dart';
import 'ios_example.dart';
import 'linux_example.dart';
import 'macos_example.dart';
import 'web_example.dart';
import 'windows_example.dart';

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebExamplePage();
    }
    if (Platform.isAndroid) {
      return const AndroidNotificationExample();
    }
    if (Platform.isIOS) {
      return const IOSNotificationExample();
    }
    if (Platform.isWindows) {
      return const WindowsExamplePage();
    }
    if (Platform.isLinux) {
      return const LinuxExamplePage();
    }
    if (Platform.isMacOS) {
      return const MacOSExamplePage();
    }
    return const UnsupportedPlatformPage();
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Unsupported Platform',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This platform is not currently supported by notification_master.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Supported: Android, iOS, Windows, Linux, macOS, Web',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
