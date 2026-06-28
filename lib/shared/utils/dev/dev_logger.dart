import 'package:flutter/foundation.dart';

class DevLogger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[DEV_LOG] $message');
      if (error != null) {
        print('[DEV_ERROR] $error');
      }
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  static void info(String message) => log('INFO: $message');
  static void warning(String message) => log('WARNING: $message');
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log('ERROR: $message', error: error, stackTrace: stackTrace);
}
