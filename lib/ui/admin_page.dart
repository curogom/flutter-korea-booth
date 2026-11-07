import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/admin_sign_in.dart';
import '../data/question_repository.dart';
import '../data/reporting_period_repository.dart';
import '../state/reporting_period_controller.dart';
import 'reporting_period_bar.dart';
import '../storage/run_ledger.dart';
import 'run_operations.dart';
import 'question_accuracy.dart';
import '../l10n/generated/app_localizations.dart';
import '../model/question.dart';
import 'visuals.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    this.repository,
    this.ledger,
    this.reportingRepository,
  });
  final ReportingPeriodRepository? reportingRepository;
  final RunLedger? ledger;
  final QuestionAdminRepository? repository;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _email = TextEditingController(), _password = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool _checking = false, _allowed = false, _error = false, _signingIn = false;
  int _authRevision = 0;
  ReportingPeriodController? _reporting;
  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _authSubscription = FirebaseAuth.instance.idTokenChanges().listen(
        _checkUser,
      );
    }
  }

  Future<void> _checkUser(User? user) async {
    final revision = ++_authRevision;
    if (!mounted) return;
    if (_user?.uid != user?.uid) {
      _reporting?.dispose();
      _reporting = null;
    }
    setState(() {
      _user = user;
      _checking = user != null;
      _allowed = false;
      _error = false;
    });
    if (user == null) return;
    try {
      final token = await user.getIdTokenResult();
      if (mounted && revision == _authRevision) {
        setState(() {
          _allowed = token.claims?['quizAdmin'] == true;
          if (_allowed &&
              _reporting == null &&
              widget.reportingRepository != null) {
            _reporting = ReportingPeriodController(widget.reportingRepository!)
              ..start();
          }
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted && revision == _authRevision) {
        setState(() {
          _checking = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = false;
    });
    try {
      await signInWithLifecycleCleanup(
        signIn: () async {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
        },
        isMounted: () => mounted,
        signOut: FirebaseAuth.instance.signOut,
      );
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _signingIn = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.getIdToken(true);
      await _checkUser(user);
    } catch (_) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _reporting?.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.admin),
        actions: [
          if (_user != null)
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text(s.signOut),
            ),
        ],
      ),
      body: widget.repository == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(s.firebaseRequired),
              ),
            )
          : _checking
          ? const Center(child: CircularProgressIndicator())
          : _allowed
          ? widget.ledger == null
                ? _QuestionList(repository: widget.repository!)
                : DefaultTabController(
                    length: 3,
                    child: AnimatedBuilder(
                      animation: _reporting ?? widget.ledger!,
                      builder: (context, _) => Column(
                        children: [
                          if (_reporting != null)
                            ReportingPeriodBar(controller: _reporting!),
                          TabBar(
                            isScrollable:
                                MediaQuery.sizeOf(context).width < 600,
                            tabs: [
                              Tab(text: s.admin),
                              Tab(text: s.operations),
                              Tab(text: s.questionAccuracy),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _QuestionList(repository: widget.repository!),
                                RunOperations(
                                  key: ValueKey('runs-${_reporting?.key}'),
                                  ledger: widget.ledger!,
                                  period: _reporting?.activePeriod,
                                  environment: _reporting?.period.environment,
                                ),
                                QuestionAccuracyPage(
                                  key: ValueKey('accuracy-${_reporting?.key}'),
                                  ledger: widget.ledger!,
                                  repository: widget.repository!,
                                  period: _reporting?.activePeriod,
                                  environment: _reporting?.period.environment,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.adminSignIn,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_user == null) ...[
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: null,
                          decoration: InputDecoration(labelText: s.email),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: null,
                          onSubmitted: (_) {
                            if (!_signingIn) _signIn();
                          },
                          decoration: InputDecoration(labelText: s.password),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _signingIn ? null : _signIn,
                          child: Text(s.signIn),
                        ),
                      ] else ...[
                        Text(s.accessDenied),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: _refresh,
                          child: Text(s.refreshAccess),
                        ),
                      ],
                      if (_error)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            s.authError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _QuestionList extends StatefulWidget {
  const _QuestionList({required this.repository});
  final QuestionAdminRepository repository;
  @override
  State<_QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends State<_QuestionList> {
  late final _questions = widget.repository.watchAll();
  Future<void> _edit([QuizQuestion? question]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuestionEditor(repository: widget.repository, question: question),
      ),
    );
    if (mounted && saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    }
  }

  Future<void> _toggle(QuizQuestion question) async {
    try {
      await widget.repository.save(question.withActive(!question.active));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return StreamBuilder<List<QuizQuestion>>(
      stream: _questions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.questionListError),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final questions = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminNote,
                      style: const TextStyle(color: muted),
                    ),
                  ),
                  const SizedBox(width: 15),
                  FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.add),
                    label: Text(s.addQuestion),
                  ),
                ],
              ),
            ),
            Expanded(
              child: questions.isEmpty
                  ? Center(child: Text(s.noQuestions))
                  : ListView.separated(
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return ListTile(
                          title: Text(
                            q
                                .textFor(
                                  Localizations.localeOf(context).languageCode,
                                )
                                .prompt,
                          ),
                          subtitle: Text(
                            '${q.order} · ${q.active ? s.published : s.draft}',
                          ),
                          onTap: () => _edit(q),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _edit(q);
                              } else {
                                _toggle(q);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(s.editQuestion),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(q.active ? s.archive : s.publish),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class QuestionEditor extends StatefulWidget {
  const QuestionEditor({super.key, required this.repository, this.question});
  final QuestionAdminRepository repository;
  final QuizQuestion? question;
  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _order;
  final Map<String, Map<String, TextEditingController>> _texts = {};
  late String _correct, _id;
  late bool _active;
  bool _saving = false, _error = false;
  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _id = q?.id ?? widget.repository.newId();
    _correct = q?.correctOptionId ?? 'a';
    _active = q?.active ?? false;
    _order = TextEditingController(text: '${q?.order ?? 10}');
    for (final language in ['ko', 'en']) {
      final text = q?.translations[language];
      _texts[language] = {
        'prompt': TextEditingController(text: text?.prompt ?? ''),
        'explanation': TextEditingController(text: text?.explanation ?? ''),
        for (final id in optionIds)
          id: TextEditingController(text: text?.options[id] ?? ''),
      };
    }
  }

  @override
  void dispose() {
    _order.dispose();
    for (final fields in _texts.values) {
      for (final controller in fields.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      final q = QuizQuestion(
        id: _id,
        order: int.parse(_order.text),
        active: _active,
        correctOptionId: _correct,
        translations: {
          for (final entry in _texts.entries)
            entry.key: QuestionText(
              prompt: entry.value['prompt']!.text.trim(),
              explanation: entry.value['explanation']!.text.trim(),
              options: {
                for (final id in optionIds) id: entry.value[id]!.text.trim(),
              },
            ),
        },
      );
      await widget.repository.save(q);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = true;
        });
      }
    }
  }

  Widget _translation(String language, AppLocalizations s) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            language == 'ko' ? s.korean : s.english,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: navy,
            ),
          ),
          const SizedBox(height: 15),
          for (final key in ['prompt', ...optionIds, 'explanation'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                key: ValueKey('question-$language-$key'),
                controller: _texts[language]![key],
                minLines: 1,
                maxLines: key == 'prompt' || key == 'explanation' ? 4 : 2,
                maxLength: key == 'prompt'
                    ? 500
                    : key == 'explanation'
                    ? 1000
                    : 120,
                validator: (value) =>
                    value?.trim().isNotEmpty == true ? null : s.requiredField,
                decoration: InputDecoration(
                  labelText: key == 'prompt'
                      ? s.questionPrompt
                      : key == 'explanation'
                      ? s.explanation
                      : s.optionLabel(key.toUpperCase()),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? s.addQuestion : s.editQuestion),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.adminNote,
                style: const TextStyle(color: muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('question-order'),
                controller: _order,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    (int.tryParse(value ?? '') ?? -1) >= 0 &&
                        (int.tryParse(value ?? '') ?? -1) <= 1000000
                    ? null
                    : s.invalidOrder,
                decoration: InputDecoration(labelText: s.order),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _correct,
                decoration: InputDecoration(labelText: s.correctAnswer),
                items: optionIds
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(s.optionLabel(id.toUpperCase())),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _correct = value!),
              ),
              SwitchListTile(
                key: const Key('publish-question'),
                contentPadding: EdgeInsets.zero,
                title: Text(s.publishQuestion),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth > 1000
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _translation('ko', s)),
                          const SizedBox(width: 20),
                          Expanded(child: _translation('en', s)),
                        ],
                      )
                    : Column(
                        children: [
                          _translation('ko', s),
                          _translation('en', s),
                        ],
                      ),
              ),
              if (_error)
                Text(
                  s.saveError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('save-question'),
                onPressed: _saving ? null : _save,
                child: Text(s.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
