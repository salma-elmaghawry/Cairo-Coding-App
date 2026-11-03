import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/question_draft.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_details_card.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_questions_section.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/services/quiz_validator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizBuilderForm extends ConsumerStatefulWidget {
  const QuizBuilderForm({super.key, this.quiz, this.content, this.questionsLocked = false});

  final Quiz? quiz;
  final QuizContent? content;
  final bool questionsLocked;

  @override
  ConsumerState<QuizBuilderForm> createState() => _BuilderFormState();
}

class _BuilderFormState extends ConsumerState<QuizBuilderForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.quiz?.title);
  late final _description = TextEditingController(text: widget.quiz?.description);
  late final _cover = TextEditingController(text: widget.quiz?.coverUrl);
  late final _duration = TextEditingController(
    text: (widget.quiz?.durationMin ?? 0) > 0 ? '${widget.quiz!.durationMin}' : '',
  );
  late final Set<String> _groupIds = {...?widget.quiz?.groupIds};
  late int _maxAttempts = widget.quiz?.maxAttempts ?? 1;
  late DateTime _opensAt;
  late DateTime _closesAt;
  late final List<QuestionDraft> _drafts;
  int _selected = 0;
  bool _showErrors = false;
  bool _saving = false;

  bool get _questionsEditable => !widget.questionsLocked;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _opensAt = widget.quiz?.opensAt ?? now;
    _closesAt = widget.quiz?.closesAt ?? now.add(const Duration(days: 7));

    final content = widget.content;
    _drafts = content == null || content.questions.isEmpty
        ? [QuestionDraft()]
        : [for (final question in content.questions) QuestionDraft.fromQuestion(question, content.key)];
    for (final draft in _drafts) {
      draft.addListener(_onDraftChanged);
    }
    for (final controller in [_title, _description, _cover, _duration]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [_title, _description, _cover, _duration]) {
      controller.dispose();
    }
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    // Providers can't change while the tree is building, and this also runs after the page's last frame.
    if (mounted) Future.microtask(() => mounted ? ref.read(quizBuilderDirtyProvider.notifier).set(true) : null);
  }

  void _onDraftChanged() {
    _markDirty();
    // The rail shows each question's text as it's typed.
    if (mounted) setState(() {});
  }

  void _changed(VoidCallback change) {
    setState(change);
    _markDirty();
  }

  void _addQuestion() {
    _changed(() {
      final previous = _drafts.isEmpty ? null : _drafts.last;
      _drafts.add(
        QuestionDraft(points: previous?.points ?? 1, timeLimitSec: previous?.timeLimitSec ?? 0)
          ..addListener(_onDraftChanged),
      );
      _selected = _drafts.length - 1;
    });
  }

  void _duplicateQuestion(int index) {
    _changed(() {
      _drafts.insert(index + 1, _drafts[index].duplicate()..addListener(_onDraftChanged));
      _selected = index + 1;
    });
  }

  void _deleteQuestion(int index) {
    _changed(() {
      _drafts.removeAt(index).dispose();
      if (_selected >= _drafts.length) _selected = _drafts.length - 1;
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    _changed(() {
      final current = _drafts[_selected];
      _drafts.insert(newIndex, _drafts.removeAt(oldIndex));
      _selected = _drafts.indexOf(current);
    });
  }

  Quiz _buildQuiz(QuizStatus status) {
    final base = widget.quiz ?? Quiz(id: '', title: '', opensAt: _opensAt, closesAt: _closesAt);
    return base.copyWith(
      title: _title.text,
      description: _description.text,
      coverUrl: _cover.text,
      groupIds: _groupIds.toList(),
      durationMin: int.tryParse(_duration.text.trim()) ?? 0,
      opensAt: _opensAt,
      closesAt: _closesAt,
      maxAttempts: _maxAttempts,
      status: status,
    );
  }

  String _messageOf(QuizProblem problem) => switch (problem.issue) {
    QuizIssue.noTitle => 'admin.quiz_builder.errors.no_title'.tr(),
    QuizIssue.noGroups => 'admin.quiz_builder.errors.no_groups'.tr(),
    QuizIssue.badDates => 'admin.quiz_builder.errors.bad_dates'.tr(),
    QuizIssue.noQuestions => 'admin.quiz_builder.errors.no_questions'.tr(),
    QuizIssue.badImageLink when problem.questionIndex == null => 'admin.quiz_builder.errors.bad_image'.tr(),
    _ => 'admin.quiz_builder.errors.question_incomplete'.tr(args: ['${(problem.questionIndex ?? 0) + 1}']),
  };

  Future<void> _save({required bool publish}) async {
    setState(() => _showErrors = publish);
    if (!_formKey.currentState!.validate()) return;

    final quiz = _buildQuiz(publish ? QuizStatus.published : QuizStatus.draft);
    final content = contentOf(_drafts);
    if (publish) {
      // Locked questions were already complete when students took them, so only the details need checking.
      final problems = findQuizProblems(quiz, _questionsEditable ? content : widget.content ?? content);
      if (problems.isNotEmpty) {
        final first = problems.first;
        if (first.questionIndex != null) setState(() => _selected = first.questionIndex!);
        showAppSnackBar(context, _messageOf(first), isError: true);
        return;
      }
    } else if (!isValidImageLink(quiz.coverUrl)) {
      showAppSnackBar(context, 'admin.quiz_builder.errors.bad_image'.tr(), isError: true);
      return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(quizRepositoryProvider)
        .saveQuiz(
          quiz,
          content: _questionsEditable ? content : null,
          previousGroupIds: widget.quiz?.groupIds ?? const [],
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        ref.read(quizBuilderDirtyProvider.notifier).set(false);
        showAppSnackBar(context, (publish ? 'admin.quizzes.published_done' : 'admin.quiz_builder.saved').tr());
        context.go(AdminRoutes.quizzes);
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  Future<void> _pick(bool opens) async {
    final picked = await pickDateTime(context, initial: opens ? _opensAt : _closesAt);
    if (picked == null) return;
    _changed(() => opens ? _opensAt = picked : _closesAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdminPage(
      eyebrow: 'admin.quizzes.eyebrow'.tr(),
      title: (widget.quiz == null ? 'admin.quiz_builder.new_title' : 'admin.quiz_builder.edit_title').tr(),
      actions: [
        OutlinedButton(onPressed: () => context.go(AdminRoutes.quizzes), child: Text('common.cancel'.tr())),
        OutlinedButton(
          onPressed: _saving ? null : () => _save(publish: false),
          child: Text('admin.quiz_builder.save_draft'.tr()),
        ),
        PrimaryButton(
          label: 'admin.quizzes.publish'.tr(),
          icon: Icons.rocket_launch_outlined,
          height: 44,
          expand: false,
          isLoading: _saving,
          onPressed: () => _save(publish: true),
        ),
      ],
      children: [
        if (widget.questionsLocked) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            color: colorScheme.tertiary.withValues(alpha: .12),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 20, color: colorScheme.tertiary),
                horizontalSpace(10),
                Expanded(child: Text('admin.quiz_builder.locked_notice'.tr(), style: AppTextStyles.font14Normal)),
              ],
            ),
          ),
          verticalSpace(16),
        ],
        QuizDetailsCard(
          formKey: _formKey,
          title: _title,
          description: _description,
          cover: _cover,
          duration: _duration,
          groupIds: _groupIds,
          maxAttempts: _maxAttempts,
          opensAt: _opensAt,
          closesAt: _closesAt,
          showErrors: _showErrors,
          onGroupToggled: (groupId, on) => _changed(() => on ? _groupIds.add(groupId) : _groupIds.remove(groupId)),
          onMaxAttemptsChanged: (value) => _changed(() => _maxAttempts = value),
          onPickOpens: () => _pick(true),
          onPickCloses: () => _pick(false),
        ),
        verticalSpace(24),
        QuizQuestionsSection(
          drafts: _drafts,
          selected: _selected,
          editable: _questionsEditable,
          showErrors: _showErrors,
          onAdd: _addQuestion,
          onSelect: (index) => setState(() => _selected = index),
          onReorder: _reorder,
          onDuplicate: _duplicateQuestion,
          onDelete: _deleteQuestion,
          onChanged: () => _changed(() {}),
        ),
      ],
    );
  }
}
