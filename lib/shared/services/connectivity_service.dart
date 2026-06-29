import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and exposes a stream + current status.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  // Stream that broadcasts connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivity
      .onConnectivityChanged
      .map(_isConnected);

  /// Returns true if at least one result is NOT none/bluetooth
  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);

  /// One-time check of the current network status
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }
}
