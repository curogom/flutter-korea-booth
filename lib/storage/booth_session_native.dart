import 'booth_session_status.dart';

Future<BoothSessionStatus> acquireBoothSession(String name) async =>
    BoothSessionStatus.acquired;
void releaseBoothSession() {}
