import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_session_controller.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_question_page.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_review_page.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_top_bar.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizTakeScreen extends ConsumerWidget {
  const QuizTakeScreen({super.key, required this.quizId});

  final String quizId;

  Future<void> _confirmLeave(BuildContext context) async {
    final navigator = Navigator.of(context);
    final leave = await showConfirmDialog(
      context,
      title: 'quizzes.leave_title'.tr(),
      message: 'quizzes.leave_message'.tr(),
      confirmLabel: 'quizzes.leave'.tr(),
      cancelLabel: 'quizzes.keep_going'.tr(),
    );
    if (leave) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider(quizId));

    ref.listen(quizSessionProvider(quizId), (previous, next) {
      final finished = next.value?.finished;
      if (finished != null && previous?.value?.finished == null) {
        if (next.value?.timedOut ?? false) showAppSnackBar(context, 'quizzes.time_up_submitted'.tr());
        context.pushReplacement(StudentRoutes.quizResult(quizId, finished.number));
      }
    });

    return PopScope(
      canPop: session is AsyncError,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (session) {
            AsyncError(:final error) => Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: BackButton(onPressed: () => context.pop()),
                ),
                Expanded(child: ErrorView(message: error.toString())),
              ],
            ),
            AsyncData(:final value) => _Body(session: value, quizId: quizId, onClose: () => _confirmLeave(context)),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.session, required this.quizId, required this.onClose});

  final QuizSession session;
  final String quizId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider(quizId).notifier);

    if (session.finishing || session.finished != null) return _Submitting(timedOut: session.timedOut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizTopBar(session: session, onClose: onClose),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppAnimations.normal,
            switchInCurve: AppAnimations.defaultCurve,
            switchOutCurve: AppAnimations.defaultCurve,
            transitionBuilder: (child, animation) {
              final isRtl = Directionality.of(context) == TextDirection.rtl;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: Offset(isRtl ? -.08 : .08, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: session.reviewing
                ? QuizReviewPage(key: const ValueKey('review'), session: session, controller: controller)
                : QuizQuestionPage(key: ValueKey(session.current.id), session: session, controller: controller),
          ),
        ),
      ],
    );
  }
}

class _Submitting extends StatelessWidget {
  const _Submitting({required this.timedOut});

  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timedOut) ...[
              Icon(Icons.timer_off_rounded, size: 56, color: Theme.of(context).colorScheme.error).popIn(),
              verticalSpace(12),
              Text('quizzes.time_up'.tr(), style: AppTextStyles.font22ExtraBold),
              verticalSpace(16),
            ],
            const CircularProgressIndicator(),
            verticalSpace(14),
            Text('quizzes.submitting'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
          ],
        ),
      ),
    );
  }
}
