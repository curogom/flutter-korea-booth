import 'dart:async';

final _pendingAdminSignIns = <Future<void>>{};

/// Re-clears authentication if a pending sign-in finishes after its UI leaves.
/// The caller still receives failures through its guarded error handler.
Future<void> signInWithLifecycleCleanup({
  required Future<void> Function() signIn,
  required bool Function() isMounted,
  required Future<void> Function() signOut,
}) {
  final operation = Future<void>.sync(signIn).then((_) async {
    if (!isMounted()) await signOut();
  });
  _pendingAdminSignIns.add(operation);
  // Handle both outcomes on this bookkeeping branch without changing the
  // original future returned to the UI or creating an unhandled error future.
  unawaited(
    operation.then<void>(
      (_) {
        _pendingAdminSignIns.remove(operation);
      },
      onError: (Object error, StackTrace stack) {
        _pendingAdminSignIns.remove(operation);
      },
    ),
  );
  return operation;
}

/// A route must hide/dispose its sign-in UI before requesting this barrier.
/// Do not return to the participant screen until all pending sign-ins and a
/// final sign-out settle. Sign-in failures do not skip the final sign-out;
/// final cleanup failures propagate so the boundary remains closed.
Future<void> clearAdminSession(Future<void> Function() signOut) async {
  while (_pendingAdminSignIns.isNotEmpty) {
    await Future.wait(
      _pendingAdminSignIns.toList().map(
        (operation) =>
            operation.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ),
    );
  }
  await signOut();
}
