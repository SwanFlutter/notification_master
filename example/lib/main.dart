// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:notification_master_example/platform_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: const ImprovedPollingTest(),
      home: const PlatformSelector(),
    );
  }
}
