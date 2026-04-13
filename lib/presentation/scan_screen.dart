import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/service/app_bluetooth_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AppBluetoothService _bluetoothService = AppBluetoothService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SmartKey Simulator')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Center(child: _scanBluetoothButton())],
      ),
    );
  }

  Widget _scanBluetoothButton() {
    return ElevatedButton(
      onPressed: _onScanDevice,
      child: Text('Scan Bluetooth'),
    );
  }

  void _onScanDevice() {
    _bluetoothService.onStartScanning();
  }
}
