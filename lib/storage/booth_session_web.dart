import 'dart:js_interop';

import 'booth_session_status.dart';

@JS('boothAcquireSession')
external JSPromise<JSString> _acquire(JSString name);
@JS('boothReleaseSession')
external void _release();

Future<BoothSessionStatus> acquireBoothSession(String name) async {
  try {
    return switch ((await _acquire(name.toJS).toDart).toDart) {
      'acquired' => BoothSessionStatus.acquired,
      'alreadyOpen' => BoothSessionStatus.alreadyOpen,
      _ => BoothSessionStatus.unavailable,
    };
  } catch (_) {
    return BoothSessionStatus.unavailable;
  }
}

void releaseBoothSession() => _release();
