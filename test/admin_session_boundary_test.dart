import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/ui/admin_session_boundary.dart';

Widget app(Future<void> Function() clear, {String initial = '/'}) =>
    MaterialApp(
      initialRoute: initial,
      routes: {
        '/': (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/admin'),
            child: const Text('Open admin'),
          ),
        ),
        '/admin': (context) => AdminSessionBoundary(
          clearSession: clear,
          child: Scaffold(
            appBar: AppBar(title: const Text('Private admin')),
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      Scaffold(appBar: AppBar(title: const Text('Editor'))),
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      },
    );

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('Open admin'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('entry hides inherited session until clearing completes', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(app(() => pending.future));
    await open(tester);
    expect(find.text('Private admin'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsOneWidget);
  });

  testWidgets('direct route entry also clears and retries failure', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(() async {
        if (++calls == 1) throw StateError('simulated failure');
      }, initial: '/admin'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsNothing);
    expect(calls, 1);
    await tester.tap(find.byKey(const Key('admin-session-retry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Private admin'), findsOneWidget);
  });

  testWidgets('back waits for exit cleanup and repeated back is serialized', (
    tester,
  ) async {
    final exit = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      app(() {
        calls++;
        return calls == 1 ? Future<void>.value() : exit.future;
      }),
    );
    await open(tester);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pump();
    expect(find.text('Private admin'), findsNothing);
    expect(find.text('Open admin'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(calls, 2);
    exit.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open admin'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('failed exit stays closed until retry succeeds', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(() async {
        if (++calls == 2) throw StateError('simulated failure');
      }),
    );
    await open(tester);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsNothing);
    expect(find.text('Open admin'), findsNothing);
    await tester.tap(find.byKey(const Key('admin-session-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Open admin'), findsOneWidget);
    expect(calls, 3);
  });

  testWidgets('cancel before entry completes never reveals admin', (
    tester,
  ) async {
    final entry = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      app(() {
        calls++;
        return calls == 1 ? entry.future : Future<void>.value();
      }),
    );
    await open(tester);
    await tester.pageBack();
    await tester.pump();
    expect(calls, 1);
    entry.complete();
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsNothing);
    expect(find.text('Open admin'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('nested editor back does not clear or close admin', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(() async {
        calls++;
      }),
    );
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsOneWidget);
    expect(calls, 1);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Private admin'), findsOneWidget);
    expect(calls, 3);
  });

  testWidgets('forced disposal performs best-effort cleanup', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(() async {
        if (++calls > 1) throw StateError('cleanup failure');
      }),
    );
    await open(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
