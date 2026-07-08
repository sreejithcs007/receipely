import 'wake_lock_helper_stub.dart'
    if (dart.library.js) 'wake_lock_helper_web.dart' as impl;

void requestWakeLock() {
  impl.requestWakeLock();
}

void releaseWakeLock() {
  impl.releaseWakeLock();
}
