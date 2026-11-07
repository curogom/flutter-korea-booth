enum RunSyncFailureKind { retryable, authentication, record }

class RunSyncFailure implements Exception {
  const RunSyncFailure(this.kind, this.code);
  final RunSyncFailureKind kind;
  final String code;
  @override
  String toString() => 'RunSyncFailure(${kind.name}, $code)';
}
