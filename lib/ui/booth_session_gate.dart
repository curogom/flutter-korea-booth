import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../storage/booth_session_status.dart';
import 'visuals.dart';

class BoothSessionGate extends StatefulWidget {
  const BoothSessionGate({
    super.key,
    required this.status,
    required this.locale,
    required this.onRetry,
  });
  final BoothSessionStatus status;
  final Locale locale;
  final Future<void> Function() onRetry;
  @override
  State<BoothSessionGate> createState() => _BoothSessionGateState();
}

class _BoothSessionGateState extends State<BoothSessionGate> {
  bool _retrying = false;
  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: widget.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
    ),
    home: Builder(
      builder: (context) {
        final s = AppLocalizations.of(context);
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tab, size: 54, color: blue),
                    const SizedBox(height: 20),
                    Text(
                      widget.status == BoothSessionStatus.alreadyOpen
                          ? s.alreadyOpenTitle
                          : s.startUnavailableTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.status == BoothSessionStatus.alreadyOpen
                          ? s.alreadyOpenHelp
                          : s.startUnavailableHelp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.6, color: muted),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retrying ? null : _retry,
                      child: Text(s.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
