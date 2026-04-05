import 'package:flutter/material.dart';

import 'ble_smartkey_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const BleSmartkeyPage(),
                  ),
                );
              },
              child: Text('Bluetooth smartkey'),
            ),
          ],
        ),
      ),
    );
  }
}
