// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

void requestWakeLock() {
  try {
    js.context.callMethod('eval', [
      '''
      if ('wakeLock' in navigator) {
        navigator.wakeLock.request('screen').then((sentinel) => {
          window.wakeLockSentinel = sentinel;
        }).catch((err) => {
          console.error(err);
        });
      }
      '''
    ]);
  } catch (_) {}
}

void releaseWakeLock() {
  try {
    js.context.callMethod('eval', [
      '''
      if (window.wakeLockSentinel) {
        window.wakeLockSentinel.release().then(() => {
          window.wakeLockSentinel = null;
        });
      }
      '''
    ]);
  } catch (_) {}
}
