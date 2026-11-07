import 'dart:js_interop';

@JS('boothLoadFirebase')
external JSPromise<JSAny?> _loadFirebase();

Future<void> prepareFirebaseWeb() async {
  await _loadFirebase().toDart;
}
