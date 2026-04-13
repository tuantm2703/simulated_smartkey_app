import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:simulated_smartkey_app/util/app_util.dart';

class AppBluetoothService {
  void onStartScanning() {
    AppUtil().log('Start scanning');
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        AppUtil().log('Result ${result.toString()}');
      }
    });
  }
}
