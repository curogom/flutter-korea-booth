import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../model/question.dart';
import '../state/quiz_controller.dart';
import 'visuals.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.controller,
    required this.locale,
    required this.onLocaleChanged,
    required this.sampleMode,
    this.showAdmin = true,
  });
  final QuizController controller;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool sampleMode;
  final bool showAdmin;
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  late QuizPhase _lastPhase;
  late int _lastRound;
  QuizController get controller => widget.controller;
  Locale get locale => widget.locale;
  ValueChanged<Locale> get onLocaleChanged => widget.onLocaleChanged;
  bool get sampleMode => widget.sampleMode;

  @override
  void initState() {
    super.initState();
    _listen();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.detached) {
      didChangeAppLifecycleState(state);
    }
  }

  void _listen() {
    _lastPhase = controller.phase;
    _lastRound = controller.round;
    controller.addListener(_quizChanged);
  }

  @override
  void didUpdateWidget(QuizPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_quizChanged);
      _listen();
    }
  }

  void _quizChanged() {
    final phase = controller.phase;
    final changedPage = controller.round != _lastRound ||
        (phase != _lastPhase &&
            (phase == QuizPhase.home ||
                phase == QuizPhase.result ||
                _lastPhase == QuizPhase.home));
    _lastPhase = phase;
    _lastRound = controller.round;
    if (changedPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_quizChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TickerMode(
        enabled: controller.isForeground,
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: BoothBackground())),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 18, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_rounded, size: 44, color: blue),
                          const Spacer(),
                          if (sampleMode &&
                              MediaQuery.sizeOf(context).width > 500)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                s.sampleMode,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          DropdownButton<Locale>(
                            key: const Key('language-picker'),
                            style: const TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: 13,
                              color: navy,
                            ),
                            value: locale,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.language, size: 19),
                            items: const [
                              DropdownMenuItem(
                                value: Locale('ko'),
                                child: Text('한국어'),
                              ),
                              DropdownMenuItem(
                                value: Locale('en'),
                                child: Text('English'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) onLocaleChanged(value);
                            },
                          ),
                          if (widget.showAdmin)
                            IconButton(
                              tooltip: s.admin,
                              icon: const Icon(Icons.tune_rounded, size: 21),
                              onPressed: () {
                                controller.reset();
                                Navigator.pushNamed(context, '/admin');
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                          key: const Key('quiz-scroll'),
                          controller: _scroll,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1160,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 300),
                                    child: controller.phase == QuizPhase.home
                                        ? _Home(
                                            key: const ValueKey('home'),
                                            controller: controller,
                                          )
                                        : controller.phase == QuizPhase.result
                                            ? _Result(
                                                key: const ValueKey('result'),
                                                controller: controller,
                                              )
                                            : _Question(
                                                key: ValueKey(
                                                  'question-${controller.round}',
                                                ),
                                                controller: controller,
                                                language: locale.languageCode,
                                              ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'Practice a little. '),
                                    TextSpan(
                                      text: 'Learn something.',
                                      style: TextStyle(
                                        color: blue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                            ),
                            if (constraints.maxWidth > 650)
                              Text(
                                'DEMO QUIZ · ${s.challenge}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                  letterSpacing: 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (controller.phase == QuizPhase.result && controller.passed)
                  const Positioned.fill(child: Celebration()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key, required this.controller});
  final QuizController controller;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DEMO QUIZ · ${s.challenge}',
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: blue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Quiz '),
                TextSpan(
                  text: 'Demo',
                  style: TextStyle(color: blue),
                ),
              ],
            ),
            style: TextStyle(
              color: navy,
              fontSize: 64,
              height: 1,
              letterSpacing: -3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'PLAY',
          style: TextStyle(
            color: navy,
            fontSize: 43,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          s.invite,
          style: const TextStyle(color: muted, height: 1.8, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryButton(
              key: const Key('start-quiz'),
              label: s.startQuiz,
              onPressed: controller.canStart ? controller.start : null,
              icon: Icons.north_east_rounded,
            ),
            SizedBox(
              width: 145,
              child: Text(
                s.winRule,
                style: const TextStyle(fontSize: 12, height: 1.6, color: muted),
              ),
            ),
          ],
        ),
        if (!controller.canStart)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              controller.loading
                  ? s.loadingQuestions
                  : controller.error != null
                      ? s.loadError
                      : s.questionsUnavailable,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ),
        if (controller.usingSavedQuestions)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              s.savedQuestionsNotice,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        if (controller.error != null || controller.hasCatalogSyncError)
          TextButton.icon(
            key: const Key('retry-questions'),
            onPressed: controller.retry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.retryQuestions),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final art = SizedBox(
          width: constraints.maxWidth < 720 ? 285 : 410,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const DemoMascot(width: 400),
              Positioned(
                left: 8,
                bottom: 5,
                child: Transform.rotate(
                  angle: -.08,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '3 / 4   DEMO COMPLETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 16),
              Center(child: art),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: 30),
            Expanded(child: Center(child: art)),
          ],
        );
      },
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    super.key,
    required this.controller,
    required this.language,
  });
  final QuizController controller;
  final String language;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context), c = controller;
    final text = c.current.textFor(language),
        revealing = c.phase == QuizPhase.reveal;
    final emotion = revealing
        ? (c.isCorrect ? DemoEmotion.happy : DemoEmotion.sad)
        : DemoEmotion.neutral;
    final companion = Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(70),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              revealing
                  ? (c.isCorrect ? s.dashCorrect : s.dashIncorrect)
                  : c.selection == null
                      ? s.dashWelcome
                      : s.dashSelected,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.5, color: navy),
            ),
          ),
          DemoMascot(emotion: emotion, width: 245),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${c.score}',
                style: const TextStyle(
                  color: blue,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${s.correctCount}\n${s.threeToWin}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final question = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.questionNumber(c.round + 1, 4).toUpperCase(),
          style: const TextStyle(
            color: blue,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          text.prompt,
          key: const Key('question-prompt'),
          style: const TextStyle(
            fontSize: 34,
            height: 1.3,
            letterSpacing: -1.2,
            color: navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 480 ? 2 : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: optionIds.map((id) {
                final selected = c.selection == id,
                    correct = revealing && id == c.current.correctOptionId,
                    wrong = revealing && selected && !correct;
                final fill = correct || (!revealing && selected)
                    ? const Color(0xffedf6ff)
                    : wrong
                        ? const Color(0xfffff0ea)
                        : Colors.white;
                final border = correct || (!revealing && selected)
                    ? blue
                    : wrong
                        ? const Color(0xffe6a492)
                        : lineBlue;
                return SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 12) / columns,
                  child: Semantics(
                    selected: selected,
                    child: AnimatedScale(
                      scale: selected && !revealing ? 1.012 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: fill,
                          border: Border.all(
                            color: border,
                            width: selected ? 1.7 : 1,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: InkWell(
                          key: Key('answer-$id'),
                          onTap: revealing ? null : () => c.select(id),
                          borderRadius: BorderRadius.circular(13),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 70),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 29,
                                    height: 29,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          correct || selected ? blue : paleBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: correct || wrong
                                        ? Icon(
                                            correct
                                                ? Icons.check_rounded
                                                : Icons.close_rounded,
                                            size: 17,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            id.toUpperCase(),
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : muted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      text.options[id]!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        const Divider(color: lineBlue),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revealing
                          ? (c.isCorrect
                              ? s.correctFeedback
                              : s.incorrectFeedback)
                          : c.selection == null
                              ? s.selectPrompt
                              : s.selectedAnswer(text.options[c.selection]!),
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      revealing
                          ? text.explanation
                          : c.selection == null
                              ? s.selectHelp
                              : s.changeHelp,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (revealing)
                SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      Text(
                        c.round == 3 ? s.showResults : s.nextQuestion,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'progress-${c.round}-${c.revealRevision}',
                        ),
                        tween: Tween(begin: 1, end: 0),
                        duration: QuizController.revealDuration,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          color: blue,
                          backgroundColor: lineBlue,
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  key: const Key('confirm-answer'),
                  onPressed: c.selection == null ? null : c.confirm,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(s.confirmAnswer),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(85, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: c.reset,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    s.home,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            ...List.generate(4, (index) {
              final answered = index < c.answers.length,
                  right = answered &&
                      c.answers[index] == c.session[index].correctOptionId;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: answered && !right
                      ? const Color(0xfffbe7de)
                      : index == c.round || answered
                          ? blue
                          : paleBlue,
                  child: answered
                      ? Icon(
                          right ? Icons.check_rounded : Icons.close_rounded,
                          size: 15,
                          color: right ? Colors.white : muted,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: index == c.round ? Colors.white : muted,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 760
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    question,
                    const SizedBox(height: 24),
                    Center(child: SizedBox(width: 300, child: companion)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 315, child: companion),
                    const SizedBox(width: 28),
                    Expanded(child: question),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({super.key, required this.controller});
  final QuizController controller;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context), c = controller;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          c.passed ? 'DEMO CHALLENGE COMPLETE' : 'THANK YOU FOR PLAYING',
          style: const TextStyle(
            fontSize: 11,
            color: blue,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          c.passed ? s.successTitle : s.tryTitle,
          style: const TextStyle(
            fontSize: 39,
            fontWeight: FontWeight.w800,
            color: navy,
            height: 1.2,
          ),
        ),
        Text(
          c.passed ? s.successSubtitle : s.trySubtitle,
          style: const TextStyle(
            fontSize: 39,
            fontWeight: FontWeight.w800,
            color: blue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CircleAvatar(
                radius: 23,
                backgroundColor:
                    c.answers[index] == c.session[index].correctOptionId
                        ? blue
                        : paleBlue,
                child: Icon(
                  c.answers[index] == c.session[index].correctOptionId
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color: c.answers[index] == c.session[index].correctOptionId
                      ? Colors.white
                      : muted,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          s.resultScore(c.score),
          key: const Key('result-score'),
          style: const TextStyle(fontWeight: FontWeight.w700, color: navy),
        ),
        const SizedBox(height: 8),
        Text(
          c.passed ? s.successMessage : s.tryMessage,
          style: const TextStyle(color: muted, height: 1.7),
        ),
        if (c.passed)
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: blue, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.swagPickup,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        PrimaryButton(label: s.nextPlayer, onPressed: c.reset),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final dash = DemoMascot(
          emotion: c.passed ? DemoEmotion.happy : DemoEmotion.sad,
          width: constraints.maxWidth < 720 ? 230 : 360,
        );
        return constraints.maxWidth < 720
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: dash),
                  const SizedBox(height: 20),
                  copy,
                ],
              )
            : Row(
                children: [
                  Expanded(child: Center(child: dash)),
                  const SizedBox(width: 30),
                  Expanded(child: copy),
                ],
              );
      },
    );
  }
}
