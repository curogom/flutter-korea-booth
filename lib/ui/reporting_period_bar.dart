import 'package:flutter/material.dart';

import '../model/reporting_period.dart';
import '../state/reporting_period_controller.dart';
import 'visuals.dart';

class ReportingPeriodBar extends StatelessWidget {
  const ReportingPeriodBar({super.key, required this.controller});
  final ReportingPeriodController controller;

  @override
  Widget build(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                ko ? '통계 조회 범위' : 'Reporting scope',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: navy,
                ),
              ),
              ChoiceChip(
                key: const Key('report-event-period'),
                label: Text(ko ? '행사 기간' : 'Event period'),
                selected: !controller.allTime,
                onSelected: (_) => controller.showAllTime(false),
              ),
              ChoiceChip(
                key: const Key('report-all-time'),
                label: Text(ko ? '기간 제한 없음' : 'All dates'),
                selected: controller.allTime,
                onSelected: (_) => controller.showAllTime(true),
              ),
              TextButton.icon(
                key: const Key('report-edit-period'),
                icon: const Icon(Icons.date_range),
                label: Text(ko ? '기간·환경 변경' : 'Edit period & environment'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _PeriodDialog(controller: controller, ko: ko),
                ),
              ),
            ],
          ),
          Text(
            controller.allTime
                ? '${controller.period.environment} · ${ko ? '현재 기기 기록 + 서버 최근 500회' : 'Local records + latest 500 server runs'}'
                : '${ReportingPeriod.formatKoreanTime(controller.period.startsAt)} ~ '
                      '${ReportingPeriod.formatKoreanTime(controller.period.endsAt)} KST · '
                      '${controller.period.environment} · ${ko ? '참여 시작 시각 기준' : 'By participation start time'}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          if (controller.error != null)
            Text(
              ko ? '조회 설정을 갱신하지 못했습니다. 마지막 설정으로 표시합니다.' : 'Could not refresh settings. Showing the last valid period.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _PeriodDialog extends StatefulWidget {
  const _PeriodDialog({required this.controller, required this.ko});
  final ReportingPeriodController controller;
  final bool ko;
  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  late final _start = TextEditingController(
    text: ReportingPeriod.formatKoreanTime(widget.controller.period.startsAt),
  );
  late final _end = TextEditingController(
    text: ReportingPeriod.formatKoreanTime(widget.controller.period.endsAt),
  );
  late String _environment = widget.controller.period.environment;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    ReportingPeriod period;
    try {
      period = ReportingPeriod(
        startsAt: ReportingPeriod.parseKoreanTime(_start.text),
        endsAt: ReportingPeriod.parseKoreanTime(_end.text),
        environment: _environment,
      );
    } on FormatException {
      setState(
        () => _error = widget.ko
            ? '날짜는 YYYY-MM-DD HH:mm 형식이며, 종료는 시작보다 뒤여야 합니다.'
            : 'Use YYYY-MM-DD HH:mm. End must be after start.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.save(period);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = widget.ko
              ? '저장하지 못했습니다. 연결과 운영자 권한을 확인해 주세요.'
              : 'Could not save. Check your connection and operator access.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.ko ? '통계 조회 기간' : 'Reporting period'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.ko
                  ? 'Analytics 수집은 계속됩니다. 저장한 기간은 참여 기록과 정답률의 조회 범위에만 적용됩니다. 모든 시간은 한국 시간(KST)입니다.'
                  : 'Analytics keeps collecting. This period only filters participation records and question accuracy. All times are Korea Standard Time (KST).',
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('report-start'),
              controller: _start,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: widget.ko
                    ? '시작 · 포함 (KST)'
                    : 'Start · inclusive (KST)',
                hintText: '2030-01-01 10:00',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('report-end'),
              controller: _end,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: widget.ko
                    ? '종료 · 미포함 (KST)'
                    : 'End · exclusive (KST)',
                hintText: '2030-01-01 18:00',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('report-environment'),
              isExpanded: true,
              initialValue: _environment,
              decoration: InputDecoration(
                labelText: widget.ko ? '데이터 환경' : 'Data environment',
              ),
              items: [
                for (final value in ['production', 'development', 'emulator'])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _environment = value!),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(widget.ko ? '취소' : 'Cancel'),
      ),
      FilledButton(
        key: const Key('report-save'),
        onPressed: _saving ? null : _save,
        child: Text(
          _saving
              ? (widget.ko ? '저장 중…' : 'Saving…')
              : (widget.ko ? '저장' : 'Save'),
        ),
      ),
    ],
  );
}
