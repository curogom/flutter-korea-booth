import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps an administrative route hidden until any inherited session is cleared.
/// Mount this on the admin route, not above the application's Navigator.
class AdminSessionBoundary extends StatefulWidget {
  const AdminSessionBoundary({
    super.key,
    required this.clearSession,
    required this.child,
  });

  final Future<void> Function() clearSession;
  final Widget child;

  @override
  State<AdminSessionBoundary> createState() => _AdminSessionBoundaryState();
}

class _AdminSessionBoundaryState extends State<AdminSessionBoundary> {
  Future<void>? _entry;
  bool _ready = false;
  bool _busy = true;
  bool _failed = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _exitCleared = false;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  void _enter() {
    _busy = true;
    _failed = false;
    _entry = Future<void>.sync(widget.clearSession).then(
      (_) {
        if (!mounted || _leaving) return;
        setState(() {
          _ready = true;
          _busy = false;
        });
      },
      onError: (Object error, StackTrace stack) {
        if (!mounted || _leaving) return;
        setState(() {
          _failed = true;
          _busy = false;
        });
      },
    );
  }

  Future<void> _leave() async {
    if (_leaving && _busy) return;
    // Only this route owns this boundary. An editor pushed above it must keep
    // its own back navigation and must not dismiss the administrative route.
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    setState(() {
      _leaving = true;
      _ready = false;
      _busy = true;
      _failed = false;
    });
    // Do not race entry cleanup against exit cleanup or expose an entry that
    // finishes after the user has already asked to leave.
    await _entry;
    try {
      await widget.clearSession();
      if (!mounted) return;
      _exitCleared = true;
      setState(() {
        _allowPop = true;
        _busy = false;
      });
      // PopScope must rebuild with canPop=true before requesting the pop.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || route?.isCurrent != true) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    if (!_exitCleared) {
      final clear = widget.clearSession;
      // Replacement/removal can bypass a pop veto. Serialize best-effort
      // cleanup after entry, swallowing errors without exposing credentials.
      unawaited(
        (_entry ?? Future<void>.value())
            .then((_) => Future<void>.sync(clear))
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: _ready
          ? widget.child
          : Scaffold(
              appBar: AppBar(
                title: Text(ko ? '관리자 세션' : 'Admin session'),
                leading: BackButton(onPressed: () => unawaited(_leave())),
              ),
              body: Center(
                child: _failed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ko
                                ? '로그아웃하지 못했습니다. 다시 시도해 주세요.'
                                : 'Could not clear the session. Please retry.',
                          ),
                          FilledButton(
                            key: const Key('admin-session-retry'),
                            onPressed: () {
                              if (_leaving) {
                                unawaited(_leave());
                              } else {
                                setState(_enter);
                              }
                            },
                            child: Text(ko ? '다시 시도' : 'Retry'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
    );
  }
}
