import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/presentation/home_page.dart';

void main() {
  runApp(const SimulatedSmartkeyApp());
}

class SimulatedSmartkeyApp extends StatelessWidget {
  const SimulatedSmartkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
