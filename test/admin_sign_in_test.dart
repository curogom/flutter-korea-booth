import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/admin_sign_in.dart';

void main() {
  test('successful mounted sign-in retains its session', () async {
    var signsOut = 0;
    await signInWithLifecycleCleanup(
      signIn: () async {},
      isMounted: () => true,
      signOut: () async {
        signsOut++;
      },
    );
    expect(signsOut, 0);
  });

  test('failed sign-in propagates to guarded UI handler', () async {
    var signsOut = 0;
    final failure = StateError('sign-in failed');
    await expectLater(
      signInWithLifecycleCleanup(
        signIn: () async {
          throw failure;
        },
        isMounted: () => false,
        signOut: () async {
          signsOut++;
        },
      ),
      throwsA(same(failure)),
    );
    expect(signsOut, 0);
  });

  test('late sign-in after disposal awaits a second cleanup', () async {
    var mounted = true;
    var signsOut = 0;
    var finished = false;
    final login = Completer<void>();
    final cleanup = Completer<void>();
    final operation =
        signInWithLifecycleCleanup(
          signIn: () => login.future,
          isMounted: () => mounted,
          signOut: () {
            signsOut++;
            return cleanup.future;
          },
        ).then((_) {
          finished = true;
        });
    // The user leaves while the authentication request is still pending.
    mounted = false;
    expect(signsOut, 0);
    login.complete();
    await Future<void>.delayed(Duration.zero);
    expect(signsOut, 1);
    expect(finished, false);
    cleanup.complete();
    await operation;
    expect(finished, true);
    expect(signsOut, 1);
  });

  test('late cleanup failure is caught by the UI-style handler', () async {
    final login = Completer<void>();
    final failure = StateError('cleanup failed');
    Object? caught;
    var updatedDisposedUi = false;
    var mounted = true;
    final operation = () async {
      try {
        await signInWithLifecycleCleanup(
          signIn: () => login.future,
          isMounted: () => mounted,
          signOut: () async {
            throw failure;
          },
        );
      } catch (error) {
        caught = error;
        if (mounted) updatedDisposedUi = true;
      }
    }();
    mounted = false;
    login.complete();
    await operation;
    expect(caught, same(failure));
    expect(updatedDisposedUi, false);
  });
  test(
    'clear waits for delayed login and late cleanup before final clear',
    () async {
      final login = Completer<void>();
      final lateCleanup = Completer<void>();
      final events = <String>[];
      final operation = signInWithLifecycleCleanup(
        signIn: () => login.future,
        isMounted: () => false,
        signOut: () {
          events.add('late cleanup');
          return lateCleanup.future;
        },
      );
      final clearing = clearAdminSession(() async {
        events.add('final clear');
      });
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      login.complete();
      await Future<void>.delayed(Duration.zero);
      expect(events, ['late cleanup']);
      lateCleanup.complete();
      await operation;
      await clearing;
      expect(events, ['late cleanup', 'final clear']);
    },
  );

  test('failed pending login still permits final cleanup', () async {
    final login = Completer<void>();
    var cleared = false;
    final operation = signInWithLifecycleCleanup(
      signIn: () => login.future,
      isMounted: () => false,
      signOut: () async {},
    );
    final expectedFailure = expectLater(operation, throwsStateError);
    final clearing = clearAdminSession(() async {
      cleared = true;
    });
    login.completeError(StateError('login failed'));
    await expectedFailure;
    await clearing;
    expect(cleared, true);
  });

  test(
    'failed late cleanup is followed by final clear; failure propagates',
    () async {
      final login = Completer<void>();
      var finalAttempts = 0;
      final operation = signInWithLifecycleCleanup(
        signIn: () => login.future,
        isMounted: () => false,
        signOut: () async {
          throw StateError('late cleanup failed');
        },
      );
      final expectedLoginFailure = expectLater(operation, throwsStateError);
      final clearing = clearAdminSession(() async {
        finalAttempts++;
        throw StateError('final clear failed');
      });
      final expectedClearFailure = expectLater(clearing, throwsStateError);
      login.complete();
      await expectedLoginFailure;
      await expectedClearFailure;
      expect(finalAttempts, 1);
      await clearAdminSession(() async {
        finalAttempts++;
      });
      expect(finalAttempts, 2);
    },
  );
}
