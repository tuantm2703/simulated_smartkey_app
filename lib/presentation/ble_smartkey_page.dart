import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/service/ble_service.dart';
import 'package:simulated_smartkey_app/util/app_const.dart';

class BleSmartkeyPage extends StatefulWidget {
  const BleSmartkeyPage({super.key});

  @override
  State<BleSmartkeyPage> createState() => _BleSmartkeyPageState();
}

class _BleSmartkeyPageState extends State<BleSmartkeyPage> {
  final BleService _bleService = BleService();
  SmartKeyStatus _status = SmartKeyStatus.idle;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SmartKey Simulator')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_displayedInfoWidget(), _groupButtonWidget()],
      ),
    );
  }

  Future<void> _fetchData() async {
    bool isSupported = await _bleService.onCheckSupported();
    _updateSmartKeyStatus(
      isSupported ? SmartKeyStatus.idle : SmartKeyStatus.unsupported,
    );
  }

  Widget _groupButtonWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_startButton(), SizedBox(width: 16), _endButton()],
      ),
    );
  }

  Widget _startButton() {
    return ElevatedButton(
      onPressed: () => _onStartAdvertising(),
      child: Text('Start'),
    );
  }

  Future<void> _onStartAdvertising() async {
    final String name = _nameController.text.trim();

    bool result = await _bleService.start(name.isEmpty ? 'SmartKey_001' : name);
    if (result) {
      _updateSmartKeyStatus(SmartKeyStatus.startAdvertise);
    }
  }

  Widget _endButton() {
    return ElevatedButton(
      onPressed: () => _onEndAdvertising(),
      child: Text('End'),
    );
  }

  Future<void> _onEndAdvertising() async {
    bool result = await _bleService.stop();
    if (result) {
      _updateSmartKeyStatus(SmartKeyStatus.idle);
    }
  }

  Widget _displayedInfoWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${_status.name}'),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(hintText: 'Name'),
            onChanged: (String? value) {
              if (_status == SmartKeyStatus.startAdvertise &&
                  (value ?? '').isNotEmpty) {
                _onEndAdvertising();
              }
            },
          ),
        ],
      ),
    );
  }

  void _updateSmartKeyStatus(SmartKeyStatus status) {
    setState(() => _status = status);
  }
}
