import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firebase_config.dart';
import '../data/run_repository.dart';
import '../model/reporting_period.dart';
import '../l10n/generated/app_localizations.dart';
import '../model/quiz_run.dart';
import '../model/question_accuracy.dart';
import '../storage/run_ledger.dart';
import 'visuals.dart';

class RunOperations extends StatefulWidget {
  const RunOperations({
    super.key,
    required this.ledger,
    this.period,
    this.environment,
  });
  final RunLedger ledger;
  final ReportingPeriod? period;
  final String? environment;
  @override
  State<RunOperations> createState() => _RunOperationsState();
}

class _RunOperationsState extends State<RunOperations> {
  late final _local = widget.ledger.watchLocal();
  String get _environment => widget.environment ?? FirebaseConfig.environment;
  late final _remote =
      widget.period != null && widget.ledger.remote is RunRangeRemoteRepository
      ? (widget.ledger.remote! as RunRangeRemoteRepository).watchPeriod(
          widget.period!,
        )
      : widget.ledger.remote?.watchRecent(_environment);
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.ledger,
      builder: (context, _) => StreamBuilder<List<QuizRun>>(
        stream: _local,
        builder: (context, local) => StreamBuilder<List<QuizRun>>(
          stream: _remote,
          builder: (context, cloud) {
            final all = mergeParticipationRuns(
              local.data ?? [],
              cloud.data ?? [],
              environment: _environment,
            ).where((run) => widget.period?.contains(run) ?? true).toList();
            final query = _search.text.trim().toLowerCase();
            final shown = all
                .where((run) => run.id.toLowerCase().contains(query))
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.period == null
                            ? s.operationsHelp
                            : Localizations.localeOf(context).languageCode ==
                                  'ko'
                            ? '선택한 기간에 시작한 참여 회차입니다. 현재 기기 기록과 서버 기간 조회를 합치며, 같은 회차는 한 번만 셉니다. 대기 중인 기록은 운영자 로그인 후 동기화합니다.'
                            : 'Runs started in the selected period. Local and server records are merged and deduplicated. Pending records sync after operator sign-in.',
                        style: const TextStyle(color: muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('${s.shownRuns}: ${all.length}'),
                          Text(
                            '${s.completedRuns}: ${all.where((r) => r.status == "completed").length}',
                          ),
                          Text(
                            '${s.passedRuns}: ${all.where((r) => r.passed).length}',
                          ),
                          Text(
                            '${s.pendingSync}: ${widget.ledger.pendingCount}',
                          ),
                          if (widget.ledger.rejectedCount > 0)
                            Text(
                              '${s.recordsNeedReview}: ${widget.ledger.rejectedCount}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                      if (cloud.hasError || widget.ledger.syncError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            s.recordsSyncError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('run-search'),
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: s.searchRun,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.ledger.isSyncing
                              ? null
                              : () => widget.ledger.flush(retryRejected: true),
                          icon: const Icon(Icons.sync),
                          label: Text(s.syncNow),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? Center(child: Text(s.noRunRecords))
                      : ListView.separated(
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final run = shown[index];
                            final status = run.passed
                                ? s.passedRuns
                                : run.status == 'completed'
                                ? s.completedRuns
                                : run.status == 'started'
                                ? s.inProgress
                                : s.interruptedRun;
                            return ListTile(
                              title: Text(
                                '${run.id.substring(0, run.id.length < 8 ? run.id.length : 8).toUpperCase()} · ${run.score}/4 · ${run.language.toUpperCase()}',
                              ),
                              subtitle: Text(
                                '${DateFormat("MM-dd HH:mm").format(run.startedAt.toUtc().add(const Duration(hours: 9)))} KST · $status',
                              ),
                              trailing:
                                  widget.ledger.rejectedCodes.containsKey(
                                    run.id,
                                  )
                                  ? Tooltip(
                                      message: s.recordsNeedReview,
                                      child: Icon(
                                        Icons.sync_problem,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
