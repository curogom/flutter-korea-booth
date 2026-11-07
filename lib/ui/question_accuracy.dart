import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firebase_config.dart';
import '../data/question_repository.dart';
import '../data/run_repository.dart';
import '../model/reporting_period.dart';
import '../l10n/generated/app_localizations.dart';
import '../model/question.dart';
import '../model/question_accuracy.dart';
import '../model/quiz_run.dart';
import '../storage/run_ledger.dart';
import 'visuals.dart';

class QuestionAccuracyPage extends StatefulWidget {
  const QuestionAccuracyPage({
    super.key,
    required this.ledger,
    required this.repository,
    this.period,
    this.environment,
  });
  final RunLedger ledger;
  final QuestionAdminRepository repository;
  final ReportingPeriod? period;
  final String? environment;
  @override
  State<QuestionAccuracyPage> createState() => _QuestionAccuracyPageState();
}

class _QuestionAccuracyPageState extends State<QuestionAccuracyPage> {
  late Stream<List<QuizRun>> _local;
  Stream<List<QuizRun>>? _remote;
  late Stream<List<QuizQuestion>> _questions;
  String? _language;
  String get _environment => widget.environment ?? FirebaseConfig.environment;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _local = widget.ledger.watchLocal();
    final remote = widget.ledger.remote;
    _remote = widget.period != null && remote is RunRangeRemoteRepository
        ? remote.watchPeriod(widget.period!)
        : remote?.watchRecent(_environment);
    _questions = widget.repository.watchAll();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final percent = NumberFormat.percentPattern(locale)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    String rate(double? value) => value == null ? '—' : percent.format(value);
    return AnimatedBuilder(
      animation: widget.ledger,
      builder: (context, _) => StreamBuilder<List<QuizRun>>(
        stream: _local,
        builder: (context, local) => StreamBuilder<List<QuizRun>>(
          stream: _remote,
          builder: (context, remote) => StreamBuilder<List<QuizQuestion>>(
            stream: _questions,
            builder: (context, catalog) {
              final runs = mergeParticipationRuns(
                local.data ?? [],
                remote.data ?? [],
                environment: _environment,
              ).where((run) => widget.period?.contains(run) ?? true).toList();
              final rows = calculateQuestionAccuracy(
                runs,
                catalog.data ?? [],
                language: _language,
              );
              final responses = rows.fold(0, (sum, row) => sum + row.responses);
              final correct = rows.fold(0, (sum, row) => sum + row.correct);
              final hasError =
                  local.hasError || remote.hasError || catalog.hasError;
              final loading = !local.hasData && !remote.hasData && !hasError;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              s.questionAccuracy,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: navy,
                              ),
                            ),
                            Chip(
                              label: Text(
                                _environment == 'production'
                                    ? s.productionData
                                    : s.testData,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.period == null
                              ? s.accuracyScope
                              : locale == 'ko'
                              ? '선택한 기간에 시작한 회차의 확정 응답을 집계합니다. 현재 기기 기록과 서버 기간 조회를 합치며, 중복 회차는 한 번만 계산합니다.'
                              : 'Confirmed answers from runs started in the selected period. Local and server period records are merged and deduplicated.',
                          style: const TextStyle(color: muted, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text('${s.responseCount}: $responses'),
                            Text('${s.correctResponses}: $correct'),
                            Text(
                              '${s.overallAccuracy}: ${rate(responses == 0 ? null : correct / responses)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              s.runLanguage,
                              style: const TextStyle(color: muted),
                            ),
                            for (final (value, label) in <(String?, String)>[
                              (null, s.allLanguages),
                              ('ko', s.korean),
                              ('en', s.english),
                            ])
                              ChoiceChip(
                                key: Key('accuracy-language-${value ?? 'all'}'),
                                label: Text(label),
                                selected: _language == value,
                                onSelected: (_) =>
                                    setState(() => _language = value),
                              ),
                            TextButton.icon(
                              key: const Key('accuracy-refresh'),
                              icon: const Icon(Icons.refresh),
                              label: Text(s.retryQuestions),
                              onPressed: () => setState(_subscribe),
                            ),
                          ],
                        ),
                        if (hasError || widget.ledger.syncError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              s.accuracyPartialData,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : rows.isEmpty
                        ? Center(child: Text(s.noAccuracyData))
                        : LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    key: const Key('question-accuracy-table'),
                                    headingRowColor:
                                        const WidgetStatePropertyAll(paleBlue),
                                    dataRowMinHeight:
                                        constraints.maxWidth >= 900 ? 64 : 100,
                                    dataRowMaxHeight:
                                        constraints.maxWidth >= 900 ? 64 : 100,
                                    columns: [
                                      DataColumn(label: Text(s.questionPrompt)),
                                      DataColumn(
                                        label: Text(s.responseCount),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text(s.correctResponses),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text(s.incorrectResponses),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text(s.accuracyRate),
                                        numeric: true,
                                      ),
                                    ],
                                    rows: [
                                      for (final row in rows)
                                        DataRow(
                                          key: ValueKey('accuracy-${row.id}'),
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width:
                                                    constraints.maxWidth >= 900
                                                    ? 440
                                                    : 260,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      row.question
                                                              ?.textFor(locale)
                                                              .prompt ??
                                                          row.id,
                                                      maxLines:
                                                          constraints
                                                                  .maxWidth >=
                                                              900
                                                          ? 2
                                                          : 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${row.id}${row.question?.active == false ? ' · ${s.draft}' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: muted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell(Text('${row.responses}')),
                                            DataCell(Text('${row.correct}')),
                                            DataCell(Text('${row.incorrect}')),
                                            DataCell(
                                              Text(
                                                rate(row.rate),
                                                style: const TextStyle(
                                                  color: blue,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
