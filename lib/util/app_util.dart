import 'package:flutter/foundation.dart';

class AppUtil {
  void log(String message) {
    if (kDebugMode) {
      print('====> $message');
    }
  }
}
