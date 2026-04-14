import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/service/app_bluetooth_service.dart';
import 'package:simulated_smartkey_app/service/nfc_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AppBluetoothService _bluetoothService = AppBluetoothService();
  final NfcService _nfcService = NfcService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SmartKey Simulator')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_scanBluetoothButton(), _scanNfcButton()],
              ),
            ),
          ),
        ],
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

  Widget _scanNfcButton() {
    return ElevatedButton(onPressed: _onScanNfc, child: Text('Scan Nfc'));
  }

  void _onScanNfc() {
    _nfcService.onScan();
  }
}