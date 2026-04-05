import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:simulated_smartkey_app/util/app_util.dart';

class BleService {
  BleService._();

  static final BleService _instance = BleService._();

  factory BleService() => _instance;

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  static const String _serviceUuid = '12345678-1234-1234-1234-1234567890ab';
  bool _isAdvertising = false;
  BluetoothPeripheralState _state = BluetoothPeripheralState.unknown;
  String _deviceName = '';

  Future<bool> onCheckSupported() async {
    bool isSupported = await _blePeripheral.isSupported;
    AppUtil().log('Is supported BLE: $isSupported');
    return isSupported;
  }

  Future<bool> start(String name) async {
    if (_isAdvertising) return false;

    _deviceName = name;
    final advertiseData = AdvertiseData(
      serviceUuid: _serviceUuid,
      localName: name,
      includeDeviceName: true,
    );
    _state = await _blePeripheral.start(advertiseData: advertiseData);
    AppUtil().log('BluetoothPeripheralState: $_state');
    _isAdvertising = true;
    AppUtil().log('BLE SmartKey $_deviceName advertising started');
    return _state == BluetoothPeripheralState.granted;
  }

  Future<bool> stop() async {
    if (!_isAdvertising) return false;
    _state = await _blePeripheral.stop();
    AppUtil().log('BluetoothPeripheralState: $_state');
    _isAdvertising = false;
    AppUtil().log('BLE SmartKey $_deviceName advertising stopped');
    return _state == BluetoothPeripheralState.ready;
  }
}
